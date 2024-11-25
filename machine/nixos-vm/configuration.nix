{
  config,
  pkgs,
  lib,
  outputs,
  ...
}: {
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {allowUnfree = true;};
  };

  imports = [
    ./hardware-configuration.nix
    ../../configs/common.nix
    ../../configs/docker.nix
    ../../configs/plasma-wayland.nix
    ../../configs/user-gui.nix
    ../../configs/user.nix
  ];

  networking.hostName = "nixos-vm"; # Define your hostname.
  time.timeZone = "Europe/Berlin";
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.systemd.enable = true;
    tmp.useTmpfs = false;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  hardware.parallels = {
    enable = true;
    # autoMountShares = true;
  };

  services = {
    k3s = {
      enable = false;
      role = "server";
    };

    gvfs.enable = true;
  };

  networking = {
    firewall.enable = false;
    networkmanager = {enable = true;};
  };

  environment.systemPackages = with pkgs; [librewolf];

  system.stateVersion = "24.11";
}
