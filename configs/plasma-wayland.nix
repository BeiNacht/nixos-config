{ config, pkgs, lib, ... }: {
  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
    partition-manager.enable = true;
      # package = pkgs.kdePackages.partitionmanager;
    # };
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      KWIN_DRM_DISABLE_TRIPLE_BUFFERING = "1";
    };
    plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      konsole
      oxygen
      kate
    ];

    systemPackages = with pkgs; [
      kdePackages.ksshaskpass
      kdePackages.kde-gtk-config
      kdePackages.breeze-gtk
      # kdePackages.partitionmanager
      kdePackages.filelight
      kdePackages.plasma-disks
      kdePackages.kalk
      krusader
      ktimetracker
      kdiff3
      kdiskmark
    ];
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    libinput.enable = true;
  };

  programs = {
    ssh = {
      startAgent = true;
      askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    };
  };
}
