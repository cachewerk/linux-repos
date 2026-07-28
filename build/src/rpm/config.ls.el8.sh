#!/bin/bash

pkg_name="lsphp$php_version_short-relay"
pkg_binary="relay-pkg.so"
pkg_identifier="el8"

pkg_binary_dest=(
    "usr/local/lsws/lsphp$php_version_short/lib64/php/modules"
)

pkg_config_dest=(
    "usr/local/lsws/lsphp$php_version_short/etc/php.d/60-relay.ini"
)

pkg_depends=(
    "openssl"
    "lsphp$php_version_short(api) = $php_api"
    "lsphp$php_version_short-json"
    "lsphp$php_version_short-session"
    "lsphp$php_version_short-pecl-msgpack"
    "lsphp$php_version_short-pecl-igbinary"
)

fpm_args=(
  # dlopen'd at startup, not linked; el7 keeps them as requires, rpm 4.11
  # predates weak dependencies
  "--rpm-tag 'Recommends: libzstd'"
  "--rpm-tag 'Recommends: lz4'"
  "--after-install /root/build/src/rpm/after-install.sh"
)
