{
  config,
  lib,
  pkgs,
  outputs,
  inputs,
  modulesPath,
  ...
}: let
  vhosts = import ../configs/nginx-vhosts.nix;
  shares = import ../configs/samba-shares.nix;
in {
  imports = [
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/user.nix
    ../configs/borg.nix
    ../configs/filesystem.nix
    ../configs/initrd-ssh.nix
    ../configs/samba.nix

    ../configs/services/actual.nix
    ../configs/services/adguardhome.nix
    ../configs/services/audiobookshelf.nix
    ../configs/services/gitea.nix
    ../configs/services/goaccess.nix
    ../configs/services/immich.nix
    ../configs/services/kokoro.nix
    ../configs/services/nextcloud.nix
    ../configs/services/paperless.nix
    ../configs/services/aniworld.nix
    ../configs/services/uptime-kuma.nix

    # ../configs/services/frigate.nix
    # ../configs/services/firefox-syncserver.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets-vps-arm.yaml;
    secrets = {
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

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/cad303e1-16d8-4c15-b6c6-1f5bfc498419";
          preLVM = true;
        };
      };

      secrets = {
        "/etc/tor/onion/bootup" = /home/alex/tor/onion; # maybe find a better spot to store this.
      };
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
      checkReversePath = "loose";
      trustedInterfaces = ["wg0" "tailscale0"];
      allowedTCPPorts = [
        53 # adguardhome DNS
        80 # nginx
        443 # nginx
        853 # adguardhome DoT
      ];
      allowedUDPPorts = [
        53 # adguardhome
        80 # nginx
        443 # nginx
        853 # adguardhome DoT
        51820 # wireguard
        41641 # Tailscale default
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
        "/var/lib/nginx"
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

        "vps-arm.meteor-altered.ts.net" = {
          addSSL = true;
          sslCertificate = "/var/lib/nginx/vps-arm.meteor-altered.ts.net.crt";
          sslCertificateKey = "/var/lib/nginx/vps-arm.meteor-altered.ts.net.key";
          locations."/" = {
            proxyPass = "http://127.0.0.1:3011"; # Your Docker container port
            proxyWebsockets = true;
          };
        };

        "homeassistant.szczepan.ski" = vhosts.proxy "http://homeassistant.meteor-altered.ts.net:8123/";

        # "frigate.szczepan.ski" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://homeserver.main.szczepan.ski/";
        #       proxyWebsockets = true;
        #     };
        #   };
        # };
      };
    };

    tailscale = {
      enable = true;
      # enable = lib.mkForce false;
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
      repo = "ssh://alex@mini.meteor-altered.ts.net/./homeserver/storage/samba/vps/borg";
      exclude = [
        "/home/alex/mounted"
        "/home/alex/.cache"
        "/persist/borg"
        "/persist/var/lib/postgresql"
        "/persist/var/lib/private/AdGuardHome/data/querylog.json"
        "/persist/var/lib/private/AdGuardHome/data/querylog.json.1"
      ];
    };

    journald = {settings.Journal.SystemMaxUse = "10G";};

    samba = {
      settings = {
        storage = shares.share "/home/alex/storage";
        homeassistant = shares.share "/home/alex/homeassistant";
        paperless = shares.share "/var/lib/paperless/consume";
        timemachine = shares.timeMachine "/home/alex/timemachine";
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

  systemd = {
    services = {
      tailscale-cert-fetch = {
        description = "Fetch Tailscale SSL certificates";
        after = ["network-online.target" "tailscaled.service"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.tailscale}/bin/tailscale cert --cert-file /var/lib/nginx/vps-arm.meteor-altered.ts.net.crt --key-file /var/lib/nginx/vps-arm.meteor-altered.ts.net.key vps-arm.meteor-altered.ts.net";
          # Ensure the nginx user can read the files after they are created
          ExecStartPost = "${pkgs.coreutils}/bin/chown nginx:nginx /var/lib/nginx/vps-arm.meteor-altered.ts.net.crt /var/lib/nginx/vps-arm.meteor-altered.ts.net.key";
        };
        # Run this daily to keep certs fresh
        startAt = "daily";
      };

      nginx.serviceConfig = {
        # This ensures it doesn't use a private /var/tmp that might hide things
        PrivateTmp = true;
      };
    };

    network = {
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
            # "fd7a:115c:a1e0::1/64"
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
              # "fd7a:115c:a1e0::2/128"
              "100.64.0.2/32"
              "192.168.178.0/24"
              # "fdc1:52e1:bbb4::/64"
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
  };

  system.stateVersion = "24.11";
}
