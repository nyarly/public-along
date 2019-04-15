{ pkgs ? import <nixpkgs> {} }:
let
  rubyEnv = pkgs.bundlerEnv {
    name = "rhet-butler";
    pname = "rhet-butler";

    gemdir = ./.;

    groups = [
      "deploy"
      "default"
      "development"
      "test"
    ];
  };
in
  rubyEnv.env
