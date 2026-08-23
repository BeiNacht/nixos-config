{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  serviceConfig = {
    MountAPIVFS = true;
    PrivateTmp = true;
    PrivateUsers = true;
    ProtectKernelModules = true;
    PrivateDevices = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectKernelTunables = true;
    ProtectSystem = "full";
    RestrictSUIDSGID = true;
  };
  sshKeys = import ./ssh-keys.nix;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;

    users.alex = {
      isNormalUser = true;
      uid = 1000;
      hashedPasswordFile = config.sops.secrets.hashedPassword.path;
      extraGroups = [
        "adbusers"
        "davfs2"
        "locatedb"
        "lp"
        "networkmanager"
        "nginx"
        "scanner"
        "tailscale"
        "wheel"
      ];
      openssh.authorizedKeys.keys = sshKeys.personal;
    };
  };

  systemd.services = {
    alex.serviceConfig = serviceConfig;
    root.serviceConfig = serviceConfig;
  };

  programs = {
    zsh.enable = true;
    nix-ld.enable = true;
  };

  environment.pathsToLink = ["/share/zsh"];
}
