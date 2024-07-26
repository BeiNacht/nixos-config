{ config, pkgs, lib, ... }:
let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [ <home-manager/nixos> ];
  networking = {
    firewall.enable = false;
    networkmanager = { enable = true; };
  };

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    packages = with pkgs; [
      # (nerdfonts.override { fonts = [ "Liberation" ]; })
      nerdfonts
      corefonts
      google-fonts
      liberation_ttf
      libertinus
      gyre-fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      noto-fonts-extra

      open-sans
      stix-two
      twemoji-color-font
    ];

    # fontconfig = {
    #   enable = true;
    #   antialias = true;
    #   defaultFonts = {
    #     # monospace = [ "Fira Mono" ];
    #     serif = [ "Linux Libertine" ];
    #     sansSerif = [ "Open Sans" ];
    #     emoji = [ "Twitter Color Emoji" ];
    #   };
    # };
  };

  hardware = {
    bluetooth.enable = true;
    sane.enable = true;
  };

  services = {
    gvfs.enable = true;
    # mullvad-vpn.enable = true;

    # etesync-dav = {
    #   enable = true;
    #   apiUrl = "https://etesync.szczepan.ski/";
    # };
  };

  programs = {
    adb.enable = true;
    ssh = { startAgent = true; };
    # dconf.enable = true;
    # gnupg.agent = {
    #   enable = true;
    #   pinentryFlavor = "curses";
    #   # enableSSHSupport = true;
    # };
  };

  environment.systemPackages = with unstable.pkgs; [
    alacritty
    baobab
    czkawka # fslint before
    # discord
    # espeak-ng
    gparted
    grsync
    handbrake
    insomnia
    keepassxc
    meld
    nextcloud-client
    pinta
    # remmina
    rustdesk-flutter
    simple-scan
    # signal-desktop
    # solaar
    # spotify
    virt-manager
  ];

  home-manager.users.alex = { pkgs, ... }: {
    # services = { syncthing = { enable = true; }; };
    programs = {
      vscode = {
        enable = true;
        package = unstable.pkgs.vscode;
      };

      mpv = {
        enable = true;
        config = {
          hwdec = "auto-safe";
          vo = "gpu";
          profile = "gpu-hq";
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
  };
}
