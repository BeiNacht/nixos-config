{ config, pkgs, lib, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      extraOptions = "--metrics-addr='127.0.0.1:9323' --experimental";
    };
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
