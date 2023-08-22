{ config, pkgs, lib, ... }:
{
  programs.evolution.enable = true;

  services = {
    xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
      displayManager = {
        gdm = {
          enable = true;
        };
      };

      desktopManager.gnome.enable = true;
      layout = "us";

      # Enable touchpad support.
      libinput.enable = true;
      updateDbusEnvironment = true;
    };
  };

  environment.systemPackages = with pkgs; [
    blackbox-terminal
    gnome.gnome-power-manager
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    whitesur-gtk-theme
    whitesur-icon-theme
    moka-icon-theme
    pantheon.elementary-icon-theme
  ];

  environment.gnome.excludePackages = (with pkgs; [ gnome-tour ])
    ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    gedit # text editor
    epiphany # web browser
    gnome-characters
    totem # video player
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # services.gpg-agent.pinentryFlavor = lib.mkDefault "gnome3";

}
