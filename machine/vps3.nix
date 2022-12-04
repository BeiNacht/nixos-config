{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ /etc/nixos/hardware-configuration.nix ../configs/common-server.nix ];

  time.timeZone = "Europe/Berlin";

  networking = {
    hostName = "vps3"; # Define your hostname.
    useDHCP = false;
    interfaces.ens18 = { useDHCP = true; };
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.100/32" ];
        privateKey = secrets.wireguard-vps3-private;
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
    firewall = {
      allowPing = true;
      allowedTCPPorts = [
        80 # web
        443 # web
      ];
      allowedUDPPorts = [
        80 # web
        443 # web
      ];
    };
  };

  environment.systemPackages = with pkgs; [ ];

  programs = {
    mtr.enable = true;
    fuse.userAllowOther = true;
  };

  services = {
    fail2ban = {
      enable = true;

      jails.DEFAULT = ''
        bantime  = 7d
      '';

      jails.sshd = ''
        filter = sshd
        maxretry = 4
        action   = iptables[name=ssh, port=ssh, protocol=tcp]
        enabled  = true
      '';
    };
  };

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  system.stateVersion = "22.05";
}
