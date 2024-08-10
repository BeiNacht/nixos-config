{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ headscale ];

  services = {
    nginx = {
      virtualHosts = {
        "headscale.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:8088/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };

    headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8088;
      # dns = { baseDomain = "example.com"; };
      settings = {
        logtail.enabled = false;
        server_url = "https://headscale.szczepan.ski";
        ip_prefixes = [
          "100.64.0.0/10"
          "fd7a:115c:a1e0::/48"
        ];
        # later
        # prefixes = {
        #   v4 = "100.64.0.0/10";
        #   v6 = "fd7a:115c:a1e0::/48";
        # };
        dns_config = {
          override_local_dns = true;
          base_domain = "szczepan.ski";
          magic_dns = true;
          domains = [ "main.szczepan.ski" ];
          nameservers = [
            "100.64.0.2"
            "127.0.0.1"
          ];
        };
      };
    };

  };
}
