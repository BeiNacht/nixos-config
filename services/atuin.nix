{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    nginx = {
      virtualHosts = {
        "atuin.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {proxyPass = "http://127.0.0.1:8888/";};
          };
        };
      };
    };

    atuin = {
      enable = true;
      openRegistration = true;
    };
  };
}
