{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/firefly-iii"
      ];
    };
  };

  sops.secrets.firefly-key = {
    owner = "firefly-iii";
  };

  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [
        config.services.firefly-iii.settings.DB_DATABASE
      ];
      ensureUsers = [
        {
          name =
            config.services.firefly-iii.settings.DB_USERNAME;
          ensureDBOwnership = true;
        }
      ];
    };

    nginx = {
      virtualHosts = {
        ${config.services.firefly-iii.virtualHost} = {
          forceSSL = true;
          enableACME = true;
        };
      };
    };

    firefly-iii = {
      enable = true;
      enableNginx = true;
      virtualHost = "firefly.szczepan.ski";

      settings = {
        APP_KEY_FILE = config.sops.secrets.firefly-key.path;
        DB_CONNECTION = "pgsql";
        DB_DATABASE = "firefly-iii";
        DB_USERNAME = "firefly-iii";
        TZ = "Europe/Berlin";
        TRUSTED_PROXIES = "**";
      };
    };
  };
}
