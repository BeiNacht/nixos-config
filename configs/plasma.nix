{ config, pkgs, lib, ... }:

{
  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.kalk
    libsForQt5.plasma-browser-integration
  ];

  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    # plasma-browser-integration
    konsole
    oxygen
  ];

  environment.etc."chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

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
