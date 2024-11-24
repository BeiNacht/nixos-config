{
  config,
  pkgs,
  lib,
  outputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../configs/common.nix
    ../../configs/docker.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      hashedPassword = {
        neededForUsers = true;
      };
    };
  };

  time.timeZone = "Europe/Berlin";

  boot = {
    initrd = {
      enable = true;
      supportedFilesystems = ["btrfs"];
    };
  };

  networking = {
    networkmanager.enable = true;
    hostName = "nixos-virtualbox"; # Define your hostname.
  };

  programs.nix-ld.enable = true;

  # services = {
  #   k3s = {
  #     enable = true;
  #     role = "server";
  #   };
  # };

  system.stateVersion = "24.11";
}
