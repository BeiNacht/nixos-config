{ config, lib, pkgs, outputs, inputs, ... }:
let
  secrets = import ../../configs/secrets.nix;
  be = import ../../configs/borg-exclude.nix;
in
{
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
    ../../configs/common.nix
    ../../configs/docker.nix
    ../../configs/user.nix

    ../../services/adguardhome.nix
    ../../services/frigate.nix
    ../../services/gitea.nix
    ../../services/nextcloud.nix
    ../../services/rustdesk-server.nix
    ../../services/uptime-kuma.nix
    ../../services/headscale.nix
    ../../services/goaccess.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets-vps-arm.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      borg-key = {
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };

      # webdav-password = {
      #   owner = config.users.users.alex.name;
      #   group = config.users.users.alex.group;
      # };

      # goaccess-password = {
      #   owner = config.users.users.alex.name;
      #   group = config.users.users.alex.group;
      # };

      frigate-password = {
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
      };

      hashedPassword = {
        neededForUsers = true;
        sopsFile = ../../secrets.yaml;
      };
    };
  };

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
        53 # adguardhome DNS
        80 # nginxs
        443 # nginx
        853 # adguardhome DoT
      ];
      allowedUDPPorts = [
        53 # adguardhome
        80 # nginx
        443 # nginx
        853 # adguardhome DoT
        3478 # headscale
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

  services = {
    dnscrypt-proxy2.enable = lib.mkForce false;

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
        "szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          globalRedirect = "alexander.szczepan.ski";
        };
        "alexander.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/www/alexander.szczepan.ski";
          locations = {
            "/" = {
              tryFiles = "$uri $uri.html $uri/ =404";
            };
          };
        };

        "homeassistant.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://mini.main.szczepan.ski:8123/";
              proxyWebsockets = true;
            };
          };
        };

      };
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      openFirewall = true;
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

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borg-key.path}";
      };
      extraCreateArgs =
        "--stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_rsa";
      paths = [ "/home/alex" "/var/lib" ];
      repo = "ssh://u278697-sub3@u278697.your-storagebox.de:23/./borg-arm";
      startAt = "daily";
      prune.keep = {
        daily = 4;
        weekly = 2;
        monthly = 2;
      };
      extraPruneArgs = "--save-space --stats";
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
      ];
    };
  };

  system.stateVersion = "24.05";
}
