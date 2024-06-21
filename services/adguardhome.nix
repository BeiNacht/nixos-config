{ config, pkgs, lib, ... }:
{
  services = {
    adguardhome = {
      enable = true;
      # mutableSettings = true;
      host = "127.0.0.1";
      port = 3002;
      settings = {
        users = [{
          name = "alex";
          password = "$2a$10$g5byXeV9EsVAhUdmso5hv.MkeMi0XGKbEejzx0Y4xmucAg1BNGKoi";
        }];
        dns = {
          bind_hots = [
            "127.0.0.1"
          ];
          port = 54;
          upstream_dns = [
            # Example config with quad9
            "9.9.9.9"
            "149.112.112.112"
            # Uncomment the following to use a local DNS service (e.g. Unbound)
            # Additionally replace the address & port as needed
            # "127.0.0.1:5335"
          ];
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
          server_name = "dns.v220240679185274666.nicesrv.de";
          enabled = true;
          allow_unencrypted_doh = true;
          port_dns_over_tls = 853;
          port_dns_over_quic = 0;
          port_https = 3003;
          certificate_chain = "";
          private_key = "";
          certificate_path = "/var/lib/chain.pem";
          private_key_path = "/var/lib/key.pem";
        };
        # The following notation uses map
        # to not have to manually create {enabled = true; url = "";} for every filter
        # This is,qq however, fully optional
        filters = map (url: { enabled = true; url = url; }) [
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
        ];
      };
    };
  };
}
