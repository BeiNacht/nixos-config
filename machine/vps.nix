{ config, lib, pkgs, ... }:
let
  secrets-desktop = import ../configs/secrets-desktop.nix;
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
in
{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ../configs/common.nix
      ../configs/docker.nix
      ../configs/user.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking.hostName = "vps"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  networking = {
    useDHCP = false;
#    defaultGateway = {
#     "address" = "gw.contabo.net";
#     "interface" = "ens18";
#    };
    interfaces.ens18 = {
      useDHCP = true;
#      ipv4.addresses = [ {
#        address = "207.180.220.97";
#        prefixLength = 24;
#      } ];
      ipv6.addresses = [ {
        address = "2a02:c207:3008:1547::1";
        prefixLength = 64;
      } ];
    };
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
        peers = [{
          publicKey = secrets.wireguard-desktop-public;
          presharedKey = secrets.wireguard-preshared;
          allowedIPs = [ "10.100.0.2/32" ];
        }
          {
            publicKey = secrets.wireguard-mini-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.3/32" ];
          }];
      };
    };

    nat = {
      enable = true;
      externalInterface = "ens18";
      internalInterfaces = [ "wg0" ];
    };
    firewall = {
      allowedTCPPorts = [ 80 443 22000 ];
      allowedUDPPorts = [ 80 443 51820 ];
      interfaces.wg0 = {
        allowedTCPPorts = [ 61208 19999 ];
      };
      # extraCommands = ''
      #   iptables -A nixos-fw -p tcp --source 10.100.0.0/24 --dport 19999:19999 -j nixos-fw-accept
      # '';
    };
  };

  programs.mtr.enable = true;

  security.acme.email = "webmaster@szczepan.ski";
  security.acme.acceptTerms = true;

  services = {
    fail2ban = {
      enable = true;

      jails.DEFAULT =
        ''
          bantime  = 7d
        '';

      jails.sshd =
        ''
          filter = sshd
          maxretry = 4
          action   = iptables[name=ssh, port=ssh, protocol=tcp]
          enabled  = true
        '';
    };
    netdata.enable = true;
    syncthing = {
      user = "alex";
      group = "users";
      enable = true;
      dataDir = "/home/alex";
      configDir = "/home/alex/.config/syncthing";
    };

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2" ;
        passphrase = secrets-desktop.borg-key;
      };
      extraCreateArgs = "--list --stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_rsa";
      paths = "/home/alex";
      repo = "ssh://u278697-sub3@u278697.your-storagebox.de:23/./borg";
      startAt = "daily";
      # user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) be.borg-exclude;
    };
  };

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  system.stateVersion = "21.05";
}
