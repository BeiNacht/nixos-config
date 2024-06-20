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
        address = "2a0a:4cc0:1:124c::";
        prefixLength = 64;
      }];
    };
    firewall = {
      allowPing = true;
      allowedTCPPorts = [
        80 # web
        222 # SSH for gitea
        443 # web
        9898 # i2p
        9899
        18080
        21114 #Rustdesk
        21115 #Rustdesk
        21116 #Rustdesk
        21117 #Rustdesk
        21118 #Rustdesk
        21119 #Rustdesk
        22000 # syncthing
      ];
      allowedUDPPorts = [
        80 # web
        443 # web
        3478 # headscale
        9898 # i2p
        21116 # Rustdesk
        51820 # wireguard
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    goaccess
    xd
    nyx
    mkp224o
    progress
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
        "git.v220240679185274666.nicesrv.de" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:3001/"; }; };
        };
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ config.services.gitea.user ];
      ensureUsers = [{
        name = config.services.gitea.database.user;
        ensureDBOwnership = true;
        # ensurePermissions."DATABASE ${config.services.gitea.database.name}" = "ALL PRIVILEGES";
      }];
    };

    gitea = {
      enable = true;
      appName = "My awesome Gitea server"; # Give the site a name
      database = {
        type = "postgres";
        password = "REMOVED_OLD_PASSWORD_FROM_HISTORY";
      };
      settings = {
        server = {
          DOMAIN = "git.v220240679185274666.nicesrv.de";
          ROOT_URL = "https://git.v220240679185274666.nicesrv.de/";
          HTTP_PORT = 3001;
        };
        service.DISABLE_REGISTRATION = true;
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
