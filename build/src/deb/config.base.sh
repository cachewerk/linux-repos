#!/bin/bash

pkg_name="php-relay"
pkg_identifier=$distro

case "$distro" in
  noble | plucky | trixie)
    pkg_binary="relay.so" ;;
  *)
    pkg_binary="relay-pkg.so" ;;
esac

pkg_depends=(
    "php$php_version-relay"
    "php$php_version-igbinary"
    "php$php_version-msgpack"
)

[[ ! "$pkg_binary" == *-pkg* ]] && pkg_depends+=(
  "libhiredis1.1.0 >= 1.1.0"
  "libck0 >= 0.7.0"
)

fpm_args=(
  "--deb-pre-depends 'php-common'"
  "--after-install /root/build/src/deb/after-install.sh"

  # This package ships no files of its own. The word "metapackage" is what tells
  # lintian to skip its empty-package and arch-dependent-files checks, so keep
  # it. The $'...' quoting is required: fpm does not expand \n in --description.
  "--description $'Relay metapackage for PHP $php_version\nThis dependency metapackage pulls in the Relay extension for PHP\n$php_version along with its companion extensions.'"
)
