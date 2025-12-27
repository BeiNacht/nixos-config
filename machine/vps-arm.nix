{
  config,
  lib,
  pkgs,
  outputs,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/user.nix
    ../configs/borg.nix

    ../configs/services/actual.nix
    ../configs/services/adguardhome.nix
    ../configs/services/audiobookshelf.nix
    ../configs/services/atuin.nix
    ../configs/services/firefly.nix
    ../configs/services/gitea.nix
    ../configs/services/goaccess.nix
    ../configs/services/grafana.nix
    ../configs/services/headscale.nix
    ../configs/services/immich.nix
    ../configs/services/nextcloud.nix
    ../configs/services/paperless.nix
    ../configs/services/uptime-kuma.nix

    #../configs/services/frigate.nix
    # ../configs/services/firefox-syncserver.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-vps-arm.yaml;
    secrets = {
      # borg-key = {
      #   owner = config.users.users.alex.name;
      #   group = config.users.users.alex.group;
      # };

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

      # syncserver-secrets = {
      #   owner = config.users.users.firefox-syncserver.name;
      # };

      nextcloud-password = {
        owner = "nextcloud";
        group = "nextcloud";
      };

      gitea-password = {
        owner = config.services.gitea.user;
        group = config.services.gitea.group;
        mode = "0440";
      };

      wireguard-private-key = {
        owner = "systemd-network";
        group = "systemd-network";
      };

      wireguard-preshared-key = {
        owner = "systemd-network";
        group = "systemd-network";
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=root"];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=home"];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=nix"];
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=persist"];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/224bc309-572c-4771-b66e-25d5e13c4917";
      fsType = "btrfs";
      options = ["subvol=log"];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/DE94-E9C1";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/3c63b075-76ca-403f-bf75-53269b6bf4fa";}
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["ip=dhcp"];
    initrd = {
      availableKernelModules = [
        "sr_mod"
        "virtio_scsi"
        "virtio-pci"
        "xhci_pci"
      ];
      kernelModules = ["dm-snapshot"];
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
        51820 # wireguard
      ];
    };
    useNetworkd = true;
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "enp7s0";
      internalInterfaces = ["wg0"];
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
        "/var/lib/samba"
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
    dnscrypt-proxy.enable = lib.mkForce false;
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
              proxyPass = "http://homeassistant.main.szczepan.ski:8123/";
              proxyWebsockets = true;
            };
          };
        };

        "frigate.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://homeserver.main.szczepan.ski/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };

    tailscale = {
      enable = lib.mkForce false;
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
        "/persist/var/lib/private/AdGuardHome/data/querylog.json"
      ];
    };

    journald = {extraConfig = "SystemMaxUse=10G";};

    samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "server";
          "netbios name" = "server";
          "security" = "user";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          "logging" = "systemd";
          "max log size" = 50;
          "invalid users" = [
            "root"
          ];
          "passwd program" = "/run/wrappers/bin/passwd %u";
        };
        homeassistant = {
          "path" = "/home/alex/homeassistant";
          "browseable" = "yes";
          "guest ok" = "no";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        paperless = {
          "path" = "/var/lib/paperless/consume";
          "browseable" = "yes";
          "guest ok" = "no";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        timemachine = {
          "path" = "/home/alex/timemachine";
          "valid users" = "alex";
          "public" = "no";
          "writeable" = "yes";
          "force user" = "alex";
          "fruit:aapl" = "yes";
          "fruit:time machine" = "yes";
          "vfs objects" = "catia fruit streams_xattr";
        };
      };
    };

    monero = {
      enable = false;
      # limits = { threads = 4; };
      # rpc = {
      #   user = "alex";
      #   password = secrets.moneroUserPassword;
      #   #address = "10.100.0.1";
      # };
      limits = {
        download = 1048576;
        upload = 1048576;
      };
      extraConfig = ''
        enforce-dns-checkpointing=true
        enable-dns-blocklist=true # Block known-malicious nodes
        no-igd=true # Disable UPnP port mapping
        no-zmq=true # ZMQ configuration

        # bandwidth settings
        out-peers=32 # This will enable much faster sync and tx awareness; the default 8 is suboptimal nowadays
        in-peers=32 # The default is unlimited; we prefer to put a cap on this
      '';
    };
  };

  systemd.network = {
    enable = true;

    networks = {
      # "10-wan" = {
      #   matchConfig.Name = "enp1s0";
      #   networkConfig = {
      #     # start a DHCP Client for IPv4 Addressing/Routing
      #     DHCP = "ipv4";
      #     # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
      #     IPv6AcceptRA = true;
      #   };
      #   # make routing on this interface a dependency for network-online.target
      #   linkConfig.RequiredForOnline = "routable";
      # };
      "50-wg0" = {
        matchConfig.Name = "wg0";

        address = [
          # /32 and /128 specifies a single address
          # for use on this wg peer machine
          # "fd31:bf08:57cb::7/128"
          "fd7a:115c:a1e0::1/64"
          "100.64.0.1/24"
        ];

        networkConfig = {
          # do not use IPMasquerade,
          # unnecessary, causes problems with host ipv6
          IPv4Forwarding = true;
          IPv6Forwarding = true;
        };
      };
    };

    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };

      wireguardConfig = {
        ListenPort = 51820;

        # ensure file is readable by `systemd-network` user
        PrivateKeyFile = config.sops.secrets.wireguard-private-key.path;

        # To automatically create routes for everything in AllowedIPs,
        # add RouteTable=main
        RouteTable = "main";

        # FirewallMark marks all packets send and received by wg0
        # with the number 42, which can be used to define policy rules on these packets.
        FirewallMark = 42;
      };

      wireguardPeers = [
        {
          # laptop wg conf
          PublicKey = "E+79YXdARLsXJxzLFCrhkszEH63drP03lVKIjXTlRxE=";
          PresharedKeyFile = config.sops.secrets.wireguard-preshared-key.path;
          AllowedIPs = [
            "fd7a:115c:a1e0::2/128"
            "100.64.0.2/32"
            "192.168.178.0/24"
            "fdc1:52e1:bbb4::/64"
          ];
          Endpoint = "8cj4irjqnbqf3rt4.myfritz.net:55171";
          PersistentKeepalive = 25;

          # RouteTable can also be set in wireguardPeers
          # RouteTable in wireguardConfig will then be ignored.
          # RouteTable = 1000;
        }
      ];
    };
  };

  system.stateVersion = "24.11";
}
