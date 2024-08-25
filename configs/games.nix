{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
    config.packageOverrides = pkgs: {
      lutris = pkgs.lutris.override {
        extraPkgs = pkgs: with unstable.pkgs; [ gamescope mangohud ];
      };
    };
  };
in
{
  programs = {
    gamescope.enable = true;
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs: with pkgs; [
          gamescope
          mangohud
          libkrb5
          keyutils
        ];
      };
    };
  };

  environment.systemPackages = with unstable.pkgs; [
    lutris
    protontricks
    protonup-qt
    vulkan-tools
    wine
    winetricks
    pcsx2
  ];
}
