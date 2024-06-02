{ config, pkgs, lib, ... }:

{
  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  # environment.systemPackages = with pkgs; [
  #   libsForQt5.kalk
  #   libsForQt5.plasma-browser-integration
  # ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # plasma-browser-integration
    konsole
    oxygen
  ];

  # environment.etc."chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    # xserver = {
    #   enable = true;
    #   excludePackages = [ pkgs.xterm ];


    #   layout = "us";

    #   # Enable touchpad support.
    #   libinput.enable = true;
    #   updateDbusEnvironment = true;
    # };
  };

  environment.systemPackages = with pkgs; [
    catppuccin-kde
    sweet-nova
  ];
}
