{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  virtualisation = {
    virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
  };
}
