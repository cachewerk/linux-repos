#!/bin/bash

pkg_name="php$php_version-relay"
pkg_provides="php-relay"
pkg_identifier=$distro

case "$distro" in
  noble | plucky | trixie)
    pkg_binary="relay.so" ;;
  *)
    pkg_binary="relay-pkg.so" ;;
esac

pkg_binary_dest=(
    "usr/lib/php/$php_api"
)

pkg_config_dest=(
    "etc/php/$php_version/mods-available/relay.ini"
)

pkg_depends=(
    "libc6 >= 2.17"
    "php$php_version-common"
    "php$php_version-igbinary"
    "php$php_version-msgpack"
)

[[ ! "$pkg_binary" == *-pkg* ]] && pkg_depends+=(
  "libhiredis1.1.0 >= 1.1.0"
  "libck0 >= 0.7.0"
)

fpm_args=(
  # Relay dlopens these at startup rather than linking them, so they are
  # wanted but not required.
  "--deb-recommends 'liblz4-1 (>= 0.0~r130)'"
  "--deb-recommends 'libzstd1 (>= 1.3.2)'"
  "--replaces 'php-relay << ${version#v}'"
  "--deb-pre-depends 'php-common'"
  "--deb-field 'Source: php-relay'"
  "--after-install /root/build/src/deb/after-install-multi.sh"
  "--after-remove /root/build/src/deb/after-remove-multi.sh"
)
