{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) lib stdenv ruby_2_3 rake bundler bundlerEnv openssl defaultGemConfig pkgconfig nodejs;

  rubyEnv = bundlerEnv {
    name = "mezzo";
    ruby = ruby_2_3;

    gemdir = ./.;

    groups = [
      "default"
      "development"
      "test"
    ];

    gemConfig = defaultGemConfig // {
      tiny_tds = attrs: {
        nativeBuildInputs = [pkgconfig openssl];
      };
    };
  };
in
  pkgs.mkShell {
    buildInputs = [ruby_2_3 rubyEnv nodejs];
  }
