{ config, pkgs, ... }:
let
  unstable = import <nixos-unstable> {
    config = {
      allowUnfree = true;
    };
  };
in
{
  nixpkgs.config.allowUnfree = true;

  networking = {
    firewall.enable = false;
    networkmanager = {
      enable = true;
    };
  };

  environment.systemPackages = with unstable.pkgs; [
    glxinfo
    gparted
    libsecret
    gnome.simple-scan
  ];

  programs = {
    dconf.enable = true;
    adb.enable = true;
    ssh = {
      startAgent = true;
    };
    # gnupg.agent = {
    #   enable = true;
    #   pinentryFlavor = "curses";
    #   # enableSSHSupport = true;
    # };
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

  hardware.bluetooth.enable = true;
  hardware.sane.enable = true;

  services = {
    # mullvad-vpn.enable = true;
    gvfs.enable = true;
    # etesync-dav = {
    #   enable = true;
    #   apiUrl = "https://etesync.szczepan.ski/";
    # };
  };
}
