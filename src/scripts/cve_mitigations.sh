#!/bin/bash
# FORK: not present upstream. Do not drop when syncing this file; see UPSTREAM_SYNC.md.
#
# Applies, then verifies, the image changes that the .trivyignore entries rely on.
# It runs as the last step of every image build, so a build fails instead of an
# ignore hiding a CVE that has come back. With --check it only verifies, e.g. in an
# image built on top of this one. Run it as root.
#
# Usage: cve_mitigations.sh <debian|ubuntu|alpine> [--check]
set -eu
variant=${1:-}
mode=${2:-apply}
usage() { echo "usage: cve_mitigations.sh <debian|ubuntu|alpine> [--check]" >&2; exit 2; }
case "$variant" in debian|ubuntu|alpine) ;; *) usage ;; esac
case "$mode" in apply|--check) ;; *) usage ;; esac
[ "$(id -u)" = 0 ] || { echo "cve_mitigations.sh must run as root" >&2; exit 2; }

fail() { echo "cve_mitigations ($variant): $*" >&2; exit 1; }

# check_absent <what> <find(1) expression>: fail if any file matches.
check_absent() {
    what=$1; shift
    found=$(find / -xdev \( "$@" \) -print) || fail "find failed while looking for $what"
    [ -z "$found" ] || fail "$what present: $found"
}

# CVE-2026-9538, CVE-2026-42496, CVE-2026-42497 (Archive::Tar), CVE-2026-48962
# (IO::Compress), CVE-2026-57433 (Storable): these perl modules are not shipped.
check_absent "perl module" -path '*/Archive/Tar.pm' -o -path '*/IO/Compress/*' \
    -o -name GlobMapper.pm -o -name Storable.pm -o -name Storable.so

# CVE-2026-52490: only the tiffcrop tool is affected, and it is not shipped.
check_absent tiffcrop -name tiffcrop

# CVE-2026-16742: only systemd-homed is affected, and it is not shipped.
check_absent systemd-homed -name systemd-homed -o -name homectl

applying() { [ "$mode" = apply ]; }
uses_dpkg() { [ "$variant" != alpine ]; }
excludes=/etc/dpkg/dpkg.cfg.d/cve-path-excludes

# drop_binary <path>: delete it and add a dpkg path-exclude so later installs and
# upgrades cannot bring it back.
drop_binary() {
    if applying; then
        grep -qx "path-exclude=$1" "$excludes" 2>/dev/null || echo "path-exclude=$1" >> "$excludes"
        rm -f "$1"
    fi
    [ ! -e "$1" ] || fail "$1 present"
    grep -qx "path-exclude=$1" "$excludes" || fail "no dpkg path-exclude for $1"
}

# CVE-2025-69720: only the infocmp CLI is affected, fixed upstream in ncurses
# 6.5-20251213. Debian has no fixed package, so infocmp goes there and on Ubuntu;
# Alpine must ship ncurses 6.5_p20251213 or later.
if uses_dpkg; then
    drop_binary /usr/bin/infocmp
elif [ -e /usr/bin/infocmp ]; then
    owner=$(apk info --who-owns /usr/bin/infocmp 2>/dev/null | sed -n 's/.* is owned by //p')
    ncurses_version=$(echo "$owner" | sed -n 's/^ncurses-\([0-9][^-]*-r[0-9]*\)$/\1/p')
    [ -n "$ncurses_version" ] || fail "cannot tell which ncurses owns infocmp: '$owner'"
    case $(apk version -t "$ncurses_version" 6.5_p20251213-r0) in
        '>'|'=') ;;
        *) fail "infocmp comes from ncurses $ncurses_version, older than the fix" ;;
    esac
fi

# CVE-2026-78408: only nsenter --join-cgroup is affected. Debian's nsenter has it,
# so nsenter goes; Ubuntu's util-linux 2.39 and Alpine's busybox nsenter lack it.
[ "$variant" != debian ] || drop_binary /usr/bin/nsenter
if command -v nsenter >/dev/null && nsenter --help 2>&1 | grep -q -- --join-cgroup; then
    fail "nsenter supports --join-cgroup"
fi

echo "cve_mitigations ($variant): all checks passed"
