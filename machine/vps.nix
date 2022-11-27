{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };

  configFile = pkgs.writeText "monero.conf" ''
    log-file=/dev/stdout
    data-dir=/var/lib/monero
    rpc-bind-ip=127.0.0.1
    rpc-bind-port=18081
    enforce-dns-checkpointing=true
    enable-dns-blocklist=true # Block known-malicious nodes
    no-igd=true # Disable UPnP port mapping
    no-zmq=true # ZMQ configuration

    # bandwidth settings
    out-peers=32 # This will enable much faster sync and tx awareness; the default 8 is suboptimal nowadays
    in-peers=32 # The default is unlimited; we prefer to put a cap on this
  '';
in {
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../configs/common.nix
    ../configs/docker.nix
    ../configs/user.nix
  ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda"; # or "nodev" for efi only
  };

  fileSystems."/export/docker" = {
    device = "/home/alex/docker";
    options = [ "bind" ];
  };

  time.timeZone = "Europe/Berlin";

  networking = {
    hostName = "vps"; # Define your hostname.
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
      ipv6.addresses = [{
        address = "2a02:c207:3008:1547::1";
        prefixLength = 64;
      }];
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
        peers = [
          {
            publicKey = secrets.wireguard-desktop-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.2/32" ];
          }
          {
            publicKey = secrets.wireguard-mini-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.3/32" "192.168.178.0/24" ];
          }
          {
            publicKey = secrets.wireguard-mbp-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.4/32" ];
          }
          {
            publicKey = secrets.wireguard-phone1-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.5/32" ];
          }
          {
            publicKey = secrets.wireguard-raspberrypi-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.6/32" ];
          }
        ];
      };
    };
    nat = {
      enable = true;
      externalInterface = "ens18";
      internalInterfaces = [ "wg0" ];
    };
    firewall = {
      allowPing = true;
      allowedTCPPorts = [
        80 # web
        443 # web
        9898 # i2p
        9899
        18080
        22000 # syncthing
      ];
      allowedUDPPorts = [
        80 # web
        443 # web
        9898 # i2p
        51820 # wireguard
      ];
      interfaces.wg0 = {
        allowedTCPPorts = [
          19999 # netdata
          2049
          4444 # i2p http proxy
          61208 # foo
          7070 # i2p control
          7654 # i2p torrent
        ];
      };
      # extraCommands = ''
      #   iptables -A nixos-fw -p tcp --source 10.100.0.0/24 --dport 19999:19999 -j nixos-fw-accept
      # '';
    };
  };

  environment.systemPackages = with pkgs; [ goaccess xd nyx ];

  programs = {
    mtr.enable = true;
    fuse.userAllowOther = true;
  };

  security.acme.defaults.email = "webmaster@szczepan.ski";
  security.acme.acceptTerms = true;

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
        "szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          globalRedirect = "www.linkedin.com/in/alexander-szczepanski-0254967b";
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
          locations = { "/" = { proxyPass = "http://127.0.0.1:8081/"; }; };
        };
        "etesync.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8082/"; }; };
        };
        "etesync-web.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8086/"; }; };
        };
        "etesync-notes.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8087/"; }; };
        };
        "portainer.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8083/"; }; };
        };
        # "mail.szczepan.ski" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = { "/" = { proxyPass = "http://127.0.0.1:8084/"; }; };
        # };
        # "git.szczepan.ski" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = { "/" = { proxyPass = "http://127.0.0.1:49154/"; }; };
        # };
        "jellyfin.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8085/"; }; };
        };
        # "file-manager.szczepan.ski" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = { "/" = { proxyPass = "http://127.0.0.1:8088/"; }; };
        # };
        "webdav.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8090/"; }; };
        };
        "pihole.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8091/"; }; };
        };
        "torrents.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:9091/"; }; };
        };
        "photoprism.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:2342/"; }; };
        };
        "syncthing.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          basicAuth = { alex = secrets.nginx-syncthing-password; };
          locations = {
            "/" = {
              extraConfig = ''
                proxy_set_header        Host localhost;
                proxy_set_header        X-Real-IP $remote_addr;
                proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header        X-Forwarded-Proto $scheme;

                proxy_pass              http://localhost:8384/;

                proxy_read_timeout      600s;
                proxy_send_timeout      600s;
              '';
            };
          };
        };
        "homeassistant.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://10.100.0.3:8123/";
              proxyWebsockets = true;
            };
          };
        };
        "goaccess.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          basicAuth = { alex = secrets.nginx-syncthing-password; };
          locations = {
            "/" = { root = "/var/www/goaccess"; };
            "/ws" = {
              proxyPass = "http://127.0.0.1:7890/";
              proxyWebsockets = true;
            };
          };
        };
        "vaultwarden.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:8092/";
              proxyWebsockets = true;
            };
            "/notifications/hub" = {
              proxyPass = "http://127.0.0.1:3012";
              proxyWebsockets = true;
            };
            "/notifications/hub/negotiate" = {
              proxyPass = "http://127.0.0.1:8092/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };

    webdav = {
      enable = true;
      user = "alex";
      group = "users";
      settings = {
        address = "127.0.0.1";
        port = 8090;
        scope = "/home/alex/docker/transmission-wireguard/downloads";
        modify = true;
        auth = true;
        users = [{
          username = "alex";
          password = secrets.webdav-password;
        }];
      };
    };

    nfs.server = {
      enable = false;
      exports = ''
        /export         10.100.0.0/24(rw,fsid=0,no_subtree_check)
        /export/docker  10.100.0.0/24(rw,nohide,insecure,no_subtree_check)
      '';
    };

    # vaultwarden = {
    #   enable = true;
    #   config = {
    #     domain = "https://vaultwarden.szczepan.ski";
    #     signupsAllowed = false;
    #     rocketPort = 8092;
    #     rocketAddress = "127.0.0.1";
    #     # adminToken =
    #     #   "jCehRECvxqWmXKMZx3dgtVEdJuqUxXoODEagItTPptBizG9SGQLCpTqjZoBM4ZDa";
    #     websocketEnabled = true;
    #     websocketAddress = "127.0.0.1";
    #     websocketPort = 3012;
    #   };
    # };

    # bitcoind.main = { enable = false; };
    # monero = {
    #   enable = true;
    #   # limits = { threads = 4; };
    #   rpc = {
    #     user = "alex";
    #     password = secrets.moneroUserPassword;
    #     #address = "10.100.0.1";
    #   };
    #   limits = {
    #     download = 1048576;
    #     upload = 1048576;
    #   };
    #   extraConfig = ''
    #     enforce-dns-checkpointing=true
    #     enable-dns-blocklist=true # Block known-malicious nodes
    #     no-igd=true # Disable UPnP port mapping
    #     no-zmq=true # ZMQ configuration

    #     # bandwidth settings
    #     out-peers=32 # This will enable much faster sync and tx awareness; the default 8 is suboptimal nowadays
    #     in-peers=32 # The default is unlimited; we prefer to put a cap on this
    #   '';
    # };

    i2pd = {
      enable = true;
      ifname = "ens18";
      address = "207.180.220.97";
      # TCP & UDP
      port = 9898;
      #   myEep = {
      #     enable = true;
      #     keys = "myEep-keys.dat";
      #     inPort = 80;
      #     address = "::1";
      #     destination = "::1";
      #     port = 8081;
      #     # inbound.length = 1;
      #     # outbound.length = 1;
      #   };
      # };
      # websocket = {
      #   enable = true;
      #   address = "10.100.0.1";
      # };
      proto = {
        http = {
          enable = true;
          address = "10.100.0.1";
        };

        httpProxy = {
          enable = true;
          address = "10.100.0.1";
        };

        socksProxy = {
          enable = true;
          address = "10.100.0.1";
        };

        i2cp = {
          enable = true;
          address = "10.100.0.1";
        };

        sam = { enable = true; };
      };

      enableIPv4 = true;
      enableIPv6 = true;
    };

    tor = {
      enable = true;
      # relay = {
      #   enable = true;
      #   role = "private-bridge";
      # };
      settings = {
        ORPort = 9001;
        ControlPort = 9051;
      };
    };

    fail2ban = {
      enable = true;

      jails.DEFAULT = ''
        bantime  = 7d
      '';

      jails.sshd = ''
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
      dataDir = "/home/alex/syncthing";
      configDir = "/home/alex/.config/syncthing";
    };

    borgbackup.jobs.home = rec {
      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = secrets.borg-key;
      };
      extraCreateArgs =
        "--stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_rsa";
      paths = [ "/home/alex" "/var/lib" ];
      repo = secrets.borg-repo;
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --stats";
      exclude = [
        "/home/alex/docker/jellyfin/data"
        "/home/alex/.cache"
        "/var/lib/monero"
      ];
    };
  };

  # users.users.monero = {
  #   isSystemUser = true;
  #   group = "monero";
  #   description = "Monero daemon user";
  #   home = "/var/lib/monero";
  #   createHome = true;
  # };

  # users.groups.monero = { };

  # systemd.services.monero = {
  #   description = "monero daemon";
  #   after = [ "network.target" ];
  #   wantedBy = [ "multi-user.target" ];

  #   serviceConfig = {
  #     User = "monero";
  #     Group = "monero";
  #     ExecStart =
  #       "${unstable.pkgs.monero-cli}/bin/monerod --config-file=${configFile} --non-interactive";
  #     Restart = "always";
  #     SuccessExitStatus = [ 0 1 ];
  #   };
  # };

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  system.stateVersion = "22.05";
}
