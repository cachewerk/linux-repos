#!/bin/bash
# Called by find -exec ... {} + so a conflict fails the publishing step.
set -e

destination=$1
shift
mkdir -p "$destination"

for package in "$@"; do
  target="$destination/$(basename "$package")"
  if [[ ! -e "$target" ]]; then
    cp "$package" "$target"
  elif ! cmp -s "$package" "$target"; then
    echo "Refusing to overwrite $target with different bytes; bump the packaging revision" >&2
    exit 1
  fi
done
