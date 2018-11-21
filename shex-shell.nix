with (import /home/judson/dev/nixpkgs {});
(bundlerEnv {
  pname = "shex";
  gemdir = ./.;
  groups = [ "default" "development" "test" ];
}).env
