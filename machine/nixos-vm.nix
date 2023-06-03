{ config, pkgs, lib, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [
    /etc/nixos/hardware-configuration.nix
    # ../configs/pantheon.nix
    ../configs/common.nix
    ../configs/user.nix
    ../configs/docker.nix
    #      ../configs/user-gui.nix
  ];

  networking.hostName = "nixos-vm"; # Define your hostname.
  time.timeZone = "Europe/Berlin";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s1.useDHCP = true;

  services = {
    # k3s = {
    #   enable = true;
    #   role = "server";
    # };
#    qemuGuest.enable = true;
#    spice-vdagentd.enable = true;
    # etesync-dav = {
    #   enable = true;
    #   apiUrl = "https://etesync.szczepan.ski/";
    # };

#    xserver = {
#      enable = false;
#      displayManager = {
#        gdm = {
#          enable = true;
          # greeters.pantheon.enable = true;
        };
#      };

#      desktopManager.gnome.enable = true;
#      layout = "us";

      # Enable touchpad support.
#      libinput.enable = true;
#      updateDbusEnvironment = true;
#    };
#  };

#  programs.evolution.enable = true;

#  environment.gnome.excludePackages = (with pkgs; [ gnome-photos gnome-tour ])
#    ++ (with pkgs.gnome; [
#      cheese # webcam tool
#      gnome-music
#      gnome-terminal
#      gedit # text editor
#      epiphany # web browser
#      geary # email reader
#      evince # document viewer
#      gnome-characters
#      totem # video player
#      iagno # go game
#      hitori # sudoku game
#      atomix # puzzle game
#    ]);

  system.stateVersion = "23.05";
}
