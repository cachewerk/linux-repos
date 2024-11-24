#!/bin/bash

set -e

uuid=$(cat /proc/sys/kernel/random/uuid)

<% binary_paths.split(' ').each do |binary_path| -%>
sed -i "s/BIN:31415926-5358-9793-2384-626433832795/BIN:${uuid}/" <%= binary_path %>/relay.so
<% end -%>

exit 0
