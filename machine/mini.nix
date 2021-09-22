{ config, pkgs, ... }:

{
  imports =
    [
      <nixos-hardware/common/cpu/intel>
      /etc/nixos/hardware-configuration.nix
      ../configs/docker.nix
      ../configs/common.nix
      ../configs/user.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModulePackages = with pkgs.linuxPackages; [ rtl88x2bu ];


  networking = {
    hostName = "mini";
    useDHCP = false;
    # interfaces.enp3s0.useDHCP = true;
    firewall = {
      enable = false;
      # allowedTCPPorts = [ 6443 ];
    };
    networkmanager.enable = true;
  };
  services.k3s.enable = true;
  services.k3s.role = "server";

  system.stateVersion = "21.05";
}
