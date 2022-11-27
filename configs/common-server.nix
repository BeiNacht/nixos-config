{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [ ../configs/common.nix ../configs/docker.nix ../configs/user.nix ];

  fileSystems."/export/docker" = {
    device = "/home/alex/docker";
    options = [ "bind" ];
  };
}
