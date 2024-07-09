{ config, pkgs, lib, ... }: {
  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # plasma-browser-integration
    konsole
    oxygen
    kate
  ];

  # environment.etc."chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  services = {
    desktopManager.plasma6.enable = true;
    displayManager = {
      defaultSession = "plasmax11";
      sddm = { enable = true; };
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

  environment.systemPackages = with pkgs; [ catppuccin-kde sweet-nova ];
}
