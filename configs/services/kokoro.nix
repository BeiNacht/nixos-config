let
  hostname = "vps-arm.meteor-altered.ts.net";
in {
  virtualisation.oci-containers = {
    backend = "docker";
    containers.kokoro = {
      image = "ghcr.io/remsky/kokoro-fastapi-cpu:latest";
      ports = ["127.0.0.1:8880:8880"];
    };
  };

  services.nginx.virtualHosts.kokoro = {
    serverName = hostname;
    onlySSL = true;
    listen = [
      {
        addr = "0.0.0.0";
        port = 8443;
        ssl = true;
      }
    ];
    sslCertificate = "/var/lib/nginx/${hostname}.crt";
    sslCertificateKey = "/var/lib/nginx/${hostname}.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:8880";
      proxyWebsockets = true;
    };
  };
}
