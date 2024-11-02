{ config, pkgs, lib, outputs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    ../../configs/common.nix
    ../../configs/docker.nix
#    ../../configs/plasma-wayland.nix
#    ../../configs/user-gui.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      hashedPassword = {
        neededForUsers = true;
      };
    };
  };

  networking.hostName = "nixos-virtualbox"; # Define your hostname.
  time.timeZone = "Europe/Berlin";

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
      };
    };
    supportedFilesystems = [ "btrfs" ];
  };
  networking.networkmanager.enable = true;
  programs.nix-ld.enable = true;

  # services = {
  #   k3s = {
  #     enable = true;
  #     role = "server";
  #   };
  # };

  system.stateVersion = "24.11";
}
