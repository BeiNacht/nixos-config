{ config, pkgs, lib, outputs, ... }:
{
  programs = {
    gamescope = {
      enable = true;
      capSysNice = false;
      package = pkgs.gamescope;
    };

    gamemode = {
      enable = true;
      enableRenice = true;
    };

    steam = {
      enable = true;
      # package = pkgs.unstable.steam;
      extraPackages = with pkgs; [
        gamescope
        mangohud
        libkrb5
        keyutils
      ];

      # extraCompatPackages = with pkgs; [
      #   proton-ge-custom
      # ];
    };
  };

  environment.systemPackages = with pkgs; [
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
