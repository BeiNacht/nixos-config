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
      xkb.layout = "us";

      updateDbusEnvironment = true;
    };

    # Enable touchpad support.
    libinput.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # blackbox-terminal
    gnome.gnome-power-manager
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    gnomeExtensions.dash-to-dock
    gnomeExtensions.caffeine
    gnomeExtensions.user-themes

    pantheon.elementary-icon-theme

    # flat-remix-icon-theme
    # flat-remix-gtk
    # flat-remix-gnome
    # juno-theme

    trayscale
  ];

  environment.gnome.excludePackages = (with pkgs; [ gnome-tour gedit ])
    ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
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
