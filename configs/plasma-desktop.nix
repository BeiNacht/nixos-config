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

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      # KWIN_DRM_DISABLE_TRIPLE_BUFFERING = "1";
    };
  };

  services = {
    displayManager = {
      sddm = {
        wayland.enable = true;
      };
      defaultSession = "plasma";
    };

    libinput.enable = true;
  };
}
