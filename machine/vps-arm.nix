{ config, lib, pkgs, ... }:
let
  be = import ../configs/borg-exclude.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ../configs/common.nix
      ../configs/docker.nix
      ../configs/user.nix

      ../services/adguardhome.nix
      ../services/frigate.nix
      ../services/gitea.nix
      ../services/nextcloud.nix
      ../services/rustdesk-server.nix
      ../services/uptime-kuma.nix
    ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "Europe/Berlin";

  networking = {
    hostName = "vps-arm"; # Define your hostname.
    nftables.enable = true;
    useDHCP = false;
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp7s0";
    };
    interfaces.enp7s0 = {
      useDHCP = true;
      ipv6.addresses = [{
        address = "2a0a:4cc0:1:124c::1";
        prefixLength = 64;
      }];
    };
    firewall = {
      allowPing = true;
      allowedTCPPorts = [
        80 # web
        # 222 # SSH for gitea
        443 # web
        # 9898 # i2p
      ];
      allowedUDPPorts = [
        80 # web
        443 # web
        3478 # headscale
        # 9898 # i2p
        # 51820 # wireguard
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    goaccess
    xd
    nyx
    headscale
  ];

  programs = {
    mtr.enable = true;
    fuse.userAllowOther = true;
  };

  security.acme = {
    defaults.email = "webmaster@szczepan.ski";
    acceptTerms = true;
  };

  # environment.etc."nextcloud-admin-pass".text = "PWD";

  services = {
    nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "0";

      commonHttpConfig = ''
        log_format  main  '$host $remote_addr - $remote_user [$time_local] $upstream_cache_status "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for" "$gzip_ratio" '
                          '$request_time $upstream_response_time $pipe';
        access_log  /var/log/nginx/access.log main;
      '';

      virtualHosts = {
        ${config.services.gitea.settings.server.DOMAIN} = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:3001/"; }; };
        };

        ${config.services.nextcloud.hostName} = {
          forceSSL = true;
          enableACME = true;
        };

        ${config.services.adguardhome.settings.tls.server_name} = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = { proxyPass = "https://127.0.0.1:3003/"; };
          };
        };
      };
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    fail2ban = {
      enable = true;
      bantime = "7d";

      jails = {
        sshd = {
          settings = {
            filter = "sshd";
            maxretry = 4;
            action = ''iptables[name=ssh, port=ssh, protocol=tcp]'';
            enabled = true;
          };
        };
      };
    };
  };

  system.stateVersion = "24.05";
}
