{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/nextcloud"
        "/var/lib/postgresql"
        "/var/lib/redis-nextcloud"
      ];
    };
  };

  users = {
    users.postgres = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
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
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = [
        config.services.nextcloud.config.dbname
      ];
      ensureUsers = [
        {
          name = config.services.nextcloud.config.dbuser;
          ensureDBOwnership = true;
          # ensurePermissions."DATABASE ${config.services.gitea.database.name}" = "ALL PRIVILEGES";
        }
      ];
    };

    nextcloud = {
      enable = true;
      hostName = "nextcloud.szczepan.ski";

      # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud31;

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
          bookmarks
          calendar
          contacts
          deck
          end_to_end_encryption
          mail
          
          memories
          music
          notes
          notify_push
          onlyoffice
          phonetrack
          previewgenerator
          tasks
          unroundedcorners
          ;
        # maps
        # user_migration = pkgs.fetchNextcloudApp {
        #   sha256 = "sha256-OwALAM/WPJ4gXHQado0njfJL+ciDsvfbPjqGWk23Pm8=";
        #   url = "https://github.com/nextcloud-releases/user_migration/releases/download/v6.0.0/user_migration-v6.0.0.tar.gz";
        #   license = "agpl3Plus";
        # };
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
        "overwrite.cli.url" = "${config.services.nextcloud.hostName}";
        "maintenance_window_start" = "1";
      };

      config = {
        dbtype = "pgsql";
        adminuser = "alex";
        adminpassFile = config.sops.secrets.nextcloud-password.path;
      };
    };
  };

  systemd.services.nextcloud-cron = {
    path = [pkgs.perl];
  };
}
