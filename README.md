# sbtnix

Generate Nix expressions from a SBT project.

## Installation

```
git clone https://github.com/icetan/sbtnix
nix-env -f sbtnix -i sbtnix
```

## Usage

```
cd my/little/sbt/project/dir
sbtnix
```

Create a build expression.

```
echo '
{ pkgs ? import <nixpkgs> {} }:
(pkgs.callPackage ./sbt-env.nix {}) {
  name = "my-little-project";
  src = ./.;
  artifacts = import ./artifacts.nix;
}
' > default.nix
nix-build
```
