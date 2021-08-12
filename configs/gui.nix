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

  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gtk2";
  # };

  environment.systemPackages = with pkgs; [
    baobab
    barrier
    bitwarden
    blueberry
    brave
    bspwm
    chromium
    cura
    dunst
    elementary-xfce-icon-theme
    etcher
    evince
    firefox
    font-manager
    fslint
    glxinfo
    gnome.eog
    gnome.gnome-calculator
    gnome.gnome-tweaks
    gnome.seahorse
    gparted
    insomnia
    jellyfin-media-player
    jellyfin-mpv-shim
    juno-theme
    kdenlive
    keepassxc
    libnotify
    libreoffice
    lightlocker
    lutris
    mangohud
    meld
    minecraft
    mojave-gtk-theme
    mpv
    nextcloud-client
    pantheon.elementary-gtk-theme
    pantheon.elementary-icon-theme
    polybar
    prusa-slicer
    pulseaudio-ctl
    pinta
    signal-desktop
    solaar
    spotify
    sxhkd
    teams
    transmission-gtk
    virtmanager
    vulkan-tools
    openconnect
    networkmanager-openconnect
    cypress
    gnome.cheese
    megapixels
    obs-studio
    fswebcam
  ];

  programs = {
    steam.enable = true;
    dconf.enable = true;
    #ssh.startAgent = true;
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
  };

  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;

    fonts = with pkgs; [
      open-sans
      twemoji-color-font
      liberation_ttf
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      corefonts
      meslo-lg
      google-fonts
      font-awesome
      stix-two
      nerdfonts
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

  services = {
    blueman.enable = true;
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    gnome.gnome-keyring.enable = true;
    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };
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
            ${pkgs.bspwm}/bin/bspwm -c /etc/bspwmrc &
            ${pkgs.sxhkd}/bin/sxhkd -c /etc/sxhkdrc &
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
