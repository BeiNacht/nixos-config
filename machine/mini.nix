{ config, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
in
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

  time.timeZone = "Europe/Berlin";
  networking = {
    hostName = "mini";
    useDHCP = false;
    firewall = {
      enable = false;
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

  services = {
    k3s = {
      enable = true;
      role = "server";
    };

    nextdns = {
      arguments = pkgs.lib.mkForce [
        "-config"
        secrets.nextdnshash
        "-cache-size"
        "10MB"
        "-listen"
        "0.0.0.0:53"
        "-listen"
        ":::53"
        "-forwarder"
        secrets.nextdnsforwarder
        "-report-client-info"
      ];
    };
  };

  system.stateVersion = "22.05";
}
