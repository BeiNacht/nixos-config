{ config, pkgs, ... }:

{

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    chromium.commandLineArgs = "--enable-features=WebUIDarkMode,NativeNotifications,VaapiVideoDecoder --ignore-gpu-blocklist --use-gl=desktop --force-dark-mode --disk-cache-dir=/tmp/cache";
  };

  networking = {
    firewall.enable = false;
    networkmanager = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    chromium
    fswebcam
    glxinfo
    gparted
    libsecret
    lightlocker
    networkmanager-openconnect
    openconnect
    pantheon.elementary-gtk-theme
    pantheon.elementary-icon-theme
    ponymix
    pulseaudio-ctl
    python39Packages.pyyaml

    i3pystatus (python38.withPackages(ps: with ps; [ i3pystatus keyring ]))
  ];

  programs = {
    steam.enable = true;
    dconf.enable = true;
    adb.enable = true;
    # seahorse.enable = true;
    ssh = {
      startAgent = true;
    };

    gnupg.agent = {
      enable = true;
      pinentryFlavor = "curses";
      # enableSSHSupport = true;
    };

    chromium = {
      enable = true;
      extensions = [
        "cbnipbdpgcncaghphljjicfgmkonflee" # Axel Springer Blocker
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube
        "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
        "fploionmjgeclbkemipmkogoaohcdbig" # Page load time
        "egnjhciaieeiiohknchakcodbpgjnchh" # Tab Wrangler
        "fnaicdffflnofjppbagibeoednhnbjhg" # Floccus bookmarks
        "mmpokgfcmbkfdeibafoafkiijdbfblfg" # Merge Windows
        "gppongmhjkpfnbhagpmjfkannfbllamg" # Wappalyzer
        "nljkibfhlpcnanjgbnlnbjecgicbjkge" # DownThemAll!
        "lckanjgmijmafbedllaakclkaicjfmnk" # Clearurls
        "njdfdhgcmkocbgbhcioffdbicglldapd" # LocalCDN
        "jinjaccalgkegednnccohejagnlnfdag" # Violentmonkey
      ];
      extraOpts = {
        "BrowserSignin" = 0;
        "SyncDisabled" = true;
        "PasswordManagerEnabled" = false;
        "AutofillAddressEnabled" = true;
        "AutofillCreditCardEnabled" = false;
        "BuiltInDnsClientEnabled" = false;
        "MetricsReportingEnabled" = true;
        "SearchSuggestEnabled" = false;
        "AlternateErrorPagesEnabled" = false;
        "UrlKeyedAnonymizedDataCollectionEnabled" = false;
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [
                                "de"
                                "en-US"
                              ];
        "CloudPrintSubmitEnabled" = false;
      };
    };

    # sway = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     dmenu
    #     swaylock
    #     swayidle
    #     xwayland
    #     mako
    #     kanshi
    #     grim
    #     slurp
    #     wl-clipboard
    #     wf-recorder
    #     (python38.withPackages(ps: with ps; [ i3pystatus keyring ]))
    #   ];
    #   extraSessionCommands = ''
    #     export SDL_VIDEODRIVER=wayland
    #     export QT_QPA_PLATFORM=wayland
    #     export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    #     export _JAVA_AWT_WM_NONREPARENTING=1
    #     export MOZ_ENABLE_WAYLAND=1
    #   '';
    # };
  };

  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;

    fonts = with pkgs; [
      corefonts
      font-awesome
      google-fonts
      liberation_ttf
      meslo-lg
      nerdfonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      open-sans
      stix-two
      twemoji-color-font
    ];

    fontconfig = {
      enable = true;
      antialias = true;
      defaultFonts = {
        # monospace = [ "Fira Mono" ];
        serif = [ "Linux Libertine" ];
        sansSerif = [ "Open Sans" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };

  hardware.bluetooth.enable = true;

  # systemd.user.targets.sway-session = {
  #   description = "Sway compositor session";
  #   documentation = [ "man:systemd.special(7)" ];
  #   bindsTo = [ "graphical-session.target" ];
  #   wants = [ "graphical-session-pre.target" ];
  #   after = [ "graphical-session-pre.target" ];
  # };

  # systemd.user.services.kanshi = {
  #   description = "Kanshi output autoconfig ";
  #   wantedBy = [ "graphical-session.target" ];
  #   partOf = [ "graphical-session.target" ];
  #   environment = { XDG_CONFIG_HOME="/home/alex/.config"; };
  #   serviceConfig = {
  #     # kanshi doesn't have an option to specifiy config file yet, so it looks
  #     # at .config/kanshi/config
  #     ExecStart = ''
  #     ${pkgs.kanshi}/bin/kanshi
  #     '';
  #     RestartSec = 5;
  #     Restart = "always";
  #   };
  # };

  services = {
    blueman.enable = true;
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };
    xserver = {
      enable = true;

      # displayManager.defaultSession = "sway";
      # displayManager.sddm.enable = true;

      # displayManager = {
      #   lightdm = {
      #     enable = true;
      #     background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
      #     # greeters.gtk.theme = {
      #     #   package = pkgs.pantheon.elementary-gtk-theme;
      #     #   name = "elementary";
      #     # };
      #     greeters.pantheon.enable = true;
      #   };
      #   defaultSession = "xsession";
      #   session = [{
      #      manage = "desktop";
      #      name = "xsession";
      #      start = ''exec $HOME/.xsession'';
      #   }];
      # };


      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      # desktopManager = {
      #   xfce = {
      #     enable = true;
      #     noDesktop = true;
      #     enableXfwm = true;
      #     thunarPlugins = [ pkgs.xfce.thunar-archive-plugin ];
      #   };
      # };
      layout = "us";
      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };
}
