{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) lib stdenv ruby rake bundlerEnv nodejs;

  rubyEnv = bundlerEnv {
    name = "rails-app";

    gemdir = ./.;

    groups = [
      "default"
      "development"
      "test"
    ];
  };
in
  pkgs.mkShell {
    buildInputs = [ruby rubyEnv rake nodejs];
  }
