#!/bin/bash

pkg_name="php-relay"
pkg_binary="relay-pkg.so"
pkg_identifier="el8"

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
    "php(api) = $php_api-64"
    "php-json"
    "php-session"
    "php-msgpack"
    "php-igbinary"
)

fpm_args=(
  # Relay dlopens these at startup rather than linking them, so they are
  # wanted but not required. el7 keeps them as hard requires: rpm 4.11
  # predates weak dependencies and would drop them silently.
  "--rpm-tag 'Recommends: libzstd'"
  "--rpm-tag 'Recommends: lz4'"
  "--after-install /root/build/src/rpm/after-install.sh"
)
