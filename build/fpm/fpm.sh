#!/bin/bash

set -e

source /root/fpm/helpers.sh

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

packages=()

debs=(
  xenial   # 16.04
  bionic   # 18.04
  focal    # 20.04
  jammy    # 22.04
  noble    # 24.04
  plucky   # 25.04
  stretch  # 9
  buster   # 10
  bullseye # 11
  bookworm # 12
  trixie   # 13
)

for deb in "${debs[@]}"; do
  case "$dist" in
    jammy | noble | plucky | bookworm | trixie) variant=+libssl ;;
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
        "$deb deb multi $arch $php $api $baseurl-php$php-debian-${arch_url}.tar.gz"
        "$deb deb ls    $arch $php $api $baseurl-php$php-debian-${arch_url}${variant}.tar.gz"
      )
    done
  done
done

for el in el7 el8 el9; do
  for arch in x86_64 aarch64; do
    for php in 7.4 8.0 8.1 8.2 8.3 8.4 8.5; do
      api=${php_api[$php]}

      packages+=(
        "$el rpm single.$el $arch $php $api $baseurl-php$php-$el-${arch/_/-}.tar.gz"
        "$el rpm multi.$el  $arch $php $api $baseurl-php$php-$el-${arch/_/-}.tar.gz"
        "$el rpm ls.$el     $arch $php $api $baseurl-php$php-$el-${arch/_/-}.tar.gz"
      )
    done
  done
done

main

exit 255
