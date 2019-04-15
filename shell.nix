{ pkgs ? import <nixpkgs> {} }:
let
  rubyEnv = pkgs.bundlerEnv {
    name = "rubygem";

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
