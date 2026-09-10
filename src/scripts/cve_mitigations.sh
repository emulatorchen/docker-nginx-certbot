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

echo "cve_mitigations ($variant): all checks passed"
