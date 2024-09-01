{ config, pkgs, lib, outputs, ... }:
{

  services.flatpak.enable = true;
  programs = {
    gamescope = {
      enable = true;
      capSysNice = false;
      package = pkgs.unstable.gamescope;
    };

    gamemode = {
      enable = true;
      enableRenice = true;
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
    # (lutris.override {
    #   extraPkgs = pkgs: [
    #     pkgs.gamescope
    #     pkgs.mangohud
    #   ];
    # })

    lutris
    heroic

    protontricks
    protonup-qt
    vulkan-tools

    gamemode

    wine
    winetricks
    # proton-ge-bin
    pcsx2
    mangohud
  ];
}
