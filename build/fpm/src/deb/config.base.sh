#!/bin/bash

pkg_name="php-relay"
pkg_identifier="debian"

pkg_depends=(
    "php$php_version-relay"
    "php$php_version-igbinary"
    "php$php_version-msgpack"
)

fpm_args=(
  "--deb-pre-depends 'php-common'"
  "--after-install /root/fpm/src/deb/after-install.sh"
)
