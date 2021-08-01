{ config, pkgs, lib, ... }:
{
  imports = [ <home-manager/nixos> ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;

    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" "libvirtd" "lp" "scanner" ];
    };
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.alex = { pkgs, ... }: {
    home.packages = [
      pkgs.cryfs
    ];

    programs = {
      ssh = {
        enable = true;
        compression = true;
        serverAliveInterval = 60;
        forwardAgent = true;

        matchBlocks."szczepan.ski" = {
          hostname = "szczepan.ski";
        };

        matchBlocks."nixos-vm" = {
          hostname = "192.168.122.33";
        };

        matchBlocks."mini" = {
          hostname = "192.168.0.87";
        };

        matchBlocks."router" = {
          hostname = "192.168.1.1";
          user = "root";
          localForwards = [ {
            bind.address = "127.0.0.1";
            bind.port = 1337;
            host.address = "127.0.0.1";
            host.port = 80;
          } ];
        };

        matchBlocks."homeserver" = {
          hostname = "192.168.1.100";
          # remoteForwards = [ {
          #   bind.address = "127.0.0.1";
          #   bind.port = 52698;
          #   host.address = "127.0.0.1";
          #   host.port = 52698;
          # } ];
        };
      };

      git = {
        enable = true;
        userName  = "Alexander Szczepanski";
        userEmail = "alexander@szczepan.ski";
        extraConfig = {
          push = { default = "current"; };
          pull = { rebase = true; };
        };
      };

      vscode = {
        enable = true;
        package = pkgs.vscode;
        extensions = with pkgs.vscode-extensions; [
          bbenoist.Nix
          justusadam.language-haskell
          editorconfig.editorconfig
          ms-azuretools.vscode-docker
          #hsnazar.hyper-term-theme
          #rafaelmaiolla.remote-vscode
          eamodio.gitlens
        ];
        # userSettings = {
        #   #"terminal.integrated.fontFamily" = "Hack";
        #   "workbench.colorTheme" = "Hyper Term Black";
        #   "window.titleBarStyle" = "custom";
        # };
      };

      rofi = {
        enable = true;
        lines = 10;
        borderWidth = 2;
        scrollbar = false;
        padding = 50;
        font = "Liberation Sans Regular 20";
        separator = "solid";
        colors = {
          window = {
            background = "#dd000000";
            border = "#a6a6a6";
            separator = "#a6a6a6";
          };
          rows = {
            normal = {
              background = "#00000000";
              foreground = "#a6a6a6";
              backgroundAlt = "#00000000";
              highlight = {
                background = "#a6a6a6";
                foreground = "#000000";
              };
            };
          };
        };
        extraConfig = {
          modi = "drun,window";
          show-icons = true;
        };
      };

      mpv = {
        enable = true;
      };

      kitty = {
        enable = true;
        extraConfig = ''
            enabled_layouts splits:split_axis=vertical
            enable_audio_bell false

            map F5 launch --location=hsplit
            map F6 launch --location=vsplit
            map F7 layout_action rotate

            map shift+up move_window up
            map shift+left move_window left
            map shift+right move_window right
            map shift+down move_window down

            map ctrl+left neighboring_window left
            map ctrl+right neighboring_window right
            map ctrl+up neighboring_window up
            map ctrl+down neighboring_window down

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

    # manuals not needed
    manual.html.enable = false;
    manual.json.enable = false;
    manual.manpages.enable = false;
  };
}
