{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    nginx = {
      virtualHosts = {
        "grafana.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          # Listening Address
          http_addr = "127.0.0.1";
          # and Port
          http_port = 3005;
          # Grafana needs to know on which domain and URL it's running
          domain = "grafana.szczepan.ski";
          # root_url = "https://grafana.szczepan.ski/"; # Not needed if it is `https://your.domain/`
          # serve_from_sub_path = true;
        };
      };
    };
  };
}
