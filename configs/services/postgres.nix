{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/postgresql"
      ];
    };
  };

  sops = {
    secrets = {
      postgres_password_hash = {
        owner = config.systemd.services.postgresql.serviceConfig.User;
        restartUnits = ["postgresql.service"];
      };
    };
  };

  services = {
    postgresql = {
      enable = true;
      enableTCPIP = true;
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      root      postgres
           superuser_map      postgres  postgres
           # Let other names login as themselves
           superuser_map      /^(.*)$   \1
      '';

      authentication = pkgs.lib.mkOverride 10 ''
        #...
        #type database DBuser origin-address auth-method
        local all all trust
        # ipv4
        host all postgres 127.0.0.1/32 scram-sha-256
      '';

      ensureUsers = [
        {
          name = "postgres";
          ensureClauses = {
            login = true;
          };
        }
      ];
    };
  };

  systemd.services."postgres-user-setup" = {
    serviceConfig.Type = "oneshot";
    wantedBy = ["postgresql.service"];
    after = ["postgresql.service"];
    serviceConfig.User = "postgres";
    environment.PSQL = "psql";
    path = [
      pkgs.gnugrep
      pkgs.postgresql
    ];
    script = ''
      password=$(cat "${config.sops.secrets.postgres_password_hash.path}")

      $PSQL -tXA \
        -c "ALTER ROLE postgres WITH ENCRYPTED PASSWORD '$password'"
          # ....
    '';
  };
}
