{
  config,
  pkgs,
  lib,
  ...
}: {
  services = {
    fwupd.enable = true;
  };
}
