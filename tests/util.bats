#!/usr/bin/env bats

SCRIPTS_DIR="$(cd -- "${BATS_TEST_DIRNAME}/../src/scripts" &> /dev/null && pwd)"
FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"
INCLUDES_DIR="${FIXTURES_DIR}/nginx_config/includes"

load "${SCRIPTS_DIR}/util.sh"


@test "is_ipv4 detects what is an IPv6 address" {
  local ipv4addresses=($(<"${FIXTURES_DIR}/ipv4_addresses.txt"))

  for ipv4addr in ${ipv4addresses[@]}; do
    echo "Testing '$ipv4addr'" >&2
    is_ipv4 "$ipv4addr"
  done
}

@test "is_ipv4 detects what is not an IPv6 address" {
  local notipv4addresses=($(<"${FIXTURES_DIR}/not_ip_addresses.txt"))
  notipv4addresses+=($(<"${FIXTURES_DIR}/ipv6_addresses.txt"))

  for notipv4addr in ${notipv4addresses[@]}; do
    echo "Testing '$notipv4addr'" >&2
    ! is_ipv4 "$notipv4addr"
  done
}

@test "is_ipv6 detects what is an IPv6 address" {
  local ipv6addresses=($(<"${FIXTURES_DIR}/ipv6_addresses.txt"))

  for ipv6addr in ${ipv6addresses[@]}; do
    echo "Testing '$ipv6addr'" >&2
    is_ipv6 "$ipv6addr"
  done
}

@test "is_ipv6 detects what is not an IPv6 address" {
  local notipv6addresses=($(<"${FIXTURES_DIR}/not_ip_addresses.txt"))
  notipv6addresses+=($(<"${FIXTURES_DIR}/ipv4_addresses.txt"))

  for notipv6addr in ${notipv6addresses[@]}; do
    echo "Testing '$notipv6addr'" >&2
    ! is_ipv6 "$notipv6addr"
  done
}

@test "is_ip detects what is an IPv4 or an IPv6 address" {
  local ipaddresses=($(<"${FIXTURES_DIR}/ipv4_addresses.txt"))
  ipaddresses+=($(<"${FIXTURES_DIR}/ipv6_addresses.txt"))

  for ipaddr in ${ipaddresses[@]}; do
    echo "Testing '$ipaddr'" >&2
    is_ip "$ipaddr"
  done
}

@test "is_ip detects what is not an IPv4 or an IPv6 address" {
  local notipaddresses=($(<"${FIXTURES_DIR}/not_ip_addresses.txt"))

  for notipaddr in ${notipaddresses[@]}; do
    echo "Testing '$notipaddr'" >&2
    ! is_ip "$notipaddr"
  done
}

