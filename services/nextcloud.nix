{ config, lib, pkgs, ... }:
{
  services = {
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
      hostName = "nextcloud.v220240679185274666.nicesrv.de";

      # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud29;

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
          maps
          memories
          music
          notes
          notify_push
          onlyoffice
          phonetrack
          previewgenerator
          tasks
          unroundedcorners;
      };

      settings = {
        overwriteProtocol = "https";
        default_phone_region = "DE";
        log_type = "file";
      };

      config = {
        dbtype = "pgsql";
        adminuser = "alex";
        adminpassFile = "/var/nextcloud-admin-pass";
      };
    };
  };
}
