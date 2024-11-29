#!/bin/bash

pkg_name="lsphp$php_version_short-relay"
pkg_identifier="debian"

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

fpm_args=(
  "--after-install /root/fpm/src/deb/after-install.sh"
)
