#!/bin/bash
# Run inside the FPM image with the repository mounted read-only at /workspace.
# Uses a fixture shared library; never downloads or publishes Relay binaries.
set -e

cp -a /workspace/build/. /root/build/
cd /root/build
mkdir -p dist changelog /tmp/fixture
printf 'int fixture(void) { return 0; }\n' > /tmp/fixture.c
cc -shared -fPIC /tmp/fixture.c -o /tmp/fixture/relay.so
cp /tmp/fixture/relay.so /tmp/fixture/relay-pkg.so
printf '; fixture\n' > /tmp/fixture/relay.ini
printf 'Fixture license\n' > /tmp/fixture/LICENSE
printf '1750000000\n' > changelog/epoch
cat > changelog/deb.tpl <<'EOF'
@PKG@ (0.50.0) unstable; urgency=medium

  * Fixture release.

 -- Relay Team <hello@cachewerk.com>  Sun, 15 Jun 2025 15:06:40 +0000
EOF
cat > changelog/rpm <<'EOF'
* Sun Jun 15 2025 Relay Team <hello@cachewerk.com> - 0.50.0-1
- Fixture release.
EOF

export DEB_REVISION=2 RPM_REVISION=3
bash ./fpm.sh v0.50.0 --list | cut -f6 > selected-packages.txt
source ./helpers.sh
build_dir=/root/build
mode=build
version=v0.50.0

for config in base multi ls; do
  unset ${!pkg_@}
  fpm_build noble deb "$config" amd64 8.4 20240924 https://example.invalid/fixture.tar.gz
done
for config in single.el9 multi.el9 ls.el9; do
  unset ${!pkg_@}
  fpm_build el9 rpm "$config" x86_64 8.4 20240924 https://example.invalid/fixture.tar.gz
done

for file in dist/*.deb; do
  test "$(dpkg-deb -f "$file" Version)" = 0.50.0-2
done
for file in dist/*.rpm; do
  test "$(rpm -qp --qf '%{VERSION}-%{RELEASE}' "$file")" = 0.50.0-3
  rpm -qp --changelog "$file" | head -1 | grep -F -- '0.50.0-3'
done
dpkg-deb -x dist/php8.4-relay-0.50.0-2-php8.4-noble-amd64.deb /tmp/extracted
gzip -dc /tmp/extracted/usr/share/doc/php8.4-relay/changelog.gz | head -1 | grep -F '(0.50.0-2)'
echo 'Verified three DEBs and three RPMs, including revisioned changelogs.'
