#!/bin/bash

pkg_name="php$php_version_short-php-relay"
pkg_binary="relay-pkg.so"
pkg_identifier="el10"

pkg_binary_dest=(
    "opt/remi/php$php_version_short/root/usr/lib64/php/modules"
)

pkg_config_dest=(
    "etc/opt/remi/php$php_version_short/php.d/60-relay.ini"
)

pkg_depends=(
    "openssl"
    # "hiredis >= 1.1.0"
    # "ck >= 0.7.0"
    "php$php_version_short-php(api) = $php_api-64"
    "php$php_version_short-php-json"
    "php$php_version_short-php-session"
    "php$php_version_short-php-msgpack"
    "php$php_version_short-php-igbinary"
)

fpm_args=(
  # dlopen'd at startup since Relay v0.40.0, not linked
  "--rpm-tag 'Recommends: libzstd'"
  "--rpm-tag 'Recommends: lz4'"
  "--after-install /root/build/src/rpm/after-install.sh"
)
