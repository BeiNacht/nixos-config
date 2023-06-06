{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports =
    [ /etc/nixos/hardware-configuration.nix ../configs/common-server.nix ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # or "nodev" for efi only
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
          {
            publicKey = secrets.wireguard-vps2-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.50/32" ];
          }
          {
            publicKey = secrets.wireguard-vps3-public;
            presharedKey = secrets.wireguard-preshared;
            allowedIPs = [ "10.100.0.100/32" ];
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

  environment.systemPackages = with pkgs; [ goaccess xd nyx mkp224o ];

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
          globalRedirect = "alexander.szczepan.ski";
        };
        "alexander.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/www/alexander.szczepan.ski";
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
        "jellyfin.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:8085/"; }; };
        };
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
        scope = "/home/alex/docker/";
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

    vaultwarden = {
      enable = true;
      config = {
        domain = "https://vaultwarden.szczepan.ski";
        signupsAllowed = false;
        rocketPort = 8092;
        rocketAddress = "127.0.0.1";
        # adminToken =
        #   "jCehRECvxqWmXKMZx3dgtVEdJuqUxXoODEagItTPptBizG9SGQLCpTqjZoBM4ZDa";
        websocketEnabled = true;
        websocketAddress = "127.0.0.1";
        websocketPort = 3012;
      };
    };

    i2pd = {
      enable = true;
      ifname = "ens18";
      address = "207.180.220.97";
      # TCP & UDP
      port = 9898;
      ntcp2.port = 9899;
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

      inTunnels = {
        foo = {
          enable = true;
          # keys = "foo-keys.dat";
          inPort = 80;
          address = "127.0.0.1";
          destination = "127.0.0.1";
          port = 8008;
        };
        foo2 = {
          enable = true;
          # keys = "foo-keys.dat";
          inPort = 80;
          address = "127.0.0.1";
          destination = "127.0.0.1";
          port = 8009;
        };
      };

      enableIPv4 = true;
      enableIPv6 = true;
    };

    icecast = {
      enable = true;
      hostname = "254ryojirydttsaealusydhwyjfe2rpschdaduok4czhg45of6ua.b32.i2p";
      listen = {
        port = 13337;
        address = "127.0.0.1";
      };
      admin = {
        user = "alex";
        password = "AaOnwDoZnspv8MszCpZZ1KuR9xXJWIE5";
      };
    };

    tor = {
      enable = true;
      # relay = {
      #   enable = true;
      #   role = "private-bridge";
      # };
      # settings = {
      #   ORPort = 9001;
      #   ControlPort = 9051;
      # };
      openFirewall = true;
      enableGeoIP = false;
      relay.onionServices = {
        foo = {
          version = 3;
          map = [{
            port = 80;
            target = {
              addr = "127.0.0.1";
              port = 8008;
            };
          }];
        };
        foo2 = {
          version = 3;
          map = [{
            port = 80;
            target = {
              addr = "127.0.0.1";
              port = 8009;
            };
          }];
        };
      };
      settings = {
        ClientUseIPv4 = true;
        ClientUseIPv6 = false;
        ClientPreferIPv6ORPort = false;
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
        monthly = 3;
      };
      extraPruneArgs = "--save-space --stats";
      exclude = [
        "/home/alex/docker/jellyfin/data"
        "/home/alex/.cache"
        "/var/lib/monero"
      ];
    };
  };

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  system.stateVersion = "23.05";
}
