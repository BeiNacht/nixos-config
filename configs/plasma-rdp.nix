{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./plasma.nix
  ];

  services = {
    xrdp = {
      enable = true;
      defaultWindowManager = "startplasma-x11";
    };

    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  # Disable systemd targets for sleep and hibernation
  systemd = {
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
}
