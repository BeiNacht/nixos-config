{ config, pkgs, lib, ... }:
{
  services = {
    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };
  };
}
