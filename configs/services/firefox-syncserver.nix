{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/mysql"
      ];
    };
  };

  users = {
    groups.firefox-syncserver = {};
    users.firefox-syncserver = {
      isSystemUser = true;
      group = "firefox-syncserver";
      extraGroups = [config.users.groups.keys.name];
    };
  };

  services = {
    mysql.package = pkgs.mariadb;
    firefox-syncserver = {
      enable = true;
      secrets = config.sops.secrets."syncserver-secrets".path;
      logLevel = "trace";
      singleNode = {
        enable = true;
        hostname = "firefox-sync.szczepan.ski";
        enableTLS = true;
        enableNginx = true;
      };
    };
  };
}
