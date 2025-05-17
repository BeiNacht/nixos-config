{
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/audiobookshelf"
      ];
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        "audiobookshelf.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:3006/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };

    audiobookshelf = {
      enable = true;
      port = 3006;
    };
  };
}
