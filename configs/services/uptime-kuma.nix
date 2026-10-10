{
  config,
  lib,
  pkgs,
  ...
}: let
  vhosts = import ../nginx-vhosts.nix;
in {
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
        "uptime.szczepan.ski" = vhosts.proxy "http://127.0.0.1:4000/";
      };
    };
  };
}
