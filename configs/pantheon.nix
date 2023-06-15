{ config, pkgs, lib, ... }:

{
  programs.pantheon-tweaks.enable = true;
  programs.evolution.enable = true;

  services = {
    xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
      displayManager = {
        lightdm = {
          enable = true;
          greeters.pantheon.enable = true;
        };
      };

      desktopManager.pantheon = {
        enable = true;
        extraWingpanelIndicators = with pkgs; [ wingpanel-indicator-ayatana ];
      };

      layout = "us";

      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };

  # App indicator
  environment.pathsToLink = [ "/libexec" ];
  environment.systemPackages = with pkgs; [ indicator-application-gtk3 ];

}
