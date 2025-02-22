#!/bin/bash

set -e

uuid=$(cat /proc/sys/kernel/random/uuid)

<% binary_paths.split(' ').each do |binary_path| -%>
sed -i "s/00000000-0000-0000-0000-000000000000/${uuid}/" <%= binary_path %>/relay.so
<% end -%>

if [ -e /usr/lib/php/php-maintscript-helper ]; then
  . /usr/lib/php/php-maintscript-helper
  php_invoke enmod "<%= php_version %>" cli relay || exit 1
  php_invoke enmod "<%= php_version %>" fpm relay || exit 1
else
  phpenmod -v "<%= php_version %>" -s cli relay
  phpenmod -v "<%= php_version %>" -s fpm relay
fi

exit 0
