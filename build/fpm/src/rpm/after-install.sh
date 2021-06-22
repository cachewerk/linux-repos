#!/bin/bash

set -e

uuid=$(uuidgen -r)

<% binary_paths.split(' ').each do |binary_path| -%>
sed -i "s/31415926-5358-9793-2384-626433832795/${uuid}/" <%= binary_path %>/relay.so
<% end -%>

exit 0
