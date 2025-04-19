{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/paperless"
      ];
    };
  };

  services = {
    paperless = {
      enable = true;
      address = "127.0.0.1";
      settings = {
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };

        PAPERLESS_BIND_ADDR = "127.0.0.1";
        PAPERLESS_URL = "https://paperless.szczepan.ski";
        PAPERLESS_USE_X_FORWARD_HOST = true;
        PAPERLESS_USE_X_FORWARD_PORT = true;
        # PAPERLESS_PROXY_SSL_HEADER = "'[\"HTTP_X_FORWARDED_PROTO\", \"https\"]'";
      };
    };

    nginx = {
      virtualHosts = {
        "paperless.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:28981/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };
}
