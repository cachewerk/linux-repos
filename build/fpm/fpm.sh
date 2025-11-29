#!/bin/bash

set -e

source /root/fpm/helpers.sh

version=$1
baseurl="https://builds.r2.relay.so/$version/relay-$version"

packages=(
  "deb base       amd64  8.4 20240924 $baseurl-php8.3-debian-x86-64.tar.gz"
  "deb multi      amd64  8.5 20250925 $baseurl-php8.5-debian-x86-64.tar.gz"
  "deb multi      amd64  8.4 20240924 $baseurl-php8.4-debian-x86-64.tar.gz"
  "deb multi      amd64  8.3 20230831 $baseurl-php8.3-debian-x86-64.tar.gz"
  "deb multi      amd64  8.2 20220829 $baseurl-php8.2-debian-x86-64.tar.gz"
  "deb multi      amd64  8.1 20210902 $baseurl-php8.1-debian-x86-64.tar.gz"
  "deb multi      amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64.tar.gz"
  "deb multi      amd64  7.4 20190902 $baseurl-php7.4-debian-x86-64.tar.gz"
  "deb ls         amd64  8.5 20250925 $baseurl-php8.5-debian-x86-64.tar.gz"
  "deb ls         amd64  8.4 20240924 $baseurl-php8.4-debian-x86-64.tar.gz"
  "deb ls         amd64  8.3 20230831 $baseurl-php8.3-debian-x86-64.tar.gz"
  "deb ls         amd64  8.2 20220829 $baseurl-php8.2-debian-x86-64.tar.gz"
  "deb ls         amd64  8.1 20210902 $baseurl-php8.1-debian-x86-64.tar.gz"
  "deb ls         amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64.tar.gz"
  "deb ls         amd64  7.4 20190902 $baseurl-php7.4-debian-x86-64.tar.gz"

  "deb base       amd64  8.4 20240924 $baseurl-php8.3-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.5 20250925 $baseurl-php8.5-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.4 20240924 $baseurl-php8.4-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.3 20230831 $baseurl-php8.3-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.2 20220829 $baseurl-php8.2-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.1 20210902 $baseurl-php8.1-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  7.4 20190902 $baseurl-php7.4-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb ls         amd64  8.5 20250925 $baseurl-php8.5-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb ls         amd64  8.4 20240924 $baseurl-php8.4-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb ls         amd64  8.3 20230831 $baseurl-php8.3-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb ls         amd64  8.2 20220829 $baseurl-php8.2-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb ls         amd64  8.1 20210902 $baseurl-php8.1-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb ls         amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb ls         amd64  7.4 20190902 $baseurl-php7.4-debian-x86-64+libssl3.tar.gz +libssl3"

  "deb base       arm64  8.4 20240924 $baseurl-php8.3-debian-aarch64.tar.gz"
  "deb multi      arm64  8.5 20250925 $baseurl-php8.5-debian-aarch64.tar.gz"
  "deb multi      arm64  8.4 20240924 $baseurl-php8.4-debian-aarch64.tar.gz"
  "deb multi      arm64  8.3 20230831 $baseurl-php8.3-debian-aarch64.tar.gz"
  "deb multi      arm64  8.2 20220829 $baseurl-php8.2-debian-aarch64.tar.gz"
  "deb multi      arm64  8.1 20210902 $baseurl-php8.1-debian-aarch64.tar.gz"
  "deb multi      arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64.tar.gz"
  "deb multi      arm64  7.4 20190902 $baseurl-php7.4-debian-aarch64.tar.gz"
  "deb ls         arm64  8.5 20250925 $baseurl-php8.5-debian-aarch64.tar.gz"
  "deb ls         arm64  8.4 20240924 $baseurl-php8.4-debian-aarch64.tar.gz"
  "deb ls         arm64  8.3 20230831 $baseurl-php8.3-debian-aarch64.tar.gz"
  "deb ls         arm64  8.2 20220829 $baseurl-php8.2-debian-aarch64.tar.gz"
  "deb ls         arm64  8.1 20210902 $baseurl-php8.1-debian-aarch64.tar.gz"
  "deb ls         arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64.tar.gz"
  "deb ls         arm64  7.4 20190902 $baseurl-php7.4-debian-aarch64.tar.gz"

  "deb base       arm64  8.4 20240924 $baseurl-php8.3-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.5 20250925 $baseurl-php8.5-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.4 20240924 $baseurl-php8.4-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.3 20230831 $baseurl-php8.3-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.2 20220829 $baseurl-php8.2-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.1 20210902 $baseurl-php8.1-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  7.4 20190902 $baseurl-php7.4-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb ls         arm64  8.5 20250925 $baseurl-php8.5-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb ls         arm64  8.4 20240924 $baseurl-php8.4-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb ls         arm64  8.3 20230831 $baseurl-php8.3-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb ls         arm64  8.2 20220829 $baseurl-php8.2-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb ls         arm64  8.1 20210902 $baseurl-php8.1-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb ls         arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb ls         arm64  7.4 20190902 $baseurl-php7.4-debian-aarch64+libssl3.tar.gz +libssl3"
)

declare -A php_api=(
  ["7.4"]=20190902
  ["8.0"]=20200930
  ["8.1"]=20210902
  ["8.2"]=20220829
  ["8.3"]=20230831
  ["8.4"]=20240924
  ["8.5"]=20250925
)

for el in el7 el8 el9; do
  for arch in x86_64 aarch64; do
    for php in 7.4 8.0 8.1 8.2 8.3 8.4 8.5; do
      api=${php_api[$php]}
      packages+=(
        "rpm single.$el $arch $php $api $baseurl-php$php-$el-${arch/_/-}.tar.gz"
        "rpm multi.$el  $arch $php $api $baseurl-php$php-$el-${arch/_/-}.tar.gz"
        "rpm ls.$el     $arch $php $api $baseurl-php$php-$el-${arch/_/-}.tar.gz"
      )
    done
  done
done

main

exit 255
