{ config, pkgs, lib, ... }:
{
  imports = [ <home-manager/nixos> ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;

    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" "libvirtd" ];
    };
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.alex = { pkgs, ... }: {
    home.packages = [
      pkgs.cryfs
      pkgs.cinnamon.nemo
    ];

    dconf.enable = true;
    dconf.settings = with lib.hm.gvariant; {
      #"org/gnome/desktop/wm/preferences".button-layout = "close:maximize";
      "org/gnome/desktop/wm/preferences".titlebar-font = "Liberation Sans Bold 9";
      #   visual-bell = false;
      #   titlebar-font = "Liberation Sans Bold 9";
      # };
      # "org/gnome/mutter" = {
      #   button-mode = "programming";
      #   show-thousands = true;
      #   base = 10;
      #   word-size = 64;
      #   window-position = lib.hm.gvariant.mkTuple [100 100];
      # };
    };

    programs = {
      ssh = {
        enable = true;
        compression = true;
        serverAliveInterval = 60;

        matchBlocks."homeserver" = {
          hostname = "192.168.1.100";
          remoteForwards = [ {
            bind.address = "127.0.0.1";
            bind.port = 52698;
            host.address = "127.0.0.1";
            host.port = 52698;
          } ];
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
