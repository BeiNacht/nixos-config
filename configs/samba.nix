# Shared samba server settings used by every host that exposes shares
# (desktop, mini, homeserver, vps-arm, framework). Hosts only need to import
# this and then set their own `services.samba.settings.<share>` blocks.
{...}: {
  services.samba = {
    enable = true;
    settings.global = {
      workgroup = "WORKGROUP";
      "server string" = "server";
      "netbios name" = "server";
      security = "user";
      "guest account" = "nobody";
      "map to guest" = "bad user";
      logging = "systemd";
      "max log size" = 50;
      "invalid users" = [
        "root"
      ];
      "passwd program" = "/run/wrappers/bin/passwd %u";
    };
  };
}
