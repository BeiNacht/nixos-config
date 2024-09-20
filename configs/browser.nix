{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
    pkgs.brave
    pkgs.firefox
    pkgs.librewolf
    pkgs.tor-browser-bundle-bin
  ];
}
