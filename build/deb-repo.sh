#!/bin/bash

gpg --batch --import key-private.asc

dists="xenial bionic focal"
architectures="amd64 arm64"

cd deb

for dist in $dists; do
  for arch in $architectures; do
    mkdir -p dists/$dist/main/binary-$arch

    find pool -name "*-$arch.deb" -exec bash -c "mv \$0 \${0/-$arch/_$arch}" {} \;

    dpkg-scanpackages --multiversion --arch $arch \
      pool > dists/$dist/main/binary-$arch/Packages

    gzip -kf9 dists/$dist/main/binary-$arch/Packages
  done

  apt-ftparchive release \
    -o APT::FTPArchive::Release::Origin="cachewerk.s3.amazonaws.com" \
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
