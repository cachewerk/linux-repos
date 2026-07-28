
# NOTE: must NOT be named pkg_*, main() runs `unset ${!pkg_@}` before every build
read -r -d '' relay_description <<'DESCRIPTION' || true
Next-generation caching layer for PHP
Relay is a fast, persistent, in-memory cache for PHP that serves as a drop-in
replacement for PhpRedis. It keeps a partial replica of the Redis or Valkey
data set inside the PHP process, avoiding network round trips and decoding
costs for cached keys.
DESCRIPTION

main()
{
  rm -rf /tmp/relay*
  rm -rf /root/build/dist
  mkdir /root/build/dist

  echo -n "$version" > /root/build/dist/TAG

  for package in "${packages[@]}"; do
    unset ${!pkg_@}
    fpm_build $package
  done

  exit 0
}

fpm_build()
{
  distro=$1
  type=$2
  config=$3
  pkg_arch=$4
  php_version=$5
  php_version_short=${5//./}
  php_api=$6
  pkg_url=$7

  # we don't have centos builds for v0.1.0
  if [[ "$version" == "v0.1.0" && "$type" == "rpm" ]]; then
    echo "Skipping RPMs for v0.1.0"
    return 0
  fi

  source /root/build/src/$type/config.$config.sh

  echo "Building Relay ($version) .$type package for PHP $php_version on $pkg_arch"

  src_path=/tmp/$(basename $pkg_url .tar.gz)
  dest_path=/root/build/src/$type/$pkg_arch-php$php_version

  if [[ ! -d "$src_path" ]]; then
    echo "Downloading $pkg_url"
    curl -s ${pkg_url//+/%2B} | tar xz -C /tmp
  fi

  rm -rf $dest_path
  mkdir -p $dest_path

  for binary_path in "${pkg_binary_dest[@]}"; do
    mkdir -p $dest_path/$binary_path
    cp $src_path/$pkg_binary $dest_path/$binary_path/relay.so
  done

  for config_file in "${pkg_config_dest[@]}"; do
    mkdir -p $(dirname $dest_path/$config_file)
    cp $src_path/relay.ini $dest_path/$config_file
  done

  # Debian policy requires /usr/share/doc/<pkg>/copyright; rpm wants documentation.
  # The year comes from the release date so the file stays reproducible.
  mkdir -p $dest_path/usr/share/doc/$pkg_name
  {
    echo "Copyright (C) 2021-$(date -u -d @$(cat /root/build/changelog.epoch) +%Y) CacheWerk, Inc."
    echo "All rights reserved."
    echo
    echo "Relay is proprietary software, licensed under the End-User License"
    echo "Agreement reproduced below."
    echo
    cat $src_path/LICENSE
  } > $dest_path/usr/share/doc/$pkg_name/copyright

  pkg_version=${version#v}
  pkg_filename="${pkg_name}-${pkg_version}-php${php_version}-${pkg_identifier}-${pkg_arch}.${type}"

  args=(
    "--input-type dir"
    "--output-type $type"

    "--maintainer 'Relay Team <hello@cachewerk.com>'"
    "--description '$relay_description'"
    "--url 'https://relay.so'"
    "--license 'Proprietary'"
    "--category 'php'"
    "--name '$pkg_name'"
    "--version '$pkg_version'"
    "--architecture $pkg_arch"

    "--package dist/$pkg_filename"
    "--source-date-epoch-default $(cat /root/build/changelog.epoch)"

    "--template-value binary_paths='$pkg_binary_dest'"
    "--template-value php_version='$php_version'"

    "--deb-priority 'optional'"
    "--deb-no-default-config-files"
  )

  # `Vendor` is a real rpm tag but not a valid Debian control field. fpm guards
  # the deb line with `!vendor.empty?`, so an explicit empty value omits it.
  # Don't try the same on --license: that line is emitted unconditionally, so an
  # empty value adds `empty-field` on top of the existing `unknown-field`.
  if [[ "$type" == "rpm" ]]; then
    args+=("--vendor 'CacheWerk, Inc.'")
  else
    args+=("--vendor ''")
  fi

  # changelogs: deb entries embed the binary package name, rpm entries do not
  if [[ "$type" == "deb" ]]; then
    sed "s/@PKG@/$pkg_name/g" /root/build/changelog.deb.tpl > /tmp/changelog-$pkg_name.deb
    args+=("--deb-changelog /tmp/changelog-$pkg_name.deb")
  else
    args+=("--rpm-changelog /root/build/changelog.rpm")
  fi

  if [ ! -z "$pkg_provides" ]; then
    args+=("--provides '$pkg_provides'")
  fi

  for fpm_arg in "${fpm_args[@]}"; do
    args+=("${fpm_arg[@]}")
  done

  for dependency in "${pkg_depends[@]}"; do
    args+=("--depends '${dependency[@]}'")
  done

  for config_file in "${pkg_config_dest[@]}"; do
    args+=("--config-files /$config_file")
  done

  args="${args[@]}"

  echo "Building package: $pkg_filename"
  bash -c "fpm $args $dest_path/=/"
}
