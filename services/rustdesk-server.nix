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
      signal = {
        enable = true;
        relayHosts = ["152.53.18.107"];
      };
      relay = {
        enable = true;
      };
    };
  };
}
