{ config, pkgs, lib, outputs, ... }:
{
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    ../../configs/common.nix
    ../../configs/user.nix
    ../../configs/docker.nix
    ../../configs/pantheon.nix
    ../../configs/user-gui.nix
  ];

  networking.hostName = "nixos-libvirt"; # Define your hostname.
  time.timeZone = "Europe/Berlin";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

#  boot.loader.systemd-boot.enable = true;
#  boot.loader.efi.canTouchEfiVariables = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s1.useDHCP = true;

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

  system.stateVersion = "24.05";
}
