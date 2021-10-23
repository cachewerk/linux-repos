#!/bin/bash

pkg_name="php$php_version_short-php-relay"
pkg_provides="php$php_version_short-php-relay"
pkg_identifier="el7"

pkg_binary_dest=(
    "opt/remi/php$php_version_short/root/usr/lib64/php/modules"
)

pkg_config_dest=(
    "etc/opt/remi/php$php_version_short/php.d/60-redis.ini"
)

pkg_depends=(
    "openssl11"
    "libev"
    "libzstd"
    "lz4"
    "php$php_version_short-php(api) = $php_api-64"
    "php$php_version_short-php-msgpack"
    "php$php_version_short-php-igbinary"
)

fpm_args=(
  "--after-install /root/fpm/src/rpm/after-install.sh"
)
