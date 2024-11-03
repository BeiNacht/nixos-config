{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    rustdesk-server = {
      enable = true;
      openFirewall = true;
      relayIP = "152.53.18.107";
    };
  };
}
