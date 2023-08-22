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
        extraWingpanelIndicators = with pkgs; [
          monitor
          wingpanel-indicator-ayatana
        ];
      };

      layout = "us";

      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };

  systemd.user.services = {
    monitor = {
      description = "indicator-monitor";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.monitor}/bin/com.github.stsdc.monitor";
      };
    };

    indicatorapp = {
      description = "indicator-application-gtk3";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.indicator-application-gtk3}/libexec/indicator-application/indicator-application-service";
      };
    };
  };

  # App indicator
  environment.pathsToLink = [ "/libexec" ];
  environment.systemPackages = with pkgs; [
    blackbox-terminal
    cinnamon.nemo-with-extensions
    gnome-online-accounts
    gnome.gnome-control-center
    gnome.gnome-system-monitor
    indicator-application-gtk3
    monitor
    gnome.eog
  ];

  environment.pantheon.excludePackages = with pkgs.pantheon; [
    elementary-code
  ];
}
