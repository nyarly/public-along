{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) lib stdenv ruby_2_3 rake bundler bundlerEnv openssl defaultGemConfig pkgconfig nodejs freetds redis;

  rubyEnv = bundlerEnv {
    name = "mezzo";
    ruby = ruby_2_3;

    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;

    groups = [
      "default"
      "development"
      "test"
    ];

    gemConfig = defaultGemConfig // {
      tiny_tds = attrs: {
        nativeBuildInputs = [pkgconfig openssl freetds];
      };
    };
  };
in
  pkgs.mkShell {
    buildInputs = [ruby_2_3 rubyEnv rake nodejs redis];
  }
