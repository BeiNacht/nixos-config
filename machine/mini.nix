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

  networking.hostName = "mini";
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 6443 ];
  services.k3s.enable = true;
  services.k3s.role = "server";

  networking.firewall.enable = false;

  system.stateVersion = "21.05";
}
