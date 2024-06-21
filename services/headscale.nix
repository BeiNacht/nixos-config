{ config, lib, pkgs, ... }:
{
  services = {
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
        ];
        dns_config = {
          base_domain = "szczepan.ski";
          magic_dns = true;
          domains = [ "headscale.szczepan.ski" ];
          nameservers = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };
      };
    };

  };
}
