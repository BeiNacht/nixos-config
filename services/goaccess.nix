{ config, lib, pkgs, ... }:
let
  secrets = import ../configs/secrets.nix;
in
{
  services = {
    nginx = {
      virtualHosts = {
        "goaccess.szczepan.ski" = {
          forceSSL = true;
          enableACME = true;
          basicAuthFile = config.sops.secrets.goaccess-password.path;
          locations = {
            "/" = { root = "/var/www/goaccess"; };
            "/ws" = {
              proxyPass = "http://127.0.0.1:7890/";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };

  systemd = {
    tmpfiles.settings = {
      "goaccess" = {
        "/var/www/goaccess" = { d.mode = "0755"; };
      };
    };

    services = {
      # Limit stack size to reduce memory usage
      fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

      goaccess = {
        description = "GoAccess real-time web log analysis";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        script = "${pkgs.gzip}/bin/zcat -f /var/log/nginx/access.* | ${pkgs.goaccess}/bin/goaccess - -o /var/www/goaccess/index.html --log-format='%v %h %^[%d:%t %^]%^\"%r\" %s %b \"%R\" \"%u\"' --real-time-html --ws-url=wss://goaccess.szczepan.ski:443/ws --port 7890 --time-format \"%H:%M:%S\" --date-format \"%d/%b/%Y\"";
        # serviceConfig = {
        #   StateDirectory = "/var/www/goaccess";
        #   # ExecStart = "${pkgs.bash}/bin/bash -c "${pkgs.gzip}/bin/zcat -f /var/log/nginx/access.* | ${pkgs.goaccess}/bin/goaccess -o /var/www/goaccess/index.html --log-format='%v %h %^[%d:%t %^]%^\"%r\" %s %b \"%R\" \"%u\"' --real-time-html --ws-url=wss://goaccess.szczepan.ski:443/ws --port 7890 --time-format \"%H:%M:%S\" --date-format \"%d/%b/%Y\"'";
        #   # ExecStop = "/bin/kill -9 ${MAINPID}";
        # };
      };
    };
  };
}
