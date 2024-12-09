{
  config,
  pkgs,
  lib,
  ...
}: let
  dns-domain = "dns.szczepan.ski";
in {
  security.acme.certs.${dns-domain}.postRun = ''
    cp fullchain.pem /var/lib/AdGuardHome/chain.pem \
      && cp key.pem /var/lib/AdGuardHome/key.pem \
      && chown adguardhome:adguardhome /var/lib/AdGuardHome/chain.pem \
      && chown adguardhome:adguardhome /var/lib/AdGuardHome/key.pem
  '';

  services = {
    nginx = {
      virtualHosts = {
        ${dns-domain} = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {proxyPass = "https://127.0.0.1:3004/";};
          };
        };
      };
    };

    adguardhome = {
      enable = true;
      mutableSettings = true;
      host = "127.0.0.1";
      port = 3002;
      settings = {
        users = [
          {
            name = "alex";
            password = "$2y$10$UhKvi4oztTfULWlIKnQhveORKXpIKCqpawJ/skSBAH96Njn4YDhTC";
          }
        ];
        dns = {
          bind_hots = [
            "0.0.0.0"
          ];
          port = 53;
          upstream_dns = [
            "https://dns.quad9.net/dns-query"
            "sdns://AgcAAAAAAAAADTk0LjE0MC4xNC4xNDAgmjo09yfeubylEAPZzpw5-PJ92cUkKQHCurGkTmNaAhkNOTQuMTQwLjE0LjE0MAovZG5zLXF1ZXJ5"
            "tls://one.one.one.one"
            "tls://dns.google"
          ];
          cache_size = 4194304;
          cache_ttl_min = 2400;
          cache_ttl_max = 84600;
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;

          parental_enabled = false; # Parental control-based DNS requests filtering.
          safe_search = {
            enabled = false; # Enforcing "Safe search" option for search engines, when possible.
          };
        };
        statistics = {
          enabled = true;
        };
        tls = {
          server_name = dns-domain;
          enabled = true;
          allow_unencrypted_doh = false;
          port_dns_over_tls = 853;
          port_dns_over_quic = 0;
          port_https = 3004;
          certificate_chain = "";
          private_key = "";
          certificate_path = "/var/lib/AdGuardHome/chain.pem";
          private_key_path = "/var/lib/AdGuardHome/key.pem";
        };
        # The following notation uses map
        # to not have to manually create {enabled = true; url = "";} for every filter
        # This is,qq however, fully optional
        filters =
          map (url: {
            enabled = true;
            url = url;
          }) [
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
          ];
      };
    };
  };
}
