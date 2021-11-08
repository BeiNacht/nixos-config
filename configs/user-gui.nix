{ config, pkgs, lib, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports = [ <home-manager/nixos> ];

  home-manager.users.alex = { pkgs, ... }: {
    home = {
      file = {
        ".bin/rofi-default-sink.sh" = {
          executable = true;
          source = ./bin/rofi-default-sink.sh;
        };
      };
      packages = with unstable.pkgs; [
        arandr
        baobab
        barrier
        evince
        gnome.eog
        gnome.file-roller
        gnome.gnome-calculator
        keepassxc
        libnotify
      ];
    };

    xdg.desktopEntries = {
      defaultSink = {
        name = "Default Sink";
        exec = "/home/alex/.bin/rofi-default-sink.sh";
        terminal = false;
      };
    };

    services = {
      syncthing = {
        enable = true;
      };
    };

    gtk = {
      enable = true;
      font = {
        name = "Liberation Sans Regular";
        size = 12;
      };
      gtk3 = {
        # bookmarks = [
        #   "file:///home/alex/Downloads"
        #   "file:///home/alex/Nextcloud"
        #   "file:///mnt/second"
        #   "smb://192.168.0.100/storage/"
        #   "file:///home/alex/Workspace"
        #   "file:///home/alex/3D%20Print"
        #   "file:///home/alex/Sync"
        # ];
        extraConfig = { gtk-application-prefer-dark-theme = 1; };
      };
      iconTheme = {
        package = pkgs.pantheon.elementary-icon-theme;
        name = "elementary";
      };
      theme = { name = "Adwaita-dark"; };
    };

    programs = {
      vscode = {
        enable = true;
        package = unstable.pkgs.vscode;
        extensions = with unstable.pkgs.vscode-extensions; [
          bbenoist.nix
          eamodio.gitlens
          editorconfig.editorconfig
          ms-azuretools.vscode-docker
          ms-vsliveshare.vsliveshare
          ms-vscode.cpptools
          mskelton.one-dark-theme
          ms-kubernetes-tools.vscode-kubernetes-tools
          ryu1kn.partial-diff
          jnoortheen.nix-ide
          brettm12345.nixfmt-vscode
        ];
      };

      rofi = {
        enable = true;
        font = "Liberation Sans Regular 20";
        extraConfig = {
          modi = "drun,window";
          show-icons = true;
          color-normal = "#00000000, #a6a6a6, #00000000, #a6a6a6, #000000";
          color-window = "#dd000000, #a6a6a6, #a6a6a6";
          separator-style = "solid";
          padding = 50;
          lines = 10;
          borderWidth = 2;
          hide-scrollbar = true;
        };
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
