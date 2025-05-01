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
          locations = {
            "/" = {
              proxyPass = "http://[::1]:2283/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };

    immich = {
      enable = true;
      settings.server.externalDomain = "https://immich.szczepan.ski";
    };
  };
}
