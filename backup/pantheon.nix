{ config, pkgs, lib, ... }:

{
  programs.pantheon-tweaks.enable = true;
  services = {
    xserver = {
      enable = true;
      displayManager = {
        lightdm = {
          enable = true;
          greeters.pantheon.enable = true;
        };
      };

      desktopManager.pantheon.enable = true;
      layout = "us";

      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };
}
