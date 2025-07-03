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
      # kdePackages.ksshaskpass
      kdePackages.breeze-gtk
      kdePackages.filelight
      kdePackages.kalk
      kdePackages.kde-gtk-config
      kdePackages.kdepim-addons
      kdePackages.plasma-disks
      kdePackages.powerdevil
      kdePackages.qtlocation
      kdePackages.qtstyleplugin-kvantum
      kdePackages.sddm-kcm
      deskflow
      hardinfo2
      kdiff3
      kdiskmark
      krusader
      ktimetracker
      maliit-keyboard
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

    libinput.enable = true;
  };

  # programs = {
  #   ssh = {
  #     startAgent = true;
  #     askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  #   };
  # };
}
