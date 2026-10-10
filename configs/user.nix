{
  config,
  pkgs,
  ...
}: let
  sshKeys = import ./ssh-keys.nix;
in {
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

  programs = {
    zsh.enable = true;
    nix-ld.enable = true;
  };

  environment.pathsToLink = ["/share/zsh"];
}
