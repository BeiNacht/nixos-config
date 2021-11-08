{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports = [ <home-manager/nixos> ];

  home-manager.users.alex = { pkgs, ... }: {
    home = {
      packages = with unstable.pkgs; [
        bitwarden
        cura
        cypress
        discord
        etcher
        firefox
        font-manager
        freecad
        fslint
        gnome.cheese
        homebank
        insomnia
        kdenlive
        libreoffice
        lutris
        mangohud
        meld
        obs-studio
        pinta
        prusa-slicer
        rpi-imager
        signal-desktop
        solaar
        spotify
        steam
        teams
        virtmanager
        vulkan-tools
        wine
        winetricks
      ];
    };
  };
}
