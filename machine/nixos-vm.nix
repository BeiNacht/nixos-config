{ config, pkgs, lib, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../configs/common.nix
    ../configs/user.nix
    ../configs/docker.nix
    ../configs/pantheon.nix
    ../configs/user-gui.nix
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

  hardware.parallels.enable = true;
  programs.nix-ld.enable = true;


  services = {
    k3s = {
      enable = true;
      role = "server";
    };
  };

  environment.pantheon.excludePackages = (with pkgs.pantheon; [
    elementary-calculator
    # elementary-calendar
    elementary-camera
    elementary-code
    elementary-music
    # elementary-photos
    # elementary-screenshot
    # elementary-tasks
    elementary-videos
    epiphany
  ]);


  system.stateVersion = "23.05";
}
