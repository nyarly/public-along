with (import <nixpkgs> {});
let
  env = bundlerEnv {
    name = "wsdl-review";
    inherit ruby;
    gemset = ./gemset.nix;
    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
  };
in
  mkShell {
    buildInputs = [ env env.wrappedRuby ];
  }
