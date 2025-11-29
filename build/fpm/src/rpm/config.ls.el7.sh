#!/bin/bash

pkg_name="lsphp$php_version_short-relay"
pkg_provides="lsphp$php_version_short-relay"
pkg_binary="relay-pkg.so"
pkg_identifier="el7"

pkg_binary_dest=(
    "usr/local/lsws/lsphp$php_version_short/lib64/php/modules"
)

pkg_config_dest=(
    "usr/local/lsws/lsphp$php_version_short/etc/php.d/60-relay.ini"
)

pkg_depends=(
    "openssl11"
    "libzstd"
    "lz4"
    "lsphp$php_version_short(api) = $php_api"
    "lsphp$php_version_short-json"
    "lsphp$php_version_short-session"
    "lsphp$php_version_short-pecl-msgpack"
    "lsphp$php_version_short-pecl-igbinary"
)

fpm_args=(
  "--after-install /root/fpm/src/rpm/after-install.sh"
)
