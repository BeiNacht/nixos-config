{ config, pkgs, lib, ... }:
let
unstable = import <nixos-unstable> {
  config.allowUnfree = true;
  config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with unstable.pkgs; [
        gamescope
        mangohud
        ncurses6
      ];
    };
    lutris = pkgs.lutris.override {
      extraPkgs = pkgs: with unstable.pkgs; [
        gamescope
        mangohud
      ];
    };
  };
};
in
{
  programs.steam = {
    enable = true;
    package = unstable.pkgs.steam;
  };

  environment.systemPackages = with unstable.pkgs; [
    goverlay
    lutris
    protontricks
    protonup-qt
    vulkan-tools
    wine
    winetricks
  ];
}