@test "parse_config_file works for single server block, single certificate name, single server name" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/single_server_single_cert_single_name.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 1 ]
  [ -n "${certificates[my-cert]}" ]

  local server_names=(${certificates[my-cert]})
  [ ${#server_names[@]} -eq 2 ]
  [ "${server_names[0]}" == "example.org" ]
  [ "${server_names[1]}" == "www.example.org" ]
}

@test "parse_config_file works for single server block, single certificate name, multiple server names" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/single_server_single_cert_multi_name.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates

  [ ${#certificates[@]} -eq 1 ]
  [ -n "${certificates[my-cert]}" ]

  local server_names=(${certificates[my-cert]})
  [ ${#server_names[@]} -eq 3 ]
  [ "${server_names[0]}" == "example.org" ]
  [ "${server_names[1]}" == "www.example.org" ]
  [ "${server_names[2]}" == "another.example.org" ]
}

@test "parse_config_file works for single server block, multiple certificate names, single server name" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/single_server_multi_cert_single_name.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 2 ]
  [ -n "${certificates[my-cert1]}" ]
  [ -n "${certificates[my-cert2]}" ]

  local server_names_cert1=(${certificates[my-cert1]})
  [ ${#server_names_cert1[@]} -eq 2 ]
  [ "${server_names_cert1[0]}" == "example.org" ]
  [ "${server_names_cert1[1]}" == "www.example.org" ]

  local server_names_cert2=(${certificates[my-cert2]})
  [ ${#server_names_cert2[@]} -eq 2 ]
  [ "${server_names_cert2[0]}" == "example.org" ]
  [ "${server_names_cert2[1]}" == "www.example.org" ]
}

@test "parse_config_file works for multiple server blocks, single certificate name, single server name" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/multi_server_single_cert_single_name.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 1 ]
  [ -n "${certificates[my-cert]}" ]

  local server_names=(${certificates[my-cert]})
  [ ${#server_names[@]} -eq 3 ]
  [ "${server_names[0]}" == "example.org" ]
  [ "${server_names[1]}" == "www.example.org" ]
  [ "${server_names[2]}" == "another.example.org" ]
}

@test "parse_config_file works for multiple server blocks, multiple certificate names, multiple server names" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/multi_server_multi_cert_multi_name.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 2 ]
  [ -n "${certificates[my-cert1]}" ]
  [ -n "${certificates[my-cert2]}" ]

  local server_names_cert1=(${certificates[my-cert1]})
  [ ${#server_names_cert1[@]} -eq 4 ]
  [ "${server_names_cert1[0]}" == "example.org" ]
  [ "${server_names_cert1[1]}" == "www.example.org" ]
  [ "${server_names_cert1[2]}" == "another.example.org" ]
  [ "${server_names_cert1[3]}" == "anew.example.org" ]

  local server_names_cert2=(${certificates[my-cert2]})
  [ ${#server_names_cert2[@]} -eq 4 ]
  [ "${server_names_cert2[0]}" == "example.org" ]
  [ "${server_names_cert2[1]}" == "www.example.org" ]
  [ "${server_names_cert2[2]}" == "another.example.org" ]
  [ "${server_names_cert2[3]}" == "anew.example.org" ]

}

@test "parse_config_file supports a single lego_domain directive" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/single_lego_domain_directive.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 1 ]
  [ -n "${certificates[my-cert]}" ]

  local server_names=(${certificates[my-cert]})
  [ ${#server_names[@]} -eq 1 ]
  [ "${server_names[0]}" == "*.example.org" ]
}

@test "parse_config_file supports multiple lego_domain directives" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/multi_lego_domain_directive.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 1 ]
  [ -n "${certificates[my-cert]}" ]

  local server_names=(${certificates[my-cert]})
  [ ${#server_names[@]} -eq 3 ]
  [ "${server_names[0]}" == "*.example.org" ]
  [ "${server_names[1]}" == "example.org" ]
  [ "${server_names[2]}" == "*.sub.example.org" ]
}

@test "parse_config_file ignores regex names" {
  local fixture="${FIXTURES_DIR}/nginx_config/single_files/regex_server_names.conf"

  local -A certificates
  parse_config_file "${fixture}" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 1 ]
  [ -n "${certificates[my-cert]}" ]

  local server_names=(${certificates[my-cert]})
  echo "${certificates[@]}"
  [ ${#server_names[@]} -eq 5 ]
  [ "${server_names[0]}" == "example.org" ]
  [ "${server_names[1]}" == "www.example.org" ]
  [ "${server_names[2]}" == "_" ]
  [ "${server_names[3]}" == "192.168.0.1" ]
  [ "${server_names[4]}" == "1:2:3:4:5:6:7:8" ]
}

@test "parse_config_file works over multiple files (with duplicates)" {
  local -A certificates
  for conf_file in ${FIXTURES_DIR}/nginx_config/multi_files/*.conf*; do
    parse_config_file "${conf_file}" certificates
  done

  local -p certificates
  [ ${#certificates[@]} -eq 3 ]
  [ -n "${certificates[my-cert1]}" ]
  [ -n "${certificates[my-cert2]}" ]
  [ -n "${certificates[my-cert3]}" ]

  local server_names_cert1=(${certificates[my-cert1]})
  [ ${#server_names_cert1[@]} -eq 3 ]
  [ "${server_names_cert1[0]}" == "example.org" ]
  [ "${server_names_cert1[1]}" == "www.example.org" ]
  [ "${server_names_cert1[2]}" == "anew.example.org" ]

  local server_names_cert2=(${certificates[my-cert2]})
  [ ${#server_names_cert2[@]} -eq 3 ]
  [ "${server_names_cert2[0]}" == "anew.example.org" ]
  [ "${server_names_cert2[1]}" == "example.com" ]
  [ "${server_names_cert2[2]}" == "*.example.com" ]

  local server_names_cert3=(${certificates[my-cert3]})
  [ ${#server_names_cert3[@]} -eq 4 ]
  [ "${server_names_cert3[0]}" == "example.net" ]
  [ "${server_names_cert3[1]}" == "*.example.net" ]
  [ "${server_names_cert3[2]}" == "www.example.net" ]
  [ "${server_names_cert3[3]}" == "new.example.net" ]
}


# ---------------------------------------------------------------------------
# nginx_config_stream - following 'include' directives
#
# Regression cover for a silent failure: a server block whose certificate lines
# live in an included snippet was invisible to discovery, because the snippet
# holds the certificate but no server_name while the including file holds the
# server_name but no certificate. Renewal then did nothing, with no error.
# ---------------------------------------------------------------------------

@test "nginx_config_stream inlines a relative include, resolved against the prefix" {
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" nginx_config_stream "${INCLUDES_DIR}/vhost_relative.conf" 2>/dev/null)"

  grep -q "ssl_certificate_key     /etc/letsencrypt/live/my-cert/privkey.pem;" <<< "${stream}"
  grep -q "server_name example.org www.example.org;" <<< "${stream}"
  # The include directive itself must be replaced, not merely followed.
  ! grep -q "^\s*include " <<< "${stream}"
}

@test "nginx_config_stream inlines an absolute include" {
  local snippet="${BATS_TEST_TMPDIR}/absolute_ssl.inc"
  local vhost="${BATS_TEST_TMPDIR}/absolute_vhost.conf"

  printf 'ssl_certificate_key /etc/letsencrypt/live/abs-cert/privkey.pem;\n' > "${snippet}"
  printf 'server {\n    server_name abs.example.org;\n    include %s;\n}\n' "${snippet}" > "${vhost}"

  local stream
  stream="$(nginx_config_stream "${vhost}" 2>/dev/null)"

  grep -q "abs-cert" <<< "${stream}"
  grep -q "abs.example.org" <<< "${stream}"
}

@test "nginx_config_stream follows nested includes" {
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" nginx_config_stream "${INCLUDES_DIR}/vhost_nested.conf" 2>/dev/null)"

  # Reached two levels down: vhost -> _nested_outer.inc -> _ssl_shared.inc
  grep -q "X-Nested" <<< "${stream}"
  grep -q "my-cert" <<< "${stream}"
}

@test "nginx_config_stream expands a glob include" {
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" nginx_config_stream "${INCLUDES_DIR}/vhost_glob.conf" 2>/dev/null)"

  grep -q "glob-cert-a" <<< "${stream}"
  grep -q "glob-cert-b" <<< "${stream}"
}

@test "nginx_config_stream tolerates a missing include instead of failing" {
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" nginx_config_stream "${INCLUDES_DIR}/vhost_missing_include.conf" 2>/dev/null)"

  # The rest of the file must survive an include that matches nothing.
  grep -q "survivor-cert" <<< "${stream}"
  grep -q "survives.example.org" <<< "${stream}"
}

@test "nginx_config_stream stops at the include depth limit" {
  # A limit of 1 permits the top-level file plus one level of includes, so the
  # first snippet is reached and the one it includes is not.
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" NGINX_INCLUDE_MAX_DEPTH=1 \
    nginx_config_stream "${INCLUDES_DIR}/vhost_nested.conf" 2>/dev/null)"

  grep -q "X-Nested" <<< "${stream}"
  ! grep -q "my-cert" <<< "${stream}"
}

@test "nginx_config_stream detects an include cycle" {
  # The depth limit bounds how deep we go, not how much work we do: files that
  # glob-include each other multiply combinatorially and would keep the renewal
  # loop busy forever, requesting nothing and reporting nothing.
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" \
    nginx_config_stream "${INCLUDES_DIR}/vhost_self_include.conf" 2>/dev/null)"

  local copies
  copies="$(grep -c "loop-cert/fullchain.pem" <<< "${stream}")"
  [ "${copies}" -eq 1 ]
}

@test "nginx_config_stream keeps its log output off stdout" {
  # stdout from this function IS the configuration every parse_* function reads,
  # so a log line written there would be parsed as though it were config.
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" NGINX_INCLUDE_MAX_DEPTH=2 \
    nginx_config_stream "${INCLUDES_DIR}/vhost_self_include.conf" 2>/dev/null)"

  ! grep -q "depth limit" <<< "${stream}"
  ! grep -q "\[warning\]" <<< "${stream}"
}

@test "nginx_config_stream resolves a quoted include path containing spaces" {
  local dir="${BATS_TEST_TMPDIR}/my snips"
  mkdir -p "${dir}"
  printf 'ssl_certificate_key /etc/letsencrypt/live/spaced-cert/privkey.pem;\n' > "${dir}/ssl.inc"

  local vhost="${BATS_TEST_TMPDIR}/spaced.conf"
  printf 'server {\n    server_name spaced.example.org;\n    include "%s/ssl.inc";\n}\n' "${dir}" > "${vhost}"

  local stream
  stream="$(nginx_config_stream "${vhost}" 2>/dev/null)"

  # Word splitting on the include argument would break this path in two and the
  # certificate would be missed silently.
  grep -q "spaced-cert" <<< "${stream}"
}

@test "nginx_config_stream inlines a repeated include every time it appears" {
  # A shared SSL snippet included by several server blocks in one file is the
  # primary use case. The cycle guard must block only a true cycle; collapsing
  # repeats would drop the certificate from every block after the first.
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" nginx_config_stream "${INCLUDES_DIR}/vhost_relative.conf" 2>/dev/null)"

  local copies
  copies="$(grep -c "live/my-cert/privkey.pem" <<< "${stream}")"
  [ "${copies}" -eq 2 ]
}

@test "a snippet under conf.d is still inlined when it is not named like a config" {
  # The exclusion must match discovery's '*.conf*' filter exactly. Excluding
  # every include under these roots would silently stop inlining '.inc'
  # snippets — losing exactly the certificates this feature exists to find.
  local root="${BATS_TEST_TMPDIR}/inc_under_confd"
  mkdir -p "${root}/conf.d/snippets" "${root}/user_conf.d/snippets"

  printf 'ssl_certificate_key /etc/letsencrypt/live/snip-cert/privkey.pem;\n' \
    > "${root}/conf.d/snippets/ssl.inc"
  printf 'ssl_certificate_key /etc/letsencrypt/live/user-snip-cert/privkey.pem;\n' \
    > "${root}/user_conf.d/snippets/ssl.inc"

  printf 'server {\n    server_name a.example.org;\n    include conf.d/snippets/ssl.inc;\n}\n' \
    > "${root}/conf.d/a.conf"
  printf 'server {\n    server_name b.example.org;\n    include user_conf.d/snippets/ssl.inc;\n}\n' \
    > "${root}/conf.d/b.conf"

  local -A certificates
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/a.conf" certificates
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/b.conf" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 2 ]
  [ "${certificates[snip-cert]}" == "a.example.org " ]
  [ "${certificates[user-snip-cert]}" == "b.example.org " ]
}

@test "the cycle guard resolves symlinks, not just literal paths" {
  # conf.d entries are symlinks into user_conf.d, so a cycle usually arrives
  # under a second name. Comparing literal strings would miss it and recurse to
  # the depth limit instead of stopping.
  local root="${BATS_TEST_TMPDIR}/symcycle"
  mkdir -p "${root}"

  printf 'ssl_certificate_key /etc/letsencrypt/live/cycle-cert/privkey.pem;\ninclude alias.inc;\n' \
    > "${root}/real.inc"
  ln -s "${root}/real.inc" "${root}/alias.inc"

  printf 'server {\n    server_name cycle.example.org;\n    include real.inc;\n}\n' \
    > "${root}/vhost.conf"

  local stream
  stream="$(NGINX_PREFIX="${root}" nginx_config_stream "${root}/vhost.conf" 2>/dev/null)"

  local copies
  copies="$(grep -c "cycle-cert" <<< "${stream}")"
  [ "${copies}" -eq 1 ]
}

@test "the exclusion still applies when conf.d itself is a symlink" {
  # Written one way and resolved another: both spellings must be recognised.
  local root="${BATS_TEST_TMPDIR}/symroot"
  mkdir -p "${root}/actual_confd/sites"
  ln -s "${root}/actual_confd" "${root}/conf.d"

  printf 'server {\n    server_name shop.example.org;\n    ssl_certificate_key /etc/letsencrypt/live/shop-cert/privkey.pem;\n}\n' \
    > "${root}/actual_confd/sites/shop.conf"
  printf 'server {\n    server_name blog.example.net;\n    ssl_certificate_key /etc/letsencrypt/live/blog-cert/privkey.pem;\n}\n' \
    > "${root}/actual_confd/sites/blog.conf"

  # Written via the resolved directory name, not via conf.d.
  printf 'include actual_confd/sites/*.conf;\n' > "${root}/actual_confd/00-main.conf"

  local -A certificates
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/00-main.conf" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 0 ]
}

@test "the exclusion covers /etc/nginx even when NGINX_PREFIX points elsewhere" {
  # Discovery scans /etc/nginx/conf.d with a hardcoded path, so relocating the
  # prefix must not stop the exclusion applying to the directory that is
  # actually scanned.
  if ! mkdir -p /etc/nginx/conf.d/sites 2>/dev/null; then
    skip "cannot write /etc/nginx in this environment"
  fi

  local root="${BATS_TEST_TMPDIR}/relocated"
  mkdir -p "${root}"

  printf 'server {\n    server_name shop.example.org;\n    ssl_certificate_key /etc/letsencrypt/live/etc-shop-cert/privkey.pem;\n}\n' \
    > /etc/nginx/conf.d/sites/etc-shop.conf
  printf 'server {\n    server_name main.example.org;\n    include /etc/nginx/conf.d/sites/etc-shop.conf;\n}\n' \
    > "${root}/00-main.conf"

  local -A certificates
  NGINX_PREFIX="${root}" parse_config_file "${root}/00-main.conf" certificates
  local -p certificates

  rm -f /etc/nginx/conf.d/sites/etc-shop.conf

  [ ${#certificates[@]} -eq 0 ]
}

@test "the exclusion resolves an include that reaches a scanned file from outside" {
  # An include naming a path outside the scanned roots whose target lives inside
  # them. Only resolving the include itself catches this; matching the written
  # path against the roots does not, because the written path is outside.
  local root="${BATS_TEST_TMPDIR}/outside"
  mkdir -p "${root}/conf.d/sites" "${root}/elsewhere"

  printf 'server {\n    server_name shop.example.org;\n    ssl_certificate_key /etc/letsencrypt/live/shop-cert/privkey.pem;\n}\n' \
    > "${root}/conf.d/sites/shop.conf"
  ln -s "${root}/conf.d/sites/shop.conf" "${root}/elsewhere/link.conf"

  printf 'server {\n    server_name main.example.org;\n    include elsewhere/link.conf;\n}\n' \
    > "${root}/conf.d/00-main.conf"

  local -A certificates
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/00-main.conf" certificates
  local -p certificates

  # shop.conf is scanned standalone, so inlining it here would give shop-cert
  # main.example.org as well.
  [ ${#certificates[@]} -eq 0 ]
}

@test "a trailing slash on NGINX_PREFIX does not defeat the exclusion" {
  local root="${BATS_TEST_TMPDIR}/slash"
  mkdir -p "${root}/conf.d/sites"

  printf 'server {\n    server_name shop.example.org;\n    ssl_certificate_key /etc/letsencrypt/live/shop-cert/privkey.pem;\n}\n' \
    > "${root}/conf.d/sites/shop.conf"
  printf 'server {\n    server_name blog.example.net;\n    ssl_certificate_key /etc/letsencrypt/live/blog-cert/privkey.pem;\n}\n' \
    > "${root}/conf.d/sites/blog.conf"
  printf 'include conf.d/sites/*.conf;\n' > "${root}/conf.d/00-main.conf"

  local -A certificates
  NGINX_PREFIX="${root}/" parse_config_file "${root}/conf.d/00-main.conf" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 0 ]
}

@test "an aggregating include is not fused when written as a user_conf.d path" {
  # symlink_user_configs mirrors user_conf.d into conf.d and discovery scans
  # with 'find -L', so one file has two names. Excluding only the conf.d
  # spelling would let this spelling fuse every site's certificate together.
  local root="${BATS_TEST_TMPDIR}/uc"
  mkdir -p "${root}/conf.d" "${root}/user_conf.d/sites"

  printf 'server {\n    server_name shop.example.org;\n    ssl_certificate_key /etc/letsencrypt/live/shop-cert/privkey.pem;\n}\n' \
    > "${root}/user_conf.d/sites/shop.conf"
  printf 'server {\n    server_name blog.example.net;\n    ssl_certificate_key /etc/letsencrypt/live/blog-cert/privkey.pem;\n}\n' \
    > "${root}/user_conf.d/sites/blog.conf"
  printf 'include user_conf.d/sites/*.conf;\n' > "${root}/user_conf.d/00-main.conf"

  # Mirror into conf.d the way symlink_user_configs does.
  ln -s "${root}/user_conf.d/00-main.conf" "${root}/conf.d/00-main.conf"
  mkdir -p "${root}/conf.d/sites"
  ln -s "${root}/user_conf.d/sites/shop.conf" "${root}/conf.d/sites/shop.conf"
  ln -s "${root}/user_conf.d/sites/blog.conf" "${root}/conf.d/sites/blog.conf"

  local -A certificates
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/00-main.conf" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 0 ]
}



@test "an aggregating include does not fuse the sites it collects" {
  # 'parse_config_file' pairs every certificate in its input with every domain
  # in it. Inlining a file that discovery already scans on its own would
  # therefore give each site's certificate every other site's hostnames — wrong
  # SANs, and every hostname leaked into every CT log entry.
  local root="${BATS_TEST_TMPDIR}/agg"
  mkdir -p "${root}/conf.d/sites"

  printf 'server {\n    server_name shop.example.org;\n    ssl_certificate_key /etc/letsencrypt/live/shop-cert/privkey.pem;\n}\n' \
    > "${root}/conf.d/sites/shop.conf"
  printf 'server {\n    server_name blog.example.net;\n    ssl_certificate_key /etc/letsencrypt/live/blog-cert/privkey.pem;\n}\n' \
    > "${root}/conf.d/sites/blog.conf"
  printf 'include conf.d/sites/*.conf;\n' > "${root}/conf.d/00-main.conf"

  local -A certificates
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/00-main.conf" certificates
  local -p certificates

  # The aggregator yields nothing itself; discovery parses each site separately.
  [ ${#certificates[@]} -eq 0 ]

  local -A per_site
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/sites/shop.conf" per_site
  NGINX_PREFIX="${root}" parse_config_file "${root}/conf.d/sites/blog.conf" per_site
  local -p per_site

  [ ${#per_site[@]} -eq 2 ]
  [ "${per_site[shop-cert]}" == "shop.example.org " ]
  [ "${per_site[blog-cert]}" == "blog.example.net " ]
}

@test "nginx_config_stream with a depth limit of 0 still reads the top-level file" {
  # A limit of 0 must mean 'follow no includes', not 'read nothing'. Reading
  # nothing would make every certificate silently disappear while every config
  # looked complete, since allfiles_exist would find no files to check.
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" NGINX_INCLUDE_MAX_DEPTH=0 \
    nginx_config_stream "${INCLUDES_DIR}/vhost_relative.conf" 2>/dev/null)"

  grep -q "server_name example.org www.example.org;" <<< "${stream}"
  ! grep -q "my-cert" <<< "${stream}"
}

@test "nginx_config_stream survives a non-numeric depth limit" {
  # A non-numeric value makes the comparison error out; treated as false, that
  # would remove the limit entirely and a self-including file would exhaust the
  # stack and take the renewal loop down with it.
  local stream
  stream="$(NGINX_PREFIX="${INCLUDES_DIR}" NGINX_INCLUDE_MAX_DEPTH=notanumber \
    nginx_config_stream "${INCLUDES_DIR}/vhost_self_include.conf" 2>/dev/null)"

  # Falls back to the default of 10, and the cycle guard stops the repeat.
  local copies
  copies="$(grep -c "loop-cert/fullchain.pem" <<< "${stream}")"
  [ "${copies}" -eq 1 ]
}

@test "allfiles_exist sees files reached through an include" {
  # This decides whether a vhost is disabled at startup, so it must see the
  # certificate that lives in the snippet.
  ! NGINX_PREFIX="${INCLUDES_DIR}" allfiles_exist "${INCLUDES_DIR}/vhost_relative.conf"
}

@test "lego_domain overrides still apply when reached through an include" {
  # The override state machine must not desync across an include boundary.
  local -A certificates
  NGINX_PREFIX="${INCLUDES_DIR}" parse_config_file "${INCLUDES_DIR}/vhost_override.conf" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 1 ]
  [ "${certificates[my-cert]}" == "*.example.org " ]
}

@test "parse_config_file discovers a certificate declared in an included snippet" {
  local -A certificates
  NGINX_PREFIX="${INCLUDES_DIR}" parse_config_file "${INCLUDES_DIR}/vhost_relative.conf" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 1 ]
  [ -n "${certificates[my-cert]}" ]

  local server_names=(${certificates[my-cert]})
  [ ${#server_names[@]} -eq 3 ]
  [ "${server_names[0]}" == "example.org" ]
  [ "${server_names[1]}" == "www.example.org" ]
  [ "${server_names[2]}" == "another.example.org" ]
}

@test "parse_config_file discovers certificates behind a glob include" {
  local -A certificates
  NGINX_PREFIX="${INCLUDES_DIR}" parse_config_file "${INCLUDES_DIR}/vhost_glob.conf" certificates
  local -p certificates

  [ ${#certificates[@]} -eq 2 ]
  [ "${certificates[glob-cert-a]}" == "glob.example.org " ]
  [ "${certificates[glob-cert-b]}" == "glob.example.org " ]
}

@test "the other parse_ helpers also see files reached through an include" {
  local conf="${INCLUDES_DIR}/vhost_relative.conf"

  [ "$(NGINX_PREFIX="${INCLUDES_DIR}" parse_keyfiles "${conf}")" == "/etc/letsencrypt/live/my-cert/privkey.pem" ]
  [ "$(NGINX_PREFIX="${INCLUDES_DIR}" parse_fullchains "${conf}")" == "/etc/letsencrypt/live/my-cert/fullchain.pem" ]
  [ "$(NGINX_PREFIX="${INCLUDES_DIR}" parse_chains "${conf}")" == "/etc/letsencrypt/live/my-cert/chain.pem" ]
  [ "$(NGINX_PREFIX="${INCLUDES_DIR}" parse_dhparams "${conf}")" == "/etc/letsencrypt/dhparams/dhparam.pem" ]
}


@test "nginx_config_stream is silent about a file that does not exist" {
  # An include matching nothing is normal and Nginx tolerates it, so this must
  # not produce output on stdout, where it would be parsed as configuration.
  local stream
  stream="$(nginx_config_stream "${BATS_TEST_TMPDIR}/no_such_file.conf" 2>/dev/null)"

  [ -z "${stream}" ]
}





