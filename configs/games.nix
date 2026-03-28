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
        # mangohud_git
        libkrb5
        keyutils
      ];

#      extraCompatPackages = with pkgs; [
#        proton-ge-bin
#      ];
    };
  };

  home-manager.users.alex = {
    config,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      gamemode
      heroic
      mangohud
      pcsx2
      protontricks
      protonup-qt
#      shadps4
      steamtinkerlaunch
      vkbasalt
      vulkan-tools
      wine
      winetricks
      (lutris.override {
        extraLibraries = pkgs: [
          gamemode
        ];
      })
    ];
  };
}
