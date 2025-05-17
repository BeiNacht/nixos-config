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
        "wheel"
        "networkmanager"
        "lp"
        "nginx"
        "scanner"
        "adbusers"
        "locatedb"
        "davfs2"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
      ];
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
