{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    systemPackages = with pkgs; [headscale];
    persistence."/persist" = {
      directories = [
        "/var/lib/headscale"
      ];
    };
  };

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
        # ip_prefixes = [
        #   "100.64.0.0/10"
        #   "fd7a:115c:a1e0::/48"
        # ];
        # later
        prefixes = {
          v4 = "100.64.0.0/10";
          v6 = "fd7a:115c:a1e0::/48";
        };
        dns = {
          override_local_dns = true;
          base_domain = "main.szczepan.ski";
          magic_dns = true;
          search_domains = ["main.szczepan.ski"];
          nameservers.global = [
            "100.64.0.2"
            "127.0.0.1"
          ];
        };

        derp = {
          server = {
            enabled = true;
            region_id = 999;
            region_code = "headscale";
            region_name = "Headscale Embedded DERP";
            stun_listen_addr = "0.0.0.0:3478";
            ipv4 = "152.53.18.107";
            ipv6 = "2a0a:4cc0:1:124c::1";
          };
        };
      };
    };
  };
}
