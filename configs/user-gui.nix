{ config, pkgs, lib, ... }:
{
  imports = [ <home-manager/nixos> ];

  home-manager.users.alex = { pkgs, ... }: {
    home.packages = [
      pkgs.cryfs
    ];

    programs = {
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

    services = {
      picom = {
        enable = true;
        blur = false;
        shadow = true;
        vSync = true;
      };

      dunst = {
        enable = true;
        settings = {
          global = {
            font = "SF Pro Display Regular 12";
            markup = "yes";
            format = "%s %p\n%b";
            sort = "yes";
            indicate_hidden = "no";
            alignment = "center";
            bounce_freq = 0;
            show_age_threshold = 60;
            word_wrap = "yes";
            ignore_newline = "no";
            geometry = "300x0-5-5";
            shrink = "yes";
            transparency = 0;
            idle_threshold = 120;
            monitor = 0;
            follow = "mouse";
            sticky_history = "yes";
            history_length = 20;
            show_indicators = "no";
            line_height = 0;
            separator_height = 1;
            stack_duplicates = "no";
            padding = 8;
            horizontal_padding = 8;
            separator_color = "frame";
            startup_notification = true;
            # dmenu = /usr/bin/dmenu -p dunst;
            # browser = /usr/bin/firefox -new-tab;
            icon_position = "left";
            icon_path = "/usr/share/icons/Arc";
            max_icon_size = 64;
          };

          frame = {
            width = 1;
            color = "#A6A6A6";
          };

          urgency_low = {
            background = "#000000";
            foreground = "#A6A6A6";
            timeout = 4;
          };

          urgency_normal = {
            background = "#000000";
            foreground = "#A6A6A6";
            timeout = 4;
          };

          urgency_critical = {
            background = "#900000";
            foreground = "#ffffff";
            timeout = 16;
          };
        };
      };
    };

    # manuals not needed
    manual.html.enable = false;
    manual.json.enable = false;
    manual.manpages.enable = false;
  };
}
