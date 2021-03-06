{ lib, writeScriptBin, writeText, mktemp, sbt, bash }:

let
  name = "sbtnix";
  version = "0.0.1";
  gen-header = "# This file has been generated by ${name} ${version}. Do not edit!";
  artifactsFromCache = writeScriptBin "from-ivy-cache"
    (builtins.readFile ./from_cache2.sh);
  ivy-convertpom = import ./ivy-convertpom {};
  repositories = ''
    [repositories]
      maven-central
      typesafe-ivy-releases: https://repo.typesafe.com/typesafe/ivy-releases/, [organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext], bootOnly
      sbt-ivy-snapshots: https://repo.scala-sbt.org/scalasbt/ivy-snapshots/, [organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext], bootOnly
  '';
  repositoriesFile = writeText "repositories-remote" repositories;
  boot = writeText "sbt-boot-properties" ''
    [scala]
      version: ''${sbt.scala.version-auto}

    [app]
      org: ''${sbt.organization-org.scala-sbt}
      name: sbt
      version: ''${sbt.version-read(sbt.version)[''${{sbt.version}}]}
      class: ''${sbt.main.class-sbt.xMain}
      components: xsbti,extra
      cross-versioned: ''${sbt.cross.versioned-false}
      resources: ''${sbt.extraClasspath-}

    ${repositories}

    [boot]
      directory: ''${sbt.boot.directory}

    [ivy]
      ivy-home: ''${sbt.ivy.home}
      checksums: ''${sbt.checksums-sha1,md5}
      override-build-repos: ''${sbt.override.build.repos-false}
      repository-config: ${repositoriesFile}
  '';
in writeScriptBin name ''
  #!${bash}/bin/bash
  set -e

  usage() {
    test "$1" && echo -e Error: $1\\n || true
    cat <<EOF
    Usage: $(basename $0) [OPTIONS]

    OPTIONS
      --output, -o      Generated nix files output directory
      --debug, -d       Debug mode (ivy cache is not destroyed)
  EOF
    exit 1
  }

  # Defaults
  outputDir="."

  # Parse CLI arguments
  while test $1;do
    case $1 in
      -o|--output) outputDir="$2";shift 2;;
      -d|--debug) debug=1;set -x;shift;;
      *) usage;;
    esac
  done

  # Arg validation
  test -d "$outputDir" || usage "\"$outputDir\" is not a directory"

  if test "$debug"; then
    TMP_IVY="sbtnix-debug-ivy-home"
    TMP_BOOT="sbtnix-debug-boot"
    mkdir -p $TMP_IVY $TMP_BOOT
  else
    TMP_IVY="$(${mktemp}/bin/mktemp -d --tmpdir sbtnix-ivy.XXXXXX)"
    TMP_BOOT="$(${mktemp}/bin/mktemp -d --tmpdir sbtnix-boot.XXXXXX)"
    cleanup() { rm -rf "$TMP_IVY" "$TMP_BOOT" || true; }
    trap "trap - TERM; cleanup; kill -- $$" EXIT INT TERM
  fi

  ${sbt}/bin/sbt -Dsbt.boot.properties=${boot} -Dsbt.boot.directory=$TMP_BOOT -Dsbt.ivy.home=$TMP_IVY update
  (echo "${gen-header}";${artifactsFromCache}/bin/from-ivy-cache "$TMP_IVY/cache") \
    > "$outputDir/artifacts.nix"
  (echo "${gen-header}";cat ${./sbt-env.nix}) \
    > "$outputDir/sbt-env.nix"
  cp ${ivy-convertpom.build}/share/java/ivy-convertpom-*-with-dependencies.jar \
    "$outputDir/ivy-convertpom.jar"
  chmod u+w "$outputDir/ivy-convertpom.jar"
''
