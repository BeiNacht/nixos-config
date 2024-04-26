{ config, pkgs, lib, ... }:

{
  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];

      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;

      layout = "us";

      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };
}
