{
  config,
  pkgs,
  lib,
  outputs,
  inputs,
  ...
}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  imports = [
    ../../configs/common.nix
  ];

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    # finder.AppleShowAllExtensions = true;
    # finder.FXPreferredViewStyle = "clmv";
    # screencapture.location = "~/Pictures/screenshots";
    screensaver.askForPasswordDelay = 10;
  };

  services = {
    nix-daemon.enable = true;
  };

  nix.settings.experimental-features = "nix-command flakes";

  nix = {
    configureBuildUsers = true;
    useDaemon = true;
  };

  homebrew.enable = true;
  system.stateVersion = 5;
}
