#!/bin/bash

pkg_name="php$php_version-relay"
pkg_provides="php-relay"
pkg_identifier="debian"

pkg_binary_dest=(
    "usr/lib/php/$php_api"
)

pkg_config_dest=(
    "etc/php/$php_version/mods-available/relay.ini"
)

pkg_depends=(
    "libc6 >= 2.17"
    "liblz4-1 >= 0.0~r130"
    "libzstd1 >= 1.3.2"
    "php$php_version-common"
    "php$php_version-igbinary"
    "php$php_version-msgpack"
)

fpm_args=(
  "--replaces 'php-relay << ${version#v}'"
  "--deb-pre-depends 'php-common'"
  "--deb-field 'Source: php-relay'"
  "--after-install /root/fpm/src/deb/after-install-multi.sh"
)
