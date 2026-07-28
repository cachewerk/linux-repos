#!/bin/bash

# Renders changelogs from the relay GitHub releases feed.
#
#   changelog.sh <releases.json> <version> <out_dir>
#
# Writes changelog.deb.tpl (@PKG@ is substituted per package by fpm_build),
# changelog.rpm, and changelog.epoch.

set -e

releases=$1
version=${2#v}
out=$3

maintainer="Relay Team <hello@cachewerk.com>"

# release notes routinely exceed lintian's 80 column limit
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

# the topmost entry has to match the version being packaged
if ! jq -e --arg v "$version" 'any(.[]; (.draft | not) and (.tag_name | ltrimstr("v")) == $v)' \
     "$releases" > /dev/null; then
  echo "No published release found for $version" >&2
  exit 1
fi

# newest first, without drafts or anything above the version being built
filtered=$(jq --arg v "$version" '
  map(select(.draft | not))
  | sort_by(.published_at)
  | reverse
  | map(. + {ver: (.tag_name | ltrimstr("v"))})
  | (map(.ver) | index($v)) as $i
  | .[$i:]
' "$releases")

# bullet lines only, headings dropped
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

# the source date epoch must not be newer than the newest changelog entry
echo "$filtered" | jq -r '.[0].published_at | fromdateiso8601' > "$out/changelog.epoch"

echo "Wrote $(grep -c '^@PKG@' "$out/changelog.deb.tpl") deb entries, $(grep -c '^\* ' "$out/changelog.rpm") rpm entries"
