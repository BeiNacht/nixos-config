{ config, pkgs, lib, ... }: {
  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    oxygen
    kate
  ];

  services = {
    desktopManager.plasma6.enable = true;
    displayManager = {
      defaultSession = "plasmax11";
      sddm = {
        enable = true;
        # wayland.enable = true;
      };
    };

    xserver = {

      enable = true;
      excludePackages = [ pkgs.xterm ];

      xkb.layout = "us";

      # Enable touchpad support.
      updateDbusEnvironment = true;
    };

    libinput.enable = true;
  };
}
