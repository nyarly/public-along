{ pkgs ? import <nixpkgs> {} }:
let
  rubyEnv = pkgs.bundlerEnv {
    name = "rhet-butler";
    pname = "rhet-butler";

    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;

    groups = [
      "deploy"
      "default"
      "development"
      "test"
    ];
  };
in
  rubyEnv.env
