{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "electron-12.2.3"
    ];
    config.packageOverrides = pkgs: {
      steam = pkgs.steam.override {
        extraPkgs = pkgs: with unstable.pkgs; [
          gamescope
          mangohud
        ];
      };
    };
  };
in
{
  imports = [ <home-manager/nixos> ];

  home-manager.users.alex = { pkgs, ... }: {
    home = {
      packages = with unstable.pkgs; [
        brave
        chromium
        # bitwarden
        # cura
        czkawka
        discord
        # etcher
        firefox
        # font-manager
        # freecad
        # homebank
        insomnia
        # kdenlive
        libreoffice
        lutris
        meld
        # obs-studio
        pinta
        # prusa-slicer
        # rpi-imager
        signal-desktop
        steam
        solaar
        spotify
        # teams
        virtmanager
        vulkan-tools
        wine
        winetricks
      ];
    };
  };
}
