{
  config,
  pkgs,
  lib,
  outputs,
  ...
}: {
  users.extraGroups.gamemode.members = ["alex"];

  programs = {
    gamescope = {
      enable = true;
      capSysNice = false;
    };

    gamemode = {
      enable = true;
      enableRenice = true;
    };

    steam = {
      enable = true;
      extraPackages = with pkgs; [
        gamescope
        mangohud_git
        libkrb5
        keyutils
      ];

      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    lutris
    heroic

    vkbasalt

    protontricks
    protonup-qt
    vulkan-tools

    gamemode

    wine
    winetricks
    # proton-ge-bin
    # pcsx2
    mangohud_git
  ];
}
