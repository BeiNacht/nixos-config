{ pkgs, ... }:

{

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  environment.systemPackages = with pkgs; [
    signal-desktop
    chromium
    gparted
    keepassxc
    meld
    # twemoji-color-font
    mpv
    brave
    firefox
    baobab
    lutris
    insomnia
    jellyfin-mpv-shim
    kdenlive
    nextcloud-client
    barrier
    solaar
    spotify
    vulkan-tools
    gnome.eog
    virtmanager
    prusa-slicer
    cura
    fslint
    transmission-gtk
    bitwarden
    gnome.gnome-tweaks
    juno-theme
    elementary-xfce-icon-theme
    libreoffice
    etcher
    mangohud
    minecraft
    jellyfin-mpv-shim
    jellyfin-media-player
    teams
  ];

  programs.steam.enable = true;

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

  programs.dconf.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.brlaser ];

  nixpkgs.config.chromium.commandLineArgs = "--enable-features=WebUIDarkMode,NativeNotifications,VaapiVideoDecoder --ignore-gpu-blocklist --use-gl=desktop --force-dark-mode --disk-cache-dir=/tmp/cache";
  programs.chromium = {
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
}
