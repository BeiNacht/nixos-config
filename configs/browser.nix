{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs.unstable; [
    brave
    chromium
    firefox
    librewolf
    tor-browser-bundle-bin
  ];
}
