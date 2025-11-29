
main()
{
  rm -rf /root/fpm/dist
  mkdir /root/fpm/dist

  echo -n "$version" > /root/fpm/dist/TAG

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

  source /root/fpm/src/$type/config.$config.sh

  echo "Building Relay ($version) .$type package for PHP $php_version on $pkg_arch"

  src_path=/tmp/$(basename $pkg_url .tar.gz)
  dest_path=/root/fpm/src/$type/$pkg_arch-php$php_version

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

  pkg_version=${version#v}
  pkg_filename="${pkg_name}-${pkg_version}-php${php_version}-${pkg_identifier}_${pkg_arch}.${type}"

  args=(
    "--input-type dir"
    "--output-type $type"

    "--vendor 'CacheWerk, Inc.'"
    "--maintainer 'Relay Team <hello@cachewerk.com>'"
    "--description 'The next-generation caching layer for PHP.'"
    "--url 'https://relay.so'"
    "--license 'Proprietary'"
    "--category 'php'"
    "--name '$pkg_name'"
    "--version '$pkg_version'"
    "--architecture $pkg_arch"

    "--package dist/$pkg_filename"
    "--source-date-epoch-default $(stat -c %Y $src_path/relay.so)"

    "--template-value binary_paths='$pkg_binary_dest'"
    "--template-value php_version='$php_version'"

    "--deb-priority 'optional'"
    "--deb-no-default-config-files"
  )

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
