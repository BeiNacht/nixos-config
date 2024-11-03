{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../configs/common.nix ../configs/docker.nix ../configs/user.nix];

  fileSystems."/export/docker" = {
    device = "/home/alex/docker";
    options = ["bind"];
  };
}
