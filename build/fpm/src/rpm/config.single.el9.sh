#!/bin/bash

pkg_name="php-relay"
pkg_provides="php-relay"
pkg_identifier="el9"

pkg_binary_dest=(
    "usr/lib64/php/modules"
    "usr/lib64/php-zts/modules"
)

pkg_config_dest=(
    "etc/php.d/60-relay.ini"
    "etc/php-zts.d/60-relay.ini"
)

pkg_depends=(
    "openssl"
    "libzstd"
    "lz4"
    "php(api) = $php_api-64"
    "php-json"
    "php-session"
    "php-msgpack"
    "php-igbinary"
)

fpm_args=(
  "--after-install /root/fpm/src/rpm/after-install.sh"
)
