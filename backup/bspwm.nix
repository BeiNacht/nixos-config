{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{

  services = {
    blueman.enable = true;
    accounts-daemon.enable = pkgs.lib.mkForce false;
    xserver = {
      enable = true;
      displayManager = {
        lightdm = {
          enable = true;
          background = ../wallpaper.jpg;
          greeters.gtk.theme = {
            name = "Adwaita-dark";
          };
        };
        defaultSession = "xsession";
        session = [{
          manage = "desktop";
          name = "xsession";
          start = ''exec $HOME/.xsession'';
        }];
      };

      desktopManager = {
        xfce = {
          enable = true;
          noDesktop = true;
          enableXfwm = true;
          thunarPlugins = [ pkgs.xfce.thunar-archive-plugin ];
        };
      };
      layout = "us";
      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };

  environment.systemPackages = with unstable.pkgs; [
    lightlocker
    pulseaudio-ctl
  ];

  home-manager.users.alex = { pkgs, ... }: {

    home = {
      file = {
        ".bin/rofi-default-sink.sh" = {
          executable = true;
          source = ../home/bin/rofi-default-sink.sh;
        };
      };
      packages = with unstable.pkgs; [
        arandr
        evince
        gnome.eog
        gnome.file-roller
        gnome.gnome-calculator
        keepassxc
        libnotify
        gnome.cheese
      ];
    };

    xdg.desktopEntries = {
      defaultSink = {
        name = "Default Sink";
        exec = "/home/alex/.bin/rofi-default-sink.sh";
        terminal = false;
      };
    };

    programs = {
      rofi = {
        enable = true;
        font = "Liberation Sans Regular 20";
        package = rofiPin.rofi;
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

    gtk = {
      enable = true;
      font = {
        name = "Liberation Sans Regular";
        size = 12;
      };
      gtk3 = {
        extraConfig = { gtk-application-prefer-dark-theme = 1; };
      };
      iconTheme = {
        package = pkgs.pantheon.elementary-icon-theme;
        name = "elementary";
      };
      theme = { name = "Adwaita-dark"; };
    };

    services = {
      # picom = {
      #   enable = true;
      #   blur = true;
      #   shadow = true;
      #   vSync = true;
      # };

      dunst = {
        enable = true;
        package = unstable.dunst;
        iconTheme = {
          package = pkgs.pantheon.elementary-icon-theme;
          name = "elementary";
        };
        settings = {
          global = {
            alignment = "center";
            follow = "mouse";
            font = "SF Pro Display Regular 12";
            format = "%s %p %b";
            width = "(0,300)";
            # height = 300;
            origin = "bottom-right";
            notification_limit = 5;
            offset = "4x4";
            horizontal_padding = 8;
            icon_position = "left";
            idle_threshold = 120;
            ignore_newline = "no";
            indicate_hidden = "no";
            line_height = 0;
            markup = "yes";
            max_icon_size = 64;
            monitor = 0;
            padding = 8;
            separator_color = "frame";
            separator_height = 1;
            show_age_threshold = 60;
            show_indicators = "no";
            shrink = "yes";
            sort = "yes";
            stack_duplicates = "no";
            startup_notification = true;
            sticky_history = "yes";
            transparency = 0;
            word_wrap = "yes";
            frame_width = 2;
            frame_color = "#A6A6A6";
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

      sxhkd = {
        enable = true;
        keybindings = {
          "super + x" = "notify-send Time $(date '+%H:%M')";
          "super + z" = "notify-send Battery $(cat /sys/class/power_supply/BAT0/capacity)%";
          "alt + Tab" = "rofi -show window";
          "super + Return" = "kitty";
          "super + shift + Return" = "rofi -show drun";
          "super + Escape" = "pkill -USR1 -x sxhkd";
          "super {_,shift + }Tab" = "bspc node -f {next,prev}";
          "super + shift + c" = "bspc node -c";
          "super + a" = "bspc node @/ --flip vertical";
          "super + d" = ''layer=normal; \
            bspc query -N -n "focused.$\{layer\}" && layer=below; \
            bspc node -l "$layer"'';
          "super + {s,f,k}" =
            ''state={floating,fullscreen,pseudo_tiled}; \
            bspc query -N -n "focused.$\{state\}" && state=tiled; \
            bspc node -t "$state" '';
          "super + alt + {Left,Down,Up,Right}" = "bspc node -p {west,south,north,east}";
          "super + ctrl + {Left,Right,Up,Down}" = "xdo move {-x -50,-x +50,-y -50,-y +50}";
          "super + ctrl + alt + {Left,Right,Up,Down}" = "xdo resize {-w -50,-w +50,-h -50,-h +50}";
          "super + {_,shift + }{Left,Down,Up,Right}" = "bspc node -{f,s} {west,south,north,east}";
          "super + m" = "bspc node -s biggest";
          "super + l" = "~/.bin/lock";
          "super + ctrl + space" = "bspc node -p cancel";
          "super + apostrophe" = "bspc node -s last";
          "super + ctrl + comma" = "bspc node @/ --rotate 90";
          "super + shift + comma" = "bspc node @/ --circulate forward";
          "super + {1-9,0}" = "bspc desktop -f '{I,II,III,IV,V,VI,VII,VIII,IX,X}' && notify-send `bspc query -D -d --names`";
          "super + shift + {1-9,0}" = "bspc node -d '{I,II,III,IV,V,VI,VII,VIII,IX,X}'";
          # "XF86AudioMute" = "pulseaudio-ctl mute";
          # "XF86AudioLowerVolume" = "pulseaudio-ctl down";
          # "XF86AudioRaiseVolume" = "pulseaudio-ctl up";
          "Print" = "flameshot gui";
          "super + v" = "bspc node -g hidden";
          "super + shift + v" = "bspc node {,$(bspc query -N -n .hidden |tail -n 1)} -g hidden=off -d $(bspc query -D -d focused --names) -t floating -f";
        };
      };

      # nextcloud-client = {
      #   enable = true;
      #   startInBackground = true;
      # };

      # polybar = {
      #   enable = true;
      #   script = "polybar bar &";
      #   settings = {
      #     "bar/top" = {
      #       monitor = "\${env:MONITOR:DisplayPort-1}";
      #       width = "100%";
      #       height = "3%";
      #       radius = 0;
      #       modules-center = "date";
      #     };

      #     "module/date" = {
      #       type = "internal/date";
      #       internal = 5;
      #       date = "%d.%m.%y";
      #       time = "%H:%M";
      #       label = "%time%  %date%";
      #     };
      #   };
      # };

      redshift = {
        enable = true;
        duskTime = "21:00-22:00";
        dawnTime = "06:30-07:00";
        package = pkgs.redshift;
      };

      flameshot.enable = true;
    };

    xsession = {
      enable = true;
      pointerCursor = {
        defaultCursor = "left_ptr";
        name = "elementary";
        package = pkgs.pantheon.elementary-icon-theme;
      };
      windowManager = {
        command = pkgs.lib.mkForce ''
          ${pkgs.bspwm}/bin/bspwm -c ~/.config/bspwm/bspwmrc &
          ${pkgs.xfce.xfce4-session}/bin/xfce4-session
        '';
        bspwm = {
          enable = true;
          extraConfig = ''
            bspc wm --adopt-orphans

            node /home/alex/Sync/windows.js
            bspc subscribe monitor_add monitor_remove| while read -r a event; do
              node /home/alex/Sync/windows.js
            done &
          '';
          settings = {
            border_width = 4;
            window_gap = 4;
            top_padding = 0;
            left_padding = 0;
            right_padding = 0;
            bottom_padding = 0;
            split_ratio = 0.50;
            borderless_monocle = true;
            single_monocle = true;
            gapless_monocle = true;
            focus_follows_pointer = true;
            pointer_follows_monitor = true;
            pointer_follows_focus = false;
            center_pseudo_tiled = true;
            automatic_scheme = "alternate";
            remove_unplugged_monitors = true;
            remove_disabled_monitors = true;
            normal_border_color = "#333333";
            focused_border_color = "#666666";
            presel_feedback_color = "#000000";
          };
        };
      };
    };
  };
}
