#!/bin/bash

set -e

# Undoes after-install-multi.sh. Failures are tolerated throughout: the PHP
# tooling may already be gone, and nothing here may block the removal.

if [ "$1" = "remove" ]; then
  if [ -e /usr/lib/php/php-maintscript-helper ]; then
    . /usr/lib/php/php-maintscript-helper
    php_invoke dismod "<%= php_version %>" ALL relay || true
  elif command -v phpdismod > /dev/null; then
    phpdismod -v "<%= php_version %>" relay || true
  fi
fi

# dpkg owns the conffile, but not the symlinks phpenmod created
if [ "$1" = "purge" ]; then
  find "/etc/php/<%= php_version %>" -type l 2>/dev/null | while read -r symlink; do
    if [ "$(basename "$(readlink -m "${symlink}")")" = "relay.ini" ]; then
      rm -f "${symlink}"
    fi
  done
fi

exit 0
