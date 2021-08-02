{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pantheon.elementary-gtk-theme
    pantheon.elementary-icon-theme
    sxhkd
    bspwm
    polybar
    lightlocker
    dunst
    libnotify
    mojave-gtk-theme
    font-manager
    pulseaudio-ctl
  ];

  environment.etc."polybar.conf" = {
    text = ''
      [colors]
      foreground = #666
      foreground-alt = #FFF
      background = #000
      background-alt = #ABC
      accent = #333
      info = #689eca
      warn = #d08292

      [bar/default]
      monitor = ''${env:MONITOR:VGA-1}
      width = 100%
      height = 32
      offset-x = 0
      offset-y = 0
      ;radius = 8.0
      fixed-center = true
      ; Put the bar at the bottom of the screen
      ;bottom = true

      background = ''${colors.background}
      foreground = ''${colors.foreground}

      border-size = 1
      border-color = ''${colors.background-alt}

      padding-left = 3
      padding-right = 1

      module-margin-left = 0
      module-margin-right = 1

      font-0 = Liberation Sans Regular:size=16;4
      font-1 = Font Awesome 5 Free Solid:size=14;3
      font-2 = Noto Emoji:size=14;4
      font-3 = DejaVu Sans:size=14;2
      font-4 = Font Awesome 5 Free Regular:size=14;3

      modules-left = xwindow
      modules-center =
      modules-right = temperature clock bspwm

      tray-position = center
      tray-padding = 2
      tray-maxsize = 24

      wm-restack = bspwm
      override-redirect = false

      scroll-up = bspwm-desknext
      scroll-down = bspwm-deskprev

      cursor-click = default
      cursor-scroll = default
      enable-ipc = true

      [module/onboard]
      type = custom/script
      exec-if = test -x /usr/bin/onboard
      exec = echo 
      click-left = onboard &
      interval = 3600
      format-foreground = ''${colors.foreground-alt}

      [module/clock]
      type = custom/script
      exec = date '+ %a %_d %b %_H:%M ' | sed 's/  / /g'
      interval = 30
      format-foreground = ''${colors.foreground}
      label-font = 1

      [module/xwindow]
      type = internal/xwindow
      label = %title:0:92:…%
      label-font = 1
      label-empty =
      label-empty-font = 3
      label-empty-foreground = ''${colors.accent}

      [module/bspwm]
      type = internal/bspwm

      format = <label-mode><label-state>
      format-foreground = ''${colors.foreground}

      label-focused = " "
      label-focused-foreground = ''${colors.accent}
      label-focused-padding = 0
      label-focused-font = 2

      label-occupied = " "
      label-occupied-padding = 0
      label-occupied-foreground = ''${colors.foreground-alt}
      label-occupied-font = 5

      label-urgent = " "
      label-urgent-foreground = ''${colors.info}
      label-urgent-padding = 0
      label-urgent-font = 2

      label-empty = " "
      label-empty-foreground = ''${colors.background-alt}
      label-empty-padding = 0
      label-empty-font = 5

      label-dimmed-focused = " "
      label-dimmed-focused-foreground = ''${colors.foreground-alt}
      label-dimmed-font = 2

      label-floating = "  "
      label-pseudotiled = "  "
      label-floating-foreground = ''${colors.foreground-alt}
      label-pseudotiled-foreground = ''${colors.foreground-alt}

      [module/temperature]
      type = internal/temperature
      thermal-zone = 2
      warn-temperature = 75
      interval = 5

      format =
      format-underline =
      format-warn = <ramp> <label-warn>

      label = %temperature-c%
      label-font = 1
      label-warn = %temperature-c%
      label-warn-foreground = ''${colors.warn}
      label-warn-font = 1

      ramp-0 = 
      ramp-1 = 
      ramp-2 = 
      ramp-foreground = ''${colors.warn}

      [settings]
      screenchange-reload = true
      compositing-overline = source
      compositing-underline = source
      compositing-background = source
      compositing-foreground = source
      compositing-border = source

      [global/wm]
      margin-top = 0
      margin-bottom = 0
    '';
  };

  environment.etc.bspwmrc = {
    mode = "0645";
    text = ''
      #!/usr/bin/env bash
      # spread desktops
      desktops=10
      count=$(xrandr -q | grep -c ' connected')
      i=1
      for m in $(xrandr -q | grep ' connected' | awk '{print $1}'); do
        sequence=$(seq -s ' ' $(((1+(i-1)*desktops/count))) $((i*desktops/count)))
        bspc monitor "$m" -d $(echo ''${sequence//10/0})
        i=$((i+1))
      done
      # if [ -e "/etc/X11/Xresources" ]; then
      #   xrdb /etc/X11/Xresources
      # fi
      # if [ -e "$HOME/.Xresources" ]; then
      #   xrdb -merge "$HOME/.Xresources"
      # fi
      # # polybar
      # for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
      #   MONITOR=$m ${pkgs.polybar}/bin/polybar --reload default -c /etc/polybar.conf &
      # done

      # pointer
      xsetroot -cursor_name left_ptr
      # turn off blanking
      # xset -dpms
      # xset s off
      # xset s noblank
      # node ~/.config/bspwm/window.js &

      bspc config border_width              4
      bspc config window_gap                5
      bspc config top_padding               0
      bspc config left_padding              0
      bspc config right_padding             0
      bspc config bottom_padding            0
      bspc config split_ratio               0.50
      bspc config borderless_monocle        true
      bspc config single_monocle            true
      bspc config gapless_monocle           true
      bspc config focus_follows_pointer     true
      bspc config pointer_follows_monitor   true
      bspc config pointer_follows_focus     false
      bspc config center_pseudo_tiled       true
      bspc config automatic_scheme 	      alternate
      bspc config remove_unplugged_monitors true
      bspc config remove_disabled_monitors  true

      bspc rule -a Gnome-calculator state=floating

      bspc config normal_border_color     "#333333"
      bspc config focused_border_color    "#666666"
      bspc config presel_feedback_color   "#000000"

      bspc wm --adopt-orphans
    '';
  };

  environment.etc.sxhkdrc = {
    text = ''
      #show time
      super + z
          notify-send Time $(date '+%H:%M')
      #show Battery
      super + x
          notify-send Battery $(cat /sys/class/power_supply/BAT0/capacity)%
      alt + Tab
          rofi -show window
      #Mute
      XF86AudioMute
          pulseaudio-ctl mute
      XF86AudioLowerVolume
          pulseaudio-ctl down
      XF86AudioRaiseVolume
          pulseaudio-ctl up
      #XF86MonBrightnessUp
      #    lux -a 20%
      #XF86MonBrightnessDown
      #    lux -s 20%
      super + Return
          kitty
      super + shift + Return
          rofi -show drun
      super + Escape
          pkill -USR1 -x sxhkd
      #cycle windows
      super {_,shift + }Tab
          bspc node -f {next,prev}
      super + shift + c
          bspc node -c
      super + a
          bspc node @/ --flip vertical
      super + d
          layer=normal; \
          bspc query -N -n "focused.$\{layer\}" && layer=below; \
          bspc node -l "$layer"
      super + {s,f,k}
          state={floating,fullscreen,pseudo_tiled}; \
          bspc query -N -n "focused.$\{state\}" && state=tiled; \
          bspc node -t "$state"
      super + alt + {Left,Down,Up,Right}
          bspc node -p {west,south,north,east}
      super + ctrl + {Left,Right,Up,Down}
          xdo move {-x -50,-x +50,-y -50,-y +50}
      super + ctrl + alt + {Left,Right,Up,Down}
          xdo resize {-w -50,-w +50,-h -50,-h +50}
      super + {_,shift + }{Left,Down,Up,Right}
          bspc node -{f,s} {west,south,north,east}
      super + m
          bspc node -s biggest
      super + l
          ~/.bin/lock
      #super + y
      #    bspc node -n last.!automatic
      super + ctrl + space
          bspc node -p cancel
      super + apostrophe
          bspc node -s last
      super + ctrl + comma
          bspc node @/ --rotate 90
      super + shift + comma
          bspc node @/ --circulate forward
      #super + shift + x
      #    bspc wm -d > "$BSPWM_STATE" && bspc quit
      super + {1-9,0}
          bspc desktop -f '{1-9,0}' && notify-send `bspc query -D -d --names`
      super + shift + {1-9,0}
          bspc node -d '{1-9,0}'
    '';
  };

  services = {
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    gnome.gnome-keyring.enable = true;
    xserver = {
      enable = true;
      displayManager = {
        lightdm = {
          enable = true;
          background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
          greeters.gtk.theme = {
            package = pkgs.mojave-gtk-theme;
            name = "Mojave-dark";
          };
        };
        defaultSession = "bspwm";
        session = [{
          manage = "desktop";
          name = "bspwm";
          start = ''
            ${pkgs.sxhkd}/bin/sxhkd -c /etc/sxhkdrc &
            ${pkgs.bspwm}/bin/bspwm -c /etc/bspwmrc &
            ${pkgs.xfce.xfce4-session}/bin/xfce4-session
          '';
        }];
      };

      desktopManager = {
        xfce = {
          enable = true;
          noDesktop = true;
          enableXfwm = true;
        };
      };
      layout = "us";
      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };
}
