with (import /home/judson/dev/nixpkgs {});
(bundlerEnv {
  pname = "shex-map";
  gemdir = ./.;
  groups = [ "default" "development" ];
}).env
