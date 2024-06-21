{ config, lib, pkgs, ... }:
{
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [
        config.services.gitea.user
      ];
      ensureUsers = [
        {
          name = config.services.gitea.database.user;
          ensureDBOwnership = true;
        }
      ];
    };

    gitea = {
      enable = true;
      appName = "My awesome Gitea server"; # Give the site a name
      database = {
        type = "postgres";
        password = "REMOVED_OLD_PASSWORD_FROM_HISTORY";
      };
      settings = {
        server = {
          DOMAIN = "git.v220240679185274666.nicesrv.de";
          ROOT_URL = "https://git.v220240679185274666.nicesrv.de/";
          HTTP_PORT = 3001;
          HTTP_ADDR = "127.0.0.1";
        };
        service.DISABLE_REGISTRATION = true;
      };
    };
  };
}
