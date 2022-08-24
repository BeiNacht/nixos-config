{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
  be = import ../configs/borg-exclude.nix;
in {
  imports = [
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

  fileSystems."/export/docker" = {
    device = "/home/alex/docker";
    options = [ "bind" ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  networking = {
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
            allowedIPs = [ "10.100.0.3/32" ];
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
      allowedTCPPorts = [ 80 443 22000 ];
      allowedUDPPorts = [ 80 443 51820 ];
      interfaces.wg0 = { allowedTCPPorts = [ 61208 19999 2049 ]; };
      # extraCommands = ''
      #   iptables -A nixos-fw -p tcp --source 10.100.0.0/24 --dport 19999:19999 -j nixos-fw-accept
      # '';
    };
  };

  environment.systemPackages = with pkgs; [ goaccess ];

  programs.mtr.enable = true;
  programs.fuse.userAllowOther = true;

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
              proxyPass = "http://10.100.0.6:8123/";
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

    samba = {
      enable = false;
      openFirewall = true;

      # This adds to the [global] section:
      extraConfig = ''
        browseable = yes
        smb encrypt = required
      '';

      shares = {
        homes = {
          browseable =
            "no"; # note: each home will be browseable; the "homes" share will not.
          "read only" = "no";
          "guest ok" = "no";
        };
      };
    };

    nfs.server = {
      enable = false;
      exports = ''
        /export         10.100.0.0/24(rw,fsid=0,no_subtree_check)
        /export/docker  10.100.0.0/24(rw,nohide,insecure,no_subtree_check)
      '';
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
        "--list --stats --verbose --checkpoint-interval 600 --exclude-caches";
      environment.BORG_RSH = "ssh -i /home/alex/.ssh/id_borg_rsa";
      paths = "/home/alex";
      repo = secrets.borg-repo;
      startAt = "daily";
      # user = "alex";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      extraPruneArgs = "--save-space --list --stats";
      exclude = map (x: paths + "/" + x) be.borg-exclude;
    };
  };

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  system.stateVersion = "22.05";
}
