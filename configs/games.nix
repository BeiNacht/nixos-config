{ config, pkgs, lib, outputs, ... }:
{

  services.flatpak.enable = true;
  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
      package = pkgs.unstable.gamescope;
    };

    gamemode = {
      enable = true;
      enableRenice = true;
    };

    steam = {
      enable = true;
      package = pkgs.unstable.steam;
      extraPackages = with pkgs; [
        unstable.gamescope
        unstable.mangohud
      ];

      extraCompatPackages = with pkgs; [
        proton-ge-custom
      ];
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
