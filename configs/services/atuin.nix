{
  config,
  lib,
  pkgs,
  ...
}: let
  vhosts = import ../nginx-vhosts.nix;
in {
  services = {
    nginx = {
      virtualHosts = {
        "atuin.szczepan.ski" = vhosts.proxy "http://127.0.0.1:8888/";
      };
    };

    atuin = {
      enable = true;
      openRegistration = true;
    };
  };
}
