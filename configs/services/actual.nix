{
  services = {
    nginx = {
      virtualHosts = {
        "actual.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "https://127.0.0.1:5006/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };
}
