{
  sbtnixSrc ? { outPath = ./.; revCount = 1234; shortRev = "abcdef"; }
}:

{
  build = { system ? builtins.currentSystem }:
    let
      pkgs = import <nixpkgs> { inherit system; };
    in
      import sbtnixSrc.outPath { inherit pkgs; };
}
