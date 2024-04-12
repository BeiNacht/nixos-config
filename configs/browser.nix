{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  environment.systemPackages = with unstable.pkgs; [
    brave
    chromium
    firefox
    librewolf
    tor-browser-bundle-bin
  ];
}
