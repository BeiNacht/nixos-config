{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./postgres.nix
  ];

  sops = {
    secrets = {
      nextcloud-password = {
        owner = "nextcloud";
        group = "nextcloud";
      };
    };
  };

  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/nextcloud"
        "/var/lib/redis-nextcloud"
      ];
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        ${config.services.nextcloud.hostName} = {
          forceSSL = true;
          enableACME = true;
        };

        ${config.services.collabora-online.settings.server_name} = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
            proxyWebsockets = true; # collabora uses websockets
          };
        };
      };
    };

    postgresql = {
      ensureDatabases = [
        config.services.nextcloud.config.dbname
      ];
      ensureUsers = [
        {
          name = config.services.nextcloud.config.dbuser;
          ensureDBOwnership = true;
        }
      ];
    };

    nextcloud = {
      enable = true;
      hostName = "nextcloud.szczepan.ski";

      # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud33;

      # Let NixOS install and configure the database automatically.
      database.createLocally = true;

      # Let NixOS install and configure Redis caching automatically.
      configureRedis = true;

      # Increase the maximum file upload size to avoid problems uploading videos.
      maxUploadSize = "16G";
      https = true;

      autoUpdateApps = {
        enable = true; # Set what time makes sense for you
        startAt = "05:00:00";
      };

      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        # List of apps we want to install and are already packaged in
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit
          # bookmarks
          calendar
          contacts
          deck
          end_to_end_encryption
          music
          notes
          notify_push
          onlyoffice
          phonetrack
          previewgenerator
          tasks
          unroundedcorners
          richdocuments # Collabora Online for Nextcloud - https://apps.nextcloud.com/apps/richdocuments
          ;
      };

      phpOptions = {
        "opcache.interned_strings_buffer" = "64";
      };

      settings = {
        overwriteProtocol = "https";
        default_phone_region = "DE";
        log_type = "file";
        "memories.exiftool" = "${lib.getExe pkgs.exiftool}";
        "memories.vod.ffmpeg" = "${lib.getExe pkgs.ffmpeg-headless}";
        "memories.vod.ffprobe" = "${pkgs.ffmpeg-headless}/bin/ffprobe";
        "overwrite.cli.url" = "https://${config.services.nextcloud.hostName}";
        "maintenance_window_start" = "1";
      };

      config = {
        dbtype = "pgsql";
        adminuser = "alex";
        adminpassFile = config.sops.secrets.nextcloud-password.path;
      };
    };

    collabora-online = {
      enable = true;
      port = 9980; # default
      settings = {
        # Rely on reverse proxy for SSL
        ssl = {
          enable = false;
          termination = true;
        };

        # Listen on loopback interface only, and accept requests from ::1
        net = {
          listen = "loopback";
          post_allow.host = ["::1"];
        };

        # Restrict loading documents from WOPI Host nextcloud.szczepan.ski
        storage.wopi = {
          "@allow" = true;
          host = ["nextcloud.szczepan.ski"];
        };

        # Set FQDN of server
        server_name = "collabora.szczepan.ski";
      };
    };
  };

  systemd.services = {
    nextcloud-cron = {
      path = [pkgs.perl];
    };
    nextcloud-config-collabora = let
      inherit (config.services.nextcloud) occ;

      wopi_url = "http://[::1]:${toString config.services.collabora-online.port}";
      public_wopi_url = "https://collabora.szczepan.ski";
      wopi_allowlist = lib.concatStringsSep "," [
        "127.0.0.1"
        "::1"
      ];
    in {
      wantedBy = ["multi-user.target"];
      after = ["nextcloud-setup.service" "coolwsd.service"];
      requires = ["coolwsd.service"];
      script = ''
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
        ${occ}/bin/nextcloud-occ richdocuments:setup
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };

  networking.hosts = {
    "127.0.0.1" = ["nextcloud.szczepan.ski" "collabora.szczepan.ski"];
    "::1" = ["nextcloud.szczepan.ski" "collabora.szczepan.ski"];
  };
}
