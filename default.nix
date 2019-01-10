{ pkgs ? import <nixpkgs> {}
, sbt ? pkgs.sbt
}:

pkgs.callPackage (import ./sbtnix.nix) { inherit sbt; }
