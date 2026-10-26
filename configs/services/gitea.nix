{
  config,
  lib,
  pkgs,
  ...
}: let
  vhosts = import ../nginx-vhosts.nix;
in {
  imports = [
    ./postgres.nix
  ];

  sops = {
    secrets = {
      gitea-password = {
        owner = config.services.gitea.user;
        group = config.services.gitea.group;
        mode = "0440";
      };
    };
  };

  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/gitea"
      ];
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        "git.szczepan.ski" = vhosts.proxy "http://127.0.0.1:3001/";
      };
    };

    postgresql = {
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
        passwordFile = config.sops.secrets.gitea-password.path;
      };
      settings = {
        server = {
          ROOT_URL = "https://git.szczepan.ski/";
          HTTP_PORT = 3001;
          HTTP_ADDR = "127.0.0.1";
        };
        service.DISABLE_REGISTRATION = true;
      };
    };
  };
}
