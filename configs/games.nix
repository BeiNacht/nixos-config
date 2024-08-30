{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
  };
  nix-gaming = import (builtins.fetchTarball "https://github.com/fufexan/nix-gaming/archive/master.tar.gz");
in
{
  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam = {
      enable = true;
      package = unstable.pkgs.steam.override {
        extraPkgs = pkgs: with unstable.pkgs; [
          gamescope
          mangohud
          libkrb5
          keyutils
        ];
      };
    };
  };

  environment.systemPackages = with unstable.pkgs; [
    (lutris.override {
      extraPkgs = pkgs: with unstable.pkgs; [
        gamescope mangohud
        ];
    })

    heroic

    protontricks
    protonup-qt
    vulkan-tools

    gamemode

    wine
    winetricks
    # proton-ge-bin
    pcsx2
    gamescope
    mangohud
  ];
}
