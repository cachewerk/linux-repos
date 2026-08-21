#!/bin/bash

set -e

source /root/build/helpers.sh
source /root/build/distros.sh

version=$1
baseurl="https://builds.r2.relay.so/$version/relay-$version"

declare -A php_api=(
  ["7.4"]=20190902
  ["8.0"]=20200930
  ["8.1"]=20210902
  ["8.2"]=20220829
  ["8.3"]=20230831
  ["8.4"]=20240924
  ["8.5"]=20250925
)

# LiteSpeed does not ship an `lsphp` runtime for every PHP version on every EL
# release, and an `ls` package for a missing one carries a `Requires` that no
# repository can ever satisfy. Derived from the `lsphpNN(api)` provides in
# https://rpms.litespeedtech.com/centos/<el>/<arch>/ -- recheck when adding a
# PHP version or an EL release.
declare -A lsphp_versions=(
  ["el7 x86_64"]="7.4 8.0 8.1 8.2 8.3"              # no 8.4/8.5
  ["el7 aarch64"]=""                                 # no aarch64 repository
  ["el8 x86_64"]="7.4 8.0 8.1 8.2 8.3 8.4 8.5"
  ["el8 aarch64"]="7.4 8.0 8.1 8.2 8.3 8.4 8.5"
  ["el9 x86_64"]="8.0 8.1 8.2 8.3 8.4 8.5"          # no 7.4
  ["el9 aarch64"]="7.4 8.0 8.1 8.2 8.3 8.4 8.5"
  ["el10 x86_64"]="8.1 8.2 8.3 8.4 8.5"             # no 7.4/8.0
  ["el10 aarch64"]="8.1 8.2 8.3 8.4 8.5"            # no 7.4/8.0
)

packages=()

for deb in "${deb_dists[@]}"; do
  case "$deb" in
    jammy | noble | plucky | bookworm | trixie) variant=+libssl3 ;;
    *) variant="" ;;
  esac

  for arch in amd64 arm64; do
    arch_url=$(echo $arch | sed 's/amd64/x86-64/; s/arm64/aarch64/')

    packages+=(
      "$deb deb base $arch 8.4 20240924 $baseurl-php8.4-debian-${arch_url}${variant}.tar.gz"
    )

    for php in 7.4 8.0 8.1 8.2 8.3 8.4 8.5; do
      api=${php_api[$php]}

      packages+=(
        "$deb deb multi $arch $php $api $baseurl-php$php-debian-${arch_url}${variant}.tar.gz"
        "$deb deb ls    $arch $php $api $baseurl-php$php-debian-${arch_url}${variant}.tar.gz"
      )
    done
  done
done

for el in "${el_dists[@]}"; do
  url_distro=$(echo $el | sed 's/el7/centos7/; s/el8/centos8/')

  for arch in x86_64 aarch64; do
    # an unrecorded combination would silently ship no `ls` packages at all
    if [[ -z "${lsphp_versions["$el $arch"]+set}" ]]; then
      echo "Error: no lsphp availability recorded for $el $arch" >&2
      exit 1
    fi

    for php in 7.4 8.0 8.1 8.2 8.3 8.4 8.5; do
      api=${php_api[$php]}
      url="$baseurl-php$php-$url_distro-${arch/_/-}.tar.gz"

      packages+=(
        "$el rpm single.$el $arch $php $api $url"
        "$el rpm multi.$el  $arch $php $api $url"
      )

      if [[ " ${lsphp_versions["$el $arch"]} " == *" $php "* ]]; then
        packages+=(
          "$el rpm ls.$el     $arch $php $api $url"
        )
      fi
    done
  done
done

main

exit 255
