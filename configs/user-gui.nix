{ config, pkgs, lib, ... }:

with builtins;
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports = [ <home-manager/nixos> ];

  environment.systemPackages = with unstable.pkgs; [
    xfce.catfish
    czkawka # fslint before
    discord
    espeak-ng
    handbrake
    insomnia
    libreoffice
    meld
    nextcloud-client
    pinta
    signal-desktop
    solaar
    remmina
    spotify
    baobab
    keepassxc
    grsync
    virt-manager
    rustdesk
  ];

  home-manager.users.alex = { pkgs, ... }: {
    # services = { syncthing = { enable = true; }; };

    programs = {
      vscode = {
        enable = true;
        package = unstable.pkgs.vscode;
      };

      mpv = {
        enable = true;
        config = {
          hwdec = "auto-safe";
          vo = "gpu";
          profile = "gpu-hq";
        };
      };

      git = {
        extraConfig = {
          credential.helper = "${
              pkgs.git.override { withLibsecret = true; }
            }/bin/git-credential-libsecret";
        };
      };

      kitty = {
        enable = true;
        extraConfig = ''
          enable_audio_bell false

          background            #000000
          foreground            #e9e9e9
          cursor                #e9e9e9
          selection_background  #424242
          color0                #000000
          color8                #000000
          color1                #d44d53
          color9                #d44d53
          color2                #b9c949
          color10               #b9c949
          color3                #e6c446
          color11               #e6c446
          color4                #79a6da
          color12               #79a6da
          color5                #c396d7
          color13               #c396d7
          color6                #70c0b1
          color14               #70c0b1
          color7                #fffefe
          color15               #fffefe
          selection_foreground #000000
        '';
      };
    };
  };
}
