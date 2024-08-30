{ config, pkgs, lib, outputs, ... }:
{
  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam = {
      enable = true;
      package = pkgs.unstable.steam.override {
        extraPkgs = pkgs: [
          pkgs.gamescope
          pkgs.mangohud
          # libkrb5
          # keyutils
        ];
      };
    };
  };

  environment.systemPackages = with pkgs.unstable; [
    (lutris.override {
      extraPkgs = pkgs: [
        pkgs.gamescope
        pkgs.mangohud
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
