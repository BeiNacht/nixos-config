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
    ../configs/plasma.nix
    ../configs/user.nix
    ../configs/user-gui.nix
  ];

  # sops = {
  #   defaultSopsFile = ../secrets/secrets-homeserver.yaml;
  # };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/edc684e5-3151-4a2b-ae10-25d82a66a616";
    };

    "/home" = {
      device = "/dev/disk/by-uuid/edc684e5-3151-4a2b-ae10-25d82a66a616";
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/edc684e5-3151-4a2b-ae10-25d82a66a616";
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/edc684e5-3151-4a2b-ae10-25d82a66a616";
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/edc684e5-3151-4a2b-ae10-25d82a66a616";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/809F-0613";
    };
  };

  # swapDevices = [
  #   {
  #     device = "/dev/disk/by-uuid/dcc19b48-b064-4160-af30-20eabb6dde30";
  #   }
  # ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  virtualisation.vmware.guest.enable = true;

  services = {
    k3s = {
      enable = false;
      role = "server";
    };
  };

  networking = {
    hostName = "nixos-vm-fusion";
    firewall.enable = false;
    networkmanager = {enable = true;};
  };

  system.stateVersion = "25.11";
}
