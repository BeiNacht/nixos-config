{
  config,
  pkgs,
  lib,
  outputs,
  ...
}: {
  imports = [
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/filesystem.nix
    ../configs/plasma-desktop.nix
    ../configs/user.nix
    ../configs/user-gui.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  virtualisation.vmware.guest.enable = true;

  services = {
    k3s = {
      enable = false;
      role = "server";
    };

    samba = {
      enable = true;
      settings = {
        global = {
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
        storage = {
          browseable = "yes";
          "guest ok" = "no";
          path = "/run/media/alex/storage";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };
  };

  networking = {
    hostName = "nixos-vm-fusion";
    firewall.enable = false;
    networkmanager = {enable = true;};
  };

  system.stateVersion = "25.11";
}
