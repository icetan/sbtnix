{ stdenv, lib, mktemp, sbt, jdk, runCommand, writeScriptBin, writeText, fetchurl
, makeWrapper, requireFile }:

let
  repositories = writeText "repositories-local" ''
    [repositories]
      local
  '';

  filterSrc = src: builtins.filterSource (path: type:
    let
      p = toString path;
      isResult = type == "symlink" && lib.hasPrefix "result" (builtins.baseNameOf p);
      isIgnore = type == "directory" && builtins.elem (builtins.baseNameOf p) [ "target" ];
      check = ! (isResult || isIgnore);
    in check
  ) src;

  ivy-convertpom = runCommand "ivy-convertpom" { buildInputs = [ makeWrapper ]; } ''
    makeWrapper ${jdk}/bin/java $out/bin/ivy-convertpom \
      --add-flags "-jar ${./ivy-convertpom.jar}"
  '';

  urlToScript = (path: dep: let
    authenticated = false;
    fetch = (if authenticated then requireFile else fetchurl) dep;
  in ''
    mkdir -p "$out/$(dirname "${path}")"
    ln -sfv "${fetch}" "$out/${path}"
  '');
  #+ (if (lib.hasSuffix ".xml.original" path) then (
  #  let
  #    ivyxmlPath = lib.substring 0 ((lib.stringLength path) - 9) path;
  #  in
  #    # XXX: for some reason IVY isn't adding the XML namespace ivy/extra to
  #    # the ivy.xml so I sed it in afterwards :(
  #    ''
  #      ${ivy-convertpom}/bin/ivy-convertpom ${fetch} "$out/${ivyxmlPath}"
  #      sed -i"" '/^<ivy-module / { / xmlns:e=/! s|>$| xmlns:e="http://ant.apache.org/ivy/extra">| }' "$out/${ivyxmlPath}"
  #    ''
  #) else ''
  #  ln -sfv "${fetch}" "$out/${path}"
  #''));

  mkCache = artifacts: runCommand "mk-ivy-cache" {} (
    (lib.concatStrings (map
      (path: urlToScript path (builtins.getAttr path artifacts))
      (builtins.attrNames artifacts)
    )) + ''
      set -x
      find $out -name "*.xml.original" | while read xmlFile; do
        pomFile="$(echo $xmlFile | sed 's/\.original$//')"
        ${jdk}/bin/java -Divyconvertpom.cache="$out" -jar ${./ivy-convertpom.jar} "$xmlFile" "$pomFile"
        sed -i"" '/^<ivy-module / { / xmlns:e=/! s|>$| xmlns:e="http://ant.apache.org/ivy/extra">| }' "$pomFile"
      done
    ''
  );

  sbt-offline = artifacts: writeScriptBin "sbt-offline" ''
    TMP_IVY="$(${mktemp}/bin/mktemp -d --tmpdir sbtnix-ivy.XXXXXX)"
    ln -s "${mkCache artifacts}" "$TMP_IVY/cache"

    cleanup() { rm -rf "$TMP_IVY" || true; }
    trap "trap - TERM; cleanup; kill -- $$" EXIT INT TERM

    exec ${jdk}/bin/java -jar -Dsbt.boot.directory=$PWD/.sbt/boot \
      ${sbt}/share/sbt/bin/sbt-launch.jar \
        -Dsbt.build.offline=true \
        -Dsbt.ivy.home=$TMP_IVY \
        -Dsbt.repository.config=${repositories} \
        "set offline := true" \
        "set offline in Global := true" \
        "set skip in update := true" \
        "$@"
  '';

  buildSbt =
  { name
  , src ? ./.
  , artifacts ? import ./artifacts.nix
  , buildInputs ? []
  }: lib.makeOverridable stdenv.mkDerivation {
    inherit name;
    src = filterSrc src;
    buildInputs = [ (sbt-offline artifacts) ] ++ buildInputs;

    phases = "unpackPhase checkPhase buildPhase installPhase";

    checkPhase = ''
      runHook preCheck

      sbt-offline test

      runHook postCheck
    '';

    buildPhase = ''
      runHook preBuild

      sbt-offline package

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      dir="$out/share/java"
      mkdir -p $dir

      find target -type f -maxdepth 1 -exec cp {} $dir \;

      runHook postInstall
    '';
  };
in buildSbt
