#!/bin/bash

set -e

source /root/fpm/helpers.sh

version=$1
baseurl="https://builds.r2.relay.so/$version/relay-$version"

packages=(
  "deb base       amd64  8.2 20200930 $baseurl-php8.1-debian-x86-64.tar.gz"
  "deb multi      amd64  8.2 20210902 $baseurl-php8.2-debian-x86-64.tar.gz"
  "deb multi      amd64  8.1 20210902 $baseurl-php8.1-debian-x86-64.tar.gz"
  "deb multi      amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64.tar.gz"
  "deb multi      amd64  7.4 20190902 $baseurl-php7.4-debian-x86-64.tar.gz"

  "deb base       amd64  8.2 20200930 $baseurl-php8.1-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.2 20210902 $baseurl-php8.2-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.1 20210902 $baseurl-php8.1-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  8.0 20200930 $baseurl-php8.0-debian-x86-64+libssl3.tar.gz +libssl3"
  "deb multi      amd64  7.4 20190902 $baseurl-php7.4-debian-x86-64+libssl3.tar.gz +libssl3"

  "deb base       arm64  8.2 20200930 $baseurl-php8.1-debian-aarch64.tar.gz"
  "deb multi      arm64  8.2 20210902 $baseurl-php8.2-debian-aarch64.tar.gz"
  "deb multi      arm64  8.1 20210902 $baseurl-php8.1-debian-aarch64.tar.gz"
  "deb multi      arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64.tar.gz"
  "deb multi      arm64  7.4 20190902 $baseurl-php7.4-debian-aarch64.tar.gz"

  "deb base       arm64  8.2 20200930 $baseurl-php8.1-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.2 20210902 $baseurl-php8.2-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.1 20210902 $baseurl-php8.1-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  8.0 20200930 $baseurl-php8.0-debian-aarch64+libssl3.tar.gz +libssl3"
  "deb multi      arm64  7.4 20190902 $baseurl-php7.4-debian-aarch64+libssl3.tar.gz +libssl3"

  "rpm single.el7 x86_64 8.2 20220829 $baseurl-php8.2-centos7-x86-64.tar.gz"
  "rpm single.el7 x86_64 8.1 20210902 $baseurl-php8.1-centos7-x86-64.tar.gz"
  "rpm single.el7 x86_64 8.0 20200930 $baseurl-php8.0-centos7-x86-64.tar.gz"
  "rpm single.el7 x86_64 7.4 20190902 $baseurl-php7.4-centos7-x86-64.tar.gz"
  "rpm multi.el7  x86_64 8.2 20220829 $baseurl-php8.2-centos7-x86-64.tar.gz"
  "rpm multi.el7  x86_64 8.1 20210902 $baseurl-php8.1-centos7-x86-64.tar.gz"
  "rpm multi.el7  x86_64 8.0 20200930 $baseurl-php8.0-centos7-x86-64.tar.gz"
  "rpm multi.el7  x86_64 7.4 20190902 $baseurl-php7.4-centos7-x86-64.tar.gz"

  "rpm single.el7 aarch64 8.2 20220829 $baseurl-php8.2-centos7-aarch64.tar.gz"
  "rpm single.el7 aarch64 8.1 20210902 $baseurl-php8.1-centos7-aarch64.tar.gz"
  "rpm single.el7 aarch64 8.0 20200930 $baseurl-php8.0-centos7-aarch64.tar.gz"
  "rpm single.el7 aarch64 7.4 20190902 $baseurl-php7.4-centos7-aarch64.tar.gz"
  "rpm multi.el7  aarch64 8.2 20220829 $baseurl-php8.2-centos7-aarch64.tar.gz"
  "rpm multi.el7  aarch64 8.1 20210902 $baseurl-php8.1-centos7-aarch64.tar.gz"
  "rpm multi.el7  aarch64 8.0 20200930 $baseurl-php8.0-centos7-aarch64.tar.gz"
  "rpm multi.el7  aarch64 7.4 20190902 $baseurl-php7.4-centos7-aarch64.tar.gz"

  "rpm single.el8 x86_64 8.2 20220829 $baseurl-php8.2-centos8-x86-64.tar.gz"
  "rpm single.el8 x86_64 8.1 20210902 $baseurl-php8.1-centos8-x86-64.tar.gz"
  "rpm single.el8 x86_64 8.0 20200930 $baseurl-php8.0-centos8-x86-64.tar.gz"
  "rpm single.el8 x86_64 7.4 20190902 $baseurl-php7.4-centos8-x86-64.tar.gz"
  "rpm multi.el8  x86_64 8.2 20220829 $baseurl-php8.2-centos8-x86-64.tar.gz"
  "rpm multi.el8  x86_64 8.1 20210902 $baseurl-php8.1-centos8-x86-64.tar.gz"
  "rpm multi.el8  x86_64 8.0 20200930 $baseurl-php8.0-centos8-x86-64.tar.gz"
  "rpm multi.el8  x86_64 7.4 20190902 $baseurl-php7.4-centos8-x86-64.tar.gz"

  "rpm single.el8 aarch64 8.2 20220829 $baseurl-php8.2-centos8-aarch64.tar.gz"
  "rpm single.el8 aarch64 8.1 20210902 $baseurl-php8.1-centos8-aarch64.tar.gz"
  "rpm single.el8 aarch64 8.0 20200930 $baseurl-php8.0-centos8-aarch64.tar.gz"
  "rpm single.el8 aarch64 7.4 20190902 $baseurl-php7.4-centos8-aarch64.tar.gz"
  "rpm multi.el8  aarch64 8.2 20220829 $baseurl-php8.2-centos8-aarch64.tar.gz"
  "rpm multi.el8  aarch64 8.1 20210902 $baseurl-php8.1-centos8-aarch64.tar.gz"
  "rpm multi.el8  aarch64 8.0 20200930 $baseurl-php8.0-centos8-aarch64.tar.gz"
  "rpm multi.el8  aarch64 7.4 20190902 $baseurl-php7.4-centos8-aarch64.tar.gz"

  "rpm single.el9 x86_64 8.2 20220829 $baseurl-php8.2-el9-x86-64.tar.gz"
  "rpm single.el9 x86_64 8.1 20210902 $baseurl-php8.1-el9-x86-64.tar.gz"
  "rpm single.el9 x86_64 8.0 20200930 $baseurl-php8.0-el9-x86-64.tar.gz"
  "rpm single.el9 x86_64 7.4 20190902 $baseurl-php7.4-el9-x86-64.tar.gz"
  "rpm multi.el9  x86_64 8.2 20220829 $baseurl-php8.2-el9-x86-64.tar.gz"
  "rpm multi.el9  x86_64 8.1 20210902 $baseurl-php8.1-el9-x86-64.tar.gz"
  "rpm multi.el9  x86_64 8.0 20200930 $baseurl-php8.0-el9-x86-64.tar.gz"
  "rpm multi.el9  x86_64 7.4 20190902 $baseurl-php7.4-el9-x86-64.tar.gz"

  "rpm single.el9 aarch64 8.2 20220829 $baseurl-php8.2-el9-aarch64.tar.gz"
  "rpm single.el9 aarch64 8.1 20210902 $baseurl-php8.1-el9-aarch64.tar.gz"
  "rpm single.el9 aarch64 8.0 20200930 $baseurl-php8.0-el9-aarch64.tar.gz"
  "rpm single.el9 aarch64 7.4 20190902 $baseurl-php7.4-el9-aarch64.tar.gz"
  "rpm multi.el9  aarch64 8.2 20220829 $baseurl-php8.2-el9-aarch64.tar.gz"
  "rpm multi.el9  aarch64 8.1 20210902 $baseurl-php8.1-el9-aarch64.tar.gz"
  "rpm multi.el9  aarch64 8.0 20200930 $baseurl-php8.0-el9-aarch64.tar.gz"
  "rpm multi.el9  aarch64 7.4 20190902 $baseurl-php7.4-el9-aarch64.tar.gz"
)

main

exit 255
