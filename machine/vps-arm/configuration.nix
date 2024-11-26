{
  config,
  lib,
  pkgs,
  outputs,
  inputs,
  ...
}: let
  secrets = import ../../configs/secrets.nix;
  be = import ../../configs/borg-exclude.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../configs/common.nix
    ../../configs/docker.nix
    ../../configs/user.nix

    ../../services/atuin.nix
    ../../services/adguardhome.nix
    ../../services/frigate.nix
    ../../services/gitea.nix
    ../../services/nextcloud.nix
    ../../services/uptime-kuma.nix
    ../../services/headscale.nix
    ../../services/goaccess.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets-vps-arm.yaml;
    secrets = {
      borg-key = {
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };

      goaccess-htpasswd = {
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
      };

      frigate-htpasswd = {
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
      };

      nextcloud-password = {
        owner = "nextcloud";
        group = "nextcloud";
      };

      gitea-password = {
        owner = config.services.gitea.user;
        group = config.services.gitea.group;
      };
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["ip=dhcp"];
    initrd = {
      availableKernelModules = ["virtio-pci"];
      systemd.users.root.shell = "/bin/cryptsetup-askpass";
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
          ];
          hostKeys = ["/persist/pre_boot_ssh_key"];
        };
      };
      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/d17f6d8b-aec8-4c48-834d-f88d6308e281";
          preLVM = true;
        };
      };
    };
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
      ipv6.addresses = [
        {
          address = "2a0a:4cc0:1:124c::1";
          prefixLength = 64;
        }
      ];
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

  environment = {
    systemPackages = with pkgs; [
      goaccess
      xd
      nyx
      headscale
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/acme"
        # "/var/lib/docker"
        "/var/lib/fail2ban"
        "/var/lib/frigate"
        "/var/lib/gitea"
        "/var/lib/headscale"
        "/var/lib/nextcloud"
        "/var/lib/postgresql"
        "/var/lib/private"
        "/var/lib/redis-nextcloud"
        "/var/www"
      ];
    };
  };

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
    qemuGuest.enable = true;

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
      extraCreateArgs = "--stats --verbose --checkpoint-interval=600 --exclude-caches";
      extraPruneArgs = [
        "--save-space"
        "--stats"
      ];
      extraCompactArgs = [
        "--cleanup-commits"
      ];
      environment = {
        BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_rsa";
        BORG_BASE_DIR = "/persist/borg";
      };
      readWritePaths = ["/persist/borg"];
      paths = ["/home/alex" "/persist"];
      repo = "ssh://u278697-sub3@u278697.your-storagebox.de:23/./borg-arm";
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
        "/persist/borg"
      ];
    };
  };

  system.stateVersion = "25.05";
}
