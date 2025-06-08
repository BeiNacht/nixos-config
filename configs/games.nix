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

  home-manager.users.alex = {config, pkgs, ...}: {
    home.packages = with pkgs; [
      gamemode
      heroic
      mangohud_git
      pcsx2
      protontricks
      protonup-qt
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

    xdg.dataFile = {
      "Steam/compatibilitytools.d/SteamTinkerLaunch/compatibilitytool.vdf".text = ''
        "compatibilitytools"
        {
          "compat_tools"
          {
            "Proton-stl" // Internal name of this tool
            {
              "install_path" "."
              "display_name" "Steam Tinker Launch"

              "from_oslist"  "windows"
              "to_oslist"    "linux"
            }
          }
        }
      '';
      "Steam/compatibilitytools.d/SteamTinkerLaunch/steamtinkerlaunch".source =
        config.lib.file.mkOutOfStoreSymlink "${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch";
      "Steam/compatibilitytools.d/SteamTinkerLaunch/toolmanifest.vdf".text = ''
        "manifest"
        {
          "commandline" "/steamtinkerlaunch run"
          "commandline_waitforexitandrun" "/steamtinkerlaunch waitforexitandrun"
        }
      '';
    };
  };
}
