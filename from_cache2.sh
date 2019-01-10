set -e

# DEBUG #
#set -x

cache_path="$1"

(cd "$cache_path"

  echo >&2 FROM CACHE: I AM AT $PWD

  echo -n "{"
  ls -1 */*/ivydata-*.properties | sed 's|^\(\(.*\)/\(.*\)/ivydata-\(.*\).properties\)$|\1 \2 \3 \4|' \
  | while read prop group name version; do
    dir="$(dirname $prop)"
    #version="$(sed -n '1 s/^#.*;//p' $prop)"

    echo -n "
  \"$group/$name/$version\" = {
    group = \"$group\";
    name = \"$name\";
    version = \"$version\";
    files = ["

    sed -n '/^artifact\\:.*\\#\(jar\|pom\|xml\)\\#.*\.location=/ { s/\(^artifact\\:\|[-0-9]*\.location=\)//g; s/\\:/:/g; s/\\#/ /g; p };' "$prop" \
    | while read name subdir typ url; do
      # DEBUG #
      #echo $prop $version $name $subdir $type $url
      #continue

      if [ "$typ" == jar ] || [ "$typ" == pom ] || ([ "$typ" == xml ] && [ "$subdir" == ivy ] && grep -q '/ivy.xml$'<<<$url); then
        if [ "$typ" == jar ]; then
          path="$dir/${subdir}s/$name-$version.jar"
        elif [ "$typ" == pom ]; then
          path="$dir/ivy-$version.xml.original"
          echo >&2 $typ $subdir $path $url
        elif [ "$typ" == xml ]; then
          path="$dir/ivy-$version.xml"
          echo >&2 $typ $subdir $path $url
        fi

        test -f "$path" || path="$url"

        if test -f "$path"; then
          sha="$(sha256sum "$path" | cut -d" " -f1)"
        elif grep -q '^http'<<<$path; then
          sha="$(nix-prefetch-url $path)"
        else
          echo >&2 "$path not a file or a URL"
          continue
        fi

        echo -n "
        { type = \"$typ\"; name = \"$(basename $path)\"; sha256 = \"$sha\"; }"
      fi
    done

    echo -n "
    ];
  };"
  done
  echo "
}"
)
