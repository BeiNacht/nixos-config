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
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/plasma.nix
    ../../configs/user.nix
    ../../configs/user-gui.nix
  ];

  networking.hostName = "nixos-vm"; # Define your hostname.
  time.timeZone = "Europe/Berlin";
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  #  hardware.parallels = {
  #    enable = true;
  # autoMountShares = true;
  #  };

  services = {
    k3s = {
      enable = false;
      role = "server";
    };
  };

  networking = {
    firewall.enable = false;
    networkmanager = {enable = true;};
  };

  system.stateVersion = "24.11";
}
