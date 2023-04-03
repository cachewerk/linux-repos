#!/bin/bash

export PATH=/opt/gnupg22/bin:$PATH

gpg --batch --import key-private.asc

cd rpm

for DISTRO in el7 el8 el9; do
  pushd $DISTRO
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
