{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ../configs/docker.nix
      ../configs/common.nix
      ../configs/user.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "mini";
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;

  networking.firewall.enable = false;

  system.stateVersion = "21.05";
}
