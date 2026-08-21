#!/bin/bash

export PATH=/opt/gnupg22/bin:$PATH

gpg --batch --import key-private.asc

source build/distros.sh

cd rpm

for DISTRO in "${el_dists[@]}"; do
  mkdir -p "$DISTRO"
  pushd "$DISTRO"
    createrepo \
      --update --database --pretty \
      --unique-md-filenames .

    gpg \
      --default-key "DFA6681F024DE2877F013F27AE02C2F1B72DE128" \
      --pinentry-mode=loopback --passphrase "$GPG_PASSPHRASE" \
      --detach-sign --armor --batch --yes \
      repodata/repomd.xml
  popd
done
