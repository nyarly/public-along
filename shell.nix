let
  srcDef = builtins.fromJSON (builtins.readFile ./nixpkgs.json);
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz";
    sha256 = "0mhqhq21y5vrr1f30qd2bvydv4bbbslvyzclhw0kdxmkgg3z4c92";
  };


  # The Mozilla overlay exposes dynamic, constantly updating
  # rust binaries for development tooling. Not recommended
  # for production or CI builds, but is right now the best way
  # to get Clippy, since Clippy only compiles withm Nighly :(.
  #
  # Note it exposes the overlay at:
  #
  #    latest.rustChannels.stable.rust
  #
  # and has a corresponding attrset for nightly.
  mozilla-overlay =
    import
  (
    builtins.fetchTarball
    https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz
  );

  pkgs = import nixpkgs {
    overlays = [ mozilla-overlay ];
  };
in
pkgs.mkShell rec {
  buildInputs = [
    pkgs.latest.rustChannels.stable.rust
    pkgs.carnix
  ];
  # Enable printing backtraces for rust binaries
  RUST_BACKTRACE = 1;
}
