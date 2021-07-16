{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    elementary-xfce-icon-theme
    gnomeExtensions.appindicator
    sxhkd
    bspwm
    polybar
    lightlocker
    dunst
  ];

  environment.etc.bspwmrc = {
    mode = "0645";
    text = ''
      #!/usr/bin/env bash
      # spread desktops
      # desktops=5
      # count=$(xrandr -q | grep -c ' connected')
      # i=1
      # for m in $(xrandr -q | grep ' connected' | awk '{print $1}'); do
      #   sequence=$(seq -s ' ' $(((1+(i-1)*desktops/count))) $((i*desktops/count)))
      #   bspc monitor "$m" -d $(echo ''${sequence//10/0})
      #   i=$((i+1))
      # done
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
      # sxhkd &
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
      super + {q,w,e,r,t,y,u,i,o,p}
          bspc desktop -f '{I,II,III,IV,V,VI,VII,VIII,IX,X}' && notify-send `bspc query -D -d --names`
      super + shift + {q,w,e,r,t,y,u,i,o,p}
          bspc node -d '{I,II,III,IV,V,VI,VII,VIII,IX,X}'
    '';
  };


  services = {
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    gnome.gnome-keyring.enable = true;
    xserver = {
      enable = true;
      displayManager = {
        # autoLogin = {
        #   enable = true;
        #   user = "starlight";
        # };
        lightdm = {
          enable = true;
          # autoLogin = {
          #   relogin = false;
          # };
        };
        # setupCommands = ''
        #   xset -dpms
        #   xset s off
        # '';
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
};
