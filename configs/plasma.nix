{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  nixpkgs.config.permittedInsecurePackages = [
    "deskflow-1.19.0"
  ];

  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
    evolution.enable = true;
    partition-manager.enable = true;
    kde-pim = {
      enable = true;
      kontact = true;
      kmail = true;
      merkuro = true;
    };
  };

  xdg.portal = {
    enable = true;
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      # KWIN_DRM_DISABLE_TRIPLE_BUFFERING = "1";
    };
    plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      konsole
      oxygen
      kate
    ];

    systemPackages = with pkgs; [
      inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
      kdePackages.ksshaskpass
      kdePackages.kde-gtk-config
      kdePackages.breeze-gtk
      kdePackages.qtstyleplugin-kvantum
      kdePackages.filelight
      kdePackages.plasma-disks
      kdePackages.kalk
      kdePackages.powerdevil
      kdePackages.qtlocation
      kdePackages.kdepim-addons
      krusader
      ktimetracker
      kdiff3
      kdiskmark
      maliit-keyboard
      deskflow
    ];

    persistence."/persist" = {
      directories = [
        "/var/lib/sddm"
      ];
    };
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      defaultSession = "plasma";
    };

    # xserver = {
    #   enable = true;
    #   excludePackages = [pkgs.xterm];
    #   # xkb.layout = "us";
    #   # # Enable touchpad support.
    #   # updateDbusEnvironment = true;
    # };

    libinput.enable = true;
  };

  programs = {
    ssh = {
      startAgent = true;
      askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    };
  };
}
