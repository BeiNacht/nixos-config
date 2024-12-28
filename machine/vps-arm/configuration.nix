{
  config,
  lib,
  pkgs,
  outputs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/user.nix
    ../../configs/borg.nix

    ../../configs/services/adguardhome.nix
    ../../configs/services/atuin.nix
    ../../configs/services/firefox-syncserver.nix
    ../../configs/services/frigate.nix
    ../../configs/services/gitea.nix
    ../../configs/services/goaccess.nix
    ../../configs/services/grafana.nix
    ../../configs/services/headscale.nix
    ../../configs/services/immich.nix
    ../../configs/services/nextcloud.nix
    ../../configs/services/uptime-kuma.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets-vps-arm.yaml;
    secrets = {
      borg-key = {
        owner = config.users.users.alex.name;
        group = config.users.users.alex.group;
      };

      goaccess-htpasswd = {
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
        mode = "0440";
      };

      frigate-htpasswd = {
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
        mode = "0440";
      };

      syncserver-secrets = {
        owner = config.users.users.firefox-syncserver.name;
      };

      nextcloud-password = {
        owner = "nextcloud";
        group = "nextcloud";
      };

      gitea-password = {
        owner = config.services.gitea.user;
        group = config.services.gitea.group;
        mode = "0440";
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

        postCommands = let
          torRc = pkgs.writeText "tor.rc" ''
            DataDirectory /etc/tor
            SOCKSPort 127.0.0.1:9050 IsolateDestAddr
            SOCKSPort 127.0.0.1:9063
            HiddenServiceDir /etc/tor/onion/bootup
            HiddenServicePort 22 127.0.0.1:22
          '';
        in ''
          echo "tor: preparing onion folder"
          # have to do this otherwise tor does not want to start
          chmod -R 700 /etc/tor

          echo "make sure localhost is up"
          ip a a 127.0.0.1/8 dev lo
          ip link set lo up

          echo "tor: starting tor"
          tor -f ${torRc} --verify-config
          tor -f ${torRc} &
        '';
      };

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/cad303e1-16d8-4c15-b6c6-1f5bfc498419";
          preLVM = true;
        };
      };

      secrets = {
        "/etc/tor/onion/bootup" = /home/alex/tor/onion; # maybe find a better spot to store this.
      };

      extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.tor}/bin/tor
      '';
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
          address = "2a0a:4cc0:c0:30aa::1";
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
      xd
      nyx
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/acme"
        "/var/lib/fail2ban"
        "/var/lib/private"
        "/var/www/alexander.szczepan.ski"
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

    borgbackup.jobs.all = rec {
      repo = "ssh://u278697-sub3@u278697.your-storagebox.de:23/./borg";
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
        "/persist/borg"
      ];
    };

    journald = {extraConfig = "SystemMaxUse=10G";};
  };

  system.stateVersion = "24.11";
}
