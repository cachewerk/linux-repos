
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

# build the package based on parameters
fpm_build()
{
  pkg_type=$1
  config=$2
  pkg_arch=$3
  php_version=$4
  php_version_short=${4//./}
  php_api=$5
  pkg_url=$6
  pkg_mod=$7

  # we don't have centos builds for v0.1.0
  if [[ "$version" == "v0.1.0" && "$pkg_type" == "rpm" ]]; then
    echo "Skipping RPMs for v0.1.0"
    return 0
  fi

  source /root/fpm/src/$pkg_type/config.$config.sh

  echo "Building Relay ($version) .$pkg_type package for PHP $php_version on $pkg_arch"

  echo "Downloading $pkg_url"
  curl -s ${pkg_url//+/%2B} | tar xz -C /tmp

  src_path=/tmp/$(basename $pkg_url .tar.gz)
  dest_path=/root/fpm/src/$pkg_type/$pkg_arch-php$php_version

  rm -rf $dest_path
  mkdir -p $dest_path

  for binary_path in "${pkg_binary_dest[@]}"; do
    mkdir -p $dest_path/$binary_path
    cp $src_path/relay.so $dest_path/$binary_path/relay.so
  done

  for config_file in "${pkg_config_dest[@]}"; do
    mkdir -p $(dirname $dest_path/$config_file)
    cp $src_path/relay.ini $dest_path/$config_file
  done

  pkg_version=${version#v}
  pkg_filename="${pkg_name}-${pkg_version}-php${php_version}-${pkg_identifier}${pkg_mod}_${pkg_arch}.${pkg_type}"

  args=(
    "--input-type dir"
    "--output-type $pkg_type"

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
