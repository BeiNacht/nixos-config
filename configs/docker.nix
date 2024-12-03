{
  config,
  pkgs,
  lib,
  ...
}: {
  virtualisation = {
    docker = {
      enable = true;
      extraOptions = "--metrics-addr='127.0.0.1:9323' --experimental";
      storageDriver = "btrfs";
    };
  };

  users.extraGroups.docker.members = ["alex"];

  environment = {
    systemPackages = with pkgs; [
      docker-compose
      lazydocker
      minikube
      dive

      distrobox
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/docker"
      ];
    };
  };
}
