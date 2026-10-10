# nginx vhost presets for `services.nginx.virtualHosts.<name>`:
#   let vhosts = import ../nginx-vhosts.nix; in
#   services.nginx.virtualHosts."app.szczepan.ski" = vhosts.proxy "http://127.0.0.1:1234/";
{
  # Public HTTPS vhost (ACME cert, HTTP redirected) reverse-proxying everything
  # to a local backend, websockets included.
  proxy = url: {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = url;
      proxyWebsockets = true;
    };
  };
}
