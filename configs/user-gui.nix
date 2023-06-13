{ config, pkgs, lib, ... }:

with builtins;
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports = [ <home-manager/nixos> ];

  home-manager.users.alex = { pkgs, ... }: {
    home = {
      packages = with unstable.pkgs; [
        baobab
        # barrier
        keepassxc
        ponymix
        # mullvad-vpn
        # dracula-theme
        # deadbeef
        grsync
      ];
    };


    services = { syncthing = { enable = true; }; };

    programs = {
      vscode = {
        enable = true;
        package = unstable.pkgs.vscode;
        # extensions = with unstable.pkgs.vscode-extensions; [
        #   bbenoist.nix
        #   eamodio.gitlens
        #   editorconfig.editorconfig
        #   ms-azuretools.vscode-docker
        #   # ms-vsliveshare.vsliveshare
        #   # ms-vscode.cpptools
        #   mskelton.one-dark-theme
        #   ms-kubernetes-tools.vscode-kubernetes-tools
        #   ryu1kn.partial-diff
        #   jnoortheen.nix-ide
        #   brettm12345.nixfmt-vscode
        # ];
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
    };
  };
}
