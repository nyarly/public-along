let
  moz_overlay = import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz);
  pkgs = import <nixpkgs> { overlays = [ moz_overlay ]; };
  mozrust = pkgs.latest.rustChannels.stable;
in
pkgs.mkShell {
  buildInputs =  with pkgs; [ mozrust.rust openssl pkgconfig sqlite ];
}
