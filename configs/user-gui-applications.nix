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
    brave
    catfish
    chromium
    czkawka # fslint before
    discord
    espeak-ng
    firefox
    handbrake
    insomnia
    libreoffice
    librewolf
    lutris
    meld
    nextcloud-client
    pinta
    signal-desktop
    solaar
    remmina
    spotify
    tor-browser-bundle-bin
    virtmanager
    vulkan-tools
    wine
    winetricks

  ];
}
