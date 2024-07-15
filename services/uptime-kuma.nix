{ config, lib, pkgs, ... }:
{
  services = {
    uptime-kuma = {
      enable = true;
      settings = {
        PORT = "4000";
        HOST = "127.0.0.1";
      };
    };

    nginx = {
      virtualHosts = {
        "uptime.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { proxyPass = "http://127.0.0.1:4000/"; }; };
        };
      };
    };
  };
}
