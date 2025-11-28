#!/bin/bash

gpg --batch --import key-private.asc

#       16.04  18.04 20.04 22.04 24.04       9     10       11       12     13
dists="xenial bionic focal jammy noble stretch buster bullseye bookworm trixie"
architectures="amd64 arm64"

symlink_pkg='pkg=${0/pool/$1}; mkdir -p $(dirname $pkg); [ ! -L $pkg ] && ln -sr $0 $pkg'

cd deb

for dist in $dists; do

  case "$dist" in
    jammy | noble | bookworm | trixie)
      find pool -name "*.deb" -name '*+libssl*' -exec bash -c "$symlink_pkg" {} pools/$dist \; ;;
    *)
      find pool -name "*.deb" ! -name '*+*' -exec bash -c "$symlink_pkg" {} pools/$dist \; ;;
  esac

  for arch in $architectures; do
    mkdir -p dists/$dist/main/binary-$arch

    echo "Building $dist repository for $arch with $pattern"

    dpkg-scanpackages --multiversion --arch $arch \
      pools/$dist > dists/$dist/main/binary-$arch/Packages

    gzip -kf9 dists/$dist/main/binary-$arch/Packages
  done

  apt-ftparchive release \
    -o APT::FTPArchive::Release::Origin="repos.r2.relay.so" \
    -o APT::FTPArchive::Release::Label="CacheWerk" \
    -o APT::FTPArchive::Release::Architectures="amd64 aarch64" \
    -o APT::FTPArchive::Release::Codename="$dist" \
    -o APT::FTPArchive::Release::Suite="$dist" \
    -o APT::FTPArchive::Release::Components="main" \
    dists/$dist > dists/$dist/Release

  gpg --default-key "DFA6681F024DE2877F013F27AE02C2F1B72DE128" \
    --pinentry-mode=loopback --passphrase "$GPG_PASSPHRASE" \
    -abs -o - dists/$dist/Release > dists/$dist/Release.gpg

  gpg --default-key "DFA6681F024DE2877F013F27AE02C2F1B72DE128" \
    --pinentry-mode=loopback --passphrase "$GPG_PASSPHRASE" \
    --clearsign -o - dists/$dist/Release > dists/$dist/InRelease
done
