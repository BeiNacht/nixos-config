{
  config,
  pkgs,
  lib,
  outputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../configs/common-linux.nix
    ../../configs/docker.nix
    ../../configs/user.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    validateSopsFiles = true;
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
      generateKey = true;
    };
  };

  boot = {
    initrd = {
      enable = true;
    };
  };

  networking = {
    networkmanager.enable = true;
    hostName = "nixos-virtualbox"; # Define your hostname.
  };

  nix.settings = {
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "gccarch-znver3"
    ];
    trusted-substituters = ["https://ai.cachix.org"];
    trusted-public-keys = ["ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="];
  };

  # nixpkgs.localSystem = {
  #   gcc.arch = "znver3";
  #   gcc.tune = "znver3";
  #   system = "x86_64-linux";
  # };

  programs.nix-ld.enable = true;

  services = {
    # k3s = {
    #   enable = true;
    #   role = "server";
    # };
  };

  system.stateVersion = "24.11";
}
