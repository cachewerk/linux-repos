#!/bin/bash

pkg_name="lsphp$php_version_short-relay"
pkg_identifier=$distro

case "$dist" in
  noble | plucky | trixie)
    pkg_binary="relay.so" ;;
  *)
    pkg_binary="relay-pkg.so" ;;
esac

pkg_binary_dest=(
    "usr/local/lsws/lsphp$php_version_short/lib/php/$php_api"
)

pkg_config_dest=(
    "usr/local/lsws/lsphp$php_version_short/etc/php/$php_version/mods-available/60-relay.ini"
)

pkg_depends=(
    "libc6 >= 2.17"
    "liblz4-1 >= 0.0~r130"
    "libzstd1 >= 1.3.2"
    "lsphp$php_version_short-common"
    "lsphp$php_version_short-igbinary"
    "lsphp$php_version_short-msgpack"
)

[[ ! "$pkg_binary" == *-pkg ]] && pkg_depends+=(
  "libhiredis1.1.0 >= 1.1.0"
  "libck0 >= 0.7.0"
)

fpm_args=(
  "--after-install /root/fpm/src/deb/after-install.sh"
)
