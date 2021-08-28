{ config, lib, pkgs, ... }:

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
  networking.useDHCP = false;
  networking.interfaces.ens3.useDHCP = true;

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

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

  system.stateVersion = "21.05";
}

