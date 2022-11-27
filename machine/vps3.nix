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
    hostName = "vpse"; # Define your hostname.
    useDHCP = false;
    interfaces.ens18 = { useDHCP = true; };
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.1/24" ];
        listenPort = 51820;
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o ens3 -j MASQUERADE
        '';
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o ens3 -j MASQUERADE
        '';
        privateKey = secrets.wireguard-vps-private;
        peers = [
          {
            publicKey = secrets.wireguard-desktop-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.2/32" ];
          }
          {
            publicKey = secrets.wireguard-mini-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.3/32" "192.168.178.0/24" ];
          }
          {
            publicKey = secrets.wireguard-mbp-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.4/32" ];
          }
          {
            publicKey = secrets.wireguard-phone1-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.5/32" ];
          }
          {
            publicKey = secrets.wireguard-raspberrypi-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.6/32" ];
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
        51820 # wireguard
      ];
      # interfaces.wg0 = {
      #   allowedTCPPorts = [
      #     2049
      #     61208 # foo
      #   ];
      # };
    };
  };

  environment.systemPackages = with pkgs; [ goaccess xd nyx ];

  programs = {
    mtr.enable = true;
    fuse.userAllowOther = true;
  };

  security.acme.defaults.email = "webmaster@szczepan.ski";
  security.acme.acceptTerms = true;

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

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = secrets.borg-key;
      };
      extraCreateArgs =
        "--stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_rsa";
      paths = [ "/home/alex" "/var/lib" ];
      repo = secrets.borg-repo;
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --stats";
      exclude = [ "/home/alex/.cache" ];
    };
  };

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  system.stateVersion = "22.05";
}
