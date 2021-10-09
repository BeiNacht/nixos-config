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
  ];

  programs = {
    steam.enable = true;
    dconf.enable = true;
    adb.enable = true;
    seahorse.enable = true;
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
          # background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
          greeters.gtk.theme = {
            package = pkgs.pantheon.elementary-gtk-theme;
            name = "elementary";
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
}
