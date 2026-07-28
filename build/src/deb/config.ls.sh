#!/bin/bash

pkg_name="lsphp$php_version_short-relay"
pkg_identifier=$distro

case "$distro" in
  noble | plucky | trixie)
    pkg_binary="relay.so" ;;
  *)
    pkg_binary="relay-pkg.so" ;;
esac

pkg_binary_dest=(
    "usr/local/lsws/lsphp$php_version_short/lib/php/$php_api"
)

pkg_config_dest=(
    "usr/local/lsws/lsphp$php_version_short/etc/php/$php_version/mods-available/60-relay.ini"
)

pkg_depends=(
    "libc6 >= 2.17"
    "liblz4-1 >= 0.0~r130"
    "libzstd1 >= 1.3.2"
    "lsphp$php_version_short-common"
    "lsphp$php_version_short-igbinary"
    "lsphp$php_version_short-msgpack"
)

[[ ! "$pkg_binary" == *-pkg* ]] && pkg_depends+=(
  "libhiredis1.1.0 >= 1.1.0"
  "libck0 >= 0.7.0"
)

# LiteSpeed keeps its bundled PHP under /usr/local, so these packages cannot
# follow the FHS the way the regular ones do. The ini has to stay a conffile
# despite living outside /etc, or a user's settings would be overwritten on
# every upgrade.
pkg_lintian_overrides=(
  "dir-in-usr-local"
  "file-in-usr-local"
  "file-in-unusual-dir"
  "file-in-usr-marked-as-conffile"
  "non-etc-file-marked-as-conffile"
)

fpm_args=(
  "--after-install /root/build/src/deb/after-install.sh"
)
