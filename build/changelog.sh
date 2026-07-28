#!/bin/bash

# Renders Debian and RPM changelogs from the cachewerk/relay GitHub releases feed.
#
#   changelog.sh <releases.json> <version> <out_dir>
#
# Writes:
#   $out_dir/changelog.deb.tpl   Debian format, with @PKG@ standing in for the binary
#                                package name (substituted per package by fpm_build)
#   $out_dir/changelog.rpm       RPM %changelog format
#
# Releases newer than $version are dropped so a rebuild of an older tag does not
# claim changes it does not contain.

set -e

releases=$1
version=${2#v}
out=$3

maintainer="Relay Team <hello@cachewerk.com>"

# Release notes are written for GitHub and routinely exceed 80 columns, which
# lintian flags as debian-changelog-line-too-long. Re-wrap the bullet lines.
wrap_bullets()
{
  awk -v prefix="$1" -v cont="$2" -v max=76 '
    index($0, prefix) != 1 { print; next }
    {
      text = substr($0, length(prefix) + 1)
      n = split(text, w, " ")
      line = prefix w[1]
      for (i = 2; i <= n; i++) {
        if (length(line) + 1 + length(w[i]) > max) { print line; line = cont w[i] }
        else line = line " " w[i]
      }
      print line
    }'
}

# The topmost entry has to match the version being packaged, so refuse to run
# rather than emit a changelog that claims the wrong release.
if ! jq -e --arg v "$version" 'any(.[]; (.draft | not) and (.tag_name | ltrimstr("v")) == $v)' \
     "$releases" > /dev/null; then
  echo "No published release found for $version" >&2
  exit 1
fi

# Newest first, drop drafts, drop anything above the version being built.
filtered=$(jq --arg v "$version" '
  map(select(.draft | not))
  | sort_by(.published_at)
  | reverse
  | map(. + {ver: (.tag_name | ltrimstr("v"))})
  | (map(.ver) | index($v)) as $i
  | .[$i:]
' "$releases")

# Bullet lines out of the Keep-a-Changelog markdown body, "### Added" headings dropped.
bullets='
  (.body // "")
  | gsub("\r"; "")
  | split("\n")
  | map(select(test("^\\s*[-*]\\s+\\S")))
  | map(sub("^\\s*[-*]\\s+"; ""))
  | map(gsub("\\s+$"; ""))
'

echo "$filtered" | jq -r --arg m "$maintainer" "
  .[]
  | ($bullets) as \$b
  | (if (\$b | length) == 0 then [\"Relay \" + .ver] else \$b end) as \$b
  | \"@PKG@ (\" + .ver + \") unstable; urgency=medium\n\n\"
    + (\$b | map(\"  * \" + .) | join(\"\n\"))
    + \"\n\n -- \" + \$m + \"  \"
    + (.published_at | fromdateiso8601 | strftime(\"%a, %d %b %Y %H:%M:%S +0000\"))
    + \"\n\"
" | wrap_bullets "  * " "    " > "$out/changelog.deb.tpl"

echo "$filtered" | jq -r --arg m "$maintainer" "
  .[]
  | ($bullets) as \$b
  | (if (\$b | length) == 0 then [\"Relay \" + .ver] else \$b end) as \$b
  | \"* \" + (.published_at | fromdateiso8601 | strftime(\"%a %b %d %Y\"))
    + \" \" + \$m + \" - \" + .ver + \"-1\n\"
    + (\$b | map(\"- \" + .) | join(\"\n\"))
    + \"\n\"
" | wrap_bullets "- " "  " > "$out/changelog.rpm"

# Timestamp of the release being packaged. fpm stamps the gzipped changelog with
# the source date epoch, and lintian flags the package when that is newer than
# the newest changelog entry, so the two have to come from the same place.
echo "$filtered" | jq -r '.[0].published_at | fromdateiso8601' > "$out/changelog.epoch"

echo "Wrote $(grep -c '^@PKG@' "$out/changelog.deb.tpl") deb entries, $(grep -c '^\* ' "$out/changelog.rpm") rpm entries"
