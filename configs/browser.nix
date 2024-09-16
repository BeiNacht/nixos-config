{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
    pkgs.brave
    # pkgs.unstable.chromium
    pkgs.unstable.firefox
    pkgs.unstable.librewolf
    pkgs.unstable.tor-browser-bundle-bin
  ];
}
