{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
in
{
  imports =
    [ # Include the results of the hardware scan.
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
    interfaces.ens3.useDHCP = true;
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
        }{
          publicKey = secrets.wireguard-mini-public;
          presharedKey = secrets.wireguard-preshared;
          allowedIPs = [ "10.100.0.3/32" ];
        }];
      };
    };

    nat = {
      enable = true;
      externalInterface = "ens3";
      internalInterfaces = [ "wg0" ];
    };
    firewall = {
      allowedTCPPorts = [ 80 443 22000 ];
      allowedUDPPorts = [ 80 443 51820 ];
    };
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
  ];

  programs.mtr.enable = true;

  security.acme.email = "webmaster@szczepan.ski";
  security.acme.acceptTerms = true;
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "0";

    virtualHosts = {
      "szczepan.ski" = {
        forceSSL = true;
        enableACME = true;
        #root = "/var/www/myhost.org";
      };
      "nextcloud.szczepan.ski" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8080/";
            extraConfig = ''
              add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
            '';
          };
          "/.well-known/carddav" = {
             return = "301 $scheme://$host/remote.php/dav";
          };
          "/.well-known/caldav" = {
             return = "301 $scheme://$host/remote.php/dav";
          };
        };
      };
      "firefly.szczepan.ski" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8081/";
          };
        };
      };
    };
  };

  services.fail2ban = {
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

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  system.stateVersion = "21.05";
}
