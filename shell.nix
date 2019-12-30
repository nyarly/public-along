with (import /home/judson/dev/nixpkgs {});
(bundlerEnv {
  pname = "diecut";
  gemdir = ./.;
  groups = [ "default" "development" ];
}).env
