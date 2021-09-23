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
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.3/24" ];
        privateKey = secrets.wireguard-mini-private;

        peers = [
          {
            publicKey = secrets.wireguard-vps-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.0/24" ];
            endpoint = "szczepan.ski:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };

  services.k3s.enable = true;
  services.k3s.role = "server";

  system.stateVersion = "21.05";
}
