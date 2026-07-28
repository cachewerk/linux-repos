#!/bin/bash

set -e

# Counterpart to after-install-multi.sh, which enables the module. Without this,
# removing the package leaves relay enabled and PHP loads a relay.so that is no
# longer there. Mirrors what Debian's own PHP extension packages do in postrm.
#
# Nothing here may abort the removal, so every call tolerates failure: by the
# time this runs the PHP tooling may already be gone.

if [ "$1" = "remove" ]; then
  if [ -e /usr/lib/php/php-maintscript-helper ]; then
    . /usr/lib/php/php-maintscript-helper
    php_invoke dismod "<%= php_version %>" ALL relay || true
  elif command -v phpdismod > /dev/null; then
    phpdismod -v "<%= php_version %>" relay || true
  fi
fi

# dpkg removes the conffile itself, but the symlinks phpenmod created are not
# owned by the package. Sweep any that still point at our ini, which is what is
# left behind when the helper above was already unavailable.
if [ "$1" = "purge" ]; then
  find "/etc/php/<%= php_version %>" -type l 2>/dev/null | while read -r symlink; do
    if [ "$(basename "$(readlink -m "${symlink}")")" = "relay.ini" ]; then
      rm -f "${symlink}"
    fi
  done
fi

exit 0
