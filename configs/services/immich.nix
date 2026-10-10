{
  config,
  lib,
  pkgs,
  ...
}: let
  vhosts = import ../nginx-vhosts.nix;
in {
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
        "immich.szczepan.ski" = vhosts.proxy "http://[::1]:2283/";
      };
    };

    immich = {
      enable = true;
      settings.server.externalDomain = "https://immich.szczepan.ski";
    };
  };
}
