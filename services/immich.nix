{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/immich"
        "/var/lib/redis-immich"
      ];
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        "immich.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {"/" = {proxyPass = "http://[::1]:2283/";};};
        };
      };
    };

    # postgresql = {
    #   enable = true;
    #   ensureDatabases = [
    #     config.services.nextcloud.config.dbname
    #   ];
    #   ensureUsers = [
    #     {
    #       name = config.services..config.dbuser;
    #       ensureDBOwnership = true;
    #       # ensurePermissions."DATABASE ${config.services.gitea.database.name}" = "ALL PRIVILEGES";
    #     }
    #   ];
    # };

    immich = {
      enable = true;
      settings.server.externalDomain = "https://immich.szczepan.ski";
    };
  };
}
