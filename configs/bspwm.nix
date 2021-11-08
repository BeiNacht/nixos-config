{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{

  services = {
    xserver = {
      enable = true;
      displayManager = {
        lightdm = {
          enable = true;
          background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
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

  home-manager.users.alex = { pkgs, ... }: {
    services = {
      # picom = {
      #   enable = true;
      #   blur = true;
      #   shadow = true;
      #   vSync = true;
      # };

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

      nextcloud-client = {
        enable = true;
        startInBackground = true;
      };

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
            window_gap = 5;
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