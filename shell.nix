{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) lib stdenv ruby_2_3 rake bundler bundlerEnv openssl freetds defaultGemConfig pkgconfig nodejs yarn;


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
    buildInputs = [rubyEnv rubyEnv.wrappedRuby rubyEnv.envPaths nodejs yarn];
  }
