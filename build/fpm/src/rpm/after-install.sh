#!/bin/bash

set -e

uuid=$(uuidgen -r)

<% binary_paths.split(' ').each do |binary_path| -%>
sed -i "s/00000000-0000-0000-0000-000000000000/${uuid}/" <%= binary_path %>/relay.so
sed -i "s/BIN:31415926-5358-9793-2384-626433832795/BIN:${uuid}/" <%= binary_path %>/relay.so
<% end -%>

exit 0
