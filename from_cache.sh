set -e

# DEBUG #
set -x

cache_path="$1"

(cd "$cache_path"
  echo >&2 FROM CACHE: I AM AT $PWD

  echo -n "{"
  find . -type f -name '*.properties' | sed 's|^\./||' \
  | while read prop; do
    dir="$(dirname $prop)"
    version="$(sed -n '1 s/^#.*;//p' $prop)"

    sed -n '/^artifact\\:.*\\#\(jar\|pom\|xml\)\\#.*\.location=http/ { s/\(^artifact\\:\|[-0-9]*\.location=\)//g; s/\\:/:/g; s/\\#/ /g; p };' "$prop" \
    | while read name subdir typ url; do
      # DEBUG #
      #echo $prop $version $name $subdir $type $url
      #continue

      path=""
      if [ "$typ" == "jar" ]; then
        path="$(ls -1 $dir/${subdir}s/$name-$version*.jar | head -n1)"
        sha="$(sha256sum "$path" | cut -d" " -f1)"
      elif [ "$typ" == "pom" ]; then
        path="$(ls -1 $dir/ivy-$version*.xml.original | head -n1)"
        sha="$(sha256sum "$path" | cut -d" " -f1)"
      elif [[ "$typ" == "xml" && "$subdir" == "ivy" ]] && (grep -q '\.xml$' <<<$url); then
        path="$(ls -1 $dir/ivy-$version*.xml | head -n1)"
        sha="$(nix-prefetch-url $url)"
      else
        continue
      fi
      echo -n "
  \"$path\" = {
    url = \"$url\";
    sha256 = \"$sha\";
  };"
    done
  done
  echo "
}"
)
