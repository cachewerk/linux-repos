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

  # ships no files; the word "metapackage" is what makes lintian skip its
  # empty-package checks, and $'...' is required since fpm won't expand \n
  "--description $'Relay metapackage for PHP $php_version\nThis dependency metapackage pulls in the Relay extension for PHP\n$php_version along with its companion extensions.'"
)
