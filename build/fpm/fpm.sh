#!/bin/bash

set -e

source /root/fpm/helpers.sh

version=$1
baseurl="https://cachewerk.s3.amazonaws.com/relay/$version/relay-$version"

packages=(
  "deb base       amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64.tar.gz"
  "deb multi      amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64.tar.gz"
  "deb multi      amd64  7.4 20190902 $baseurl-php7.4-debian-x86-64.tar.gz"

  "deb base       arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64.tar.gz"
  "deb multi      arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64.tar.gz"
  "deb multi      arm64  7.4 20190902 $baseurl-php7.4-debian-aarch64.tar.gz"

  "rpm single.el7 x86_64 8.0 20200930 $baseurl-php8.0-centos7-x86-64.tar.gz"
  "rpm single.el7 x86_64 7.4 20190902 $baseurl-php7.4-centos7-x86-64.tar.gz"
  "rpm multi.el7  x86_64 8.0 20200930 $baseurl-php8.0-centos7-x86-64.tar.gz"
  "rpm multi.el7  x86_64 7.4 20190902 $baseurl-php7.4-centos7-x86-64.tar.gz"

  "rpm single.el7 aarch64 8.0 20200930 $baseurl-php8.0-centos7-aarch64.tar.gz"
  "rpm single.el7 aarch64 7.4 20190902 $baseurl-php7.4-centos7-aarch64.tar.gz"
  "rpm multi.el7  aarch64 8.0 20200930 $baseurl-php8.0-centos7-aarch64.tar.gz"
  "rpm multi.el7  aarch64 7.4 20190902 $baseurl-php7.4-centos7-aarch64.tar.gz"

  "rpm single.el8 x86_64 8.0 20200930 $baseurl-php8.0-centos8-x86-64.tar.gz"
  "rpm single.el8 x86_64 7.4 20190902 $baseurl-php7.4-centos8-x86-64.tar.gz"
  "rpm multi.el8  x86_64 8.0 20200930 $baseurl-php8.0-centos8-x86-64.tar.gz"
  "rpm multi.el8  x86_64 7.4 20190902 $baseurl-php7.4-centos8-x86-64.tar.gz"

  "rpm single.el8 aarch64 8.0 20200930 $baseurl-php8.0-centos8-aarch64.tar.gz"
  "rpm single.el8 aarch64 7.4 20190902 $baseurl-php7.4-centos8-aarch64.tar.gz"
  "rpm multi.el8  aarch64 8.0 20200930 $baseurl-php8.0-centos8-aarch64.tar.gz"
  "rpm multi.el8  aarch64 7.4 20190902 $baseurl-php7.4-centos8-aarch64.tar.gz"
)

main

exit 255
