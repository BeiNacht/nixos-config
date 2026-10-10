{
  config,
  pkgs,
  lib,
  outputs,
  ...
}: let
  shares = import ../configs/samba-shares.nix;
in {
  imports = [
    ../configs/common-linux.nix
    ../configs/docker.nix
    ../configs/filesystem.nix
    ../configs/plasma-desktop.nix
    ../configs/samba.nix
    ../configs/user.nix
    ../configs/user-gui.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  fileSystems = {
    "/home/alex/shared/storage" = {
      device = "/dev/disk/by-uuid/9a85d05a-2d26-47e9-803a-f10740d9eafa";
      fsType = "btrfs";
      options = [
        "autodefrag"
        "compress=zstd"
        "nodiratime"
        "noatime"
        "noauto" # Don't mount at boot
        # "x-systemd.automount" # Enable systemd automounting
        # "x-systemd.idle-timeout=10min" # Optional: auto-unmount/lock after 10 mins of silence
        # "x-systemd.device-timeout=5s" # Don't freeze the system if the USB isn't plugged in
        "nofail" # Boot proceeds normally if USB is missing
      ];
    };
  };

  # environment.etc.crypttab.text = ''
  #   storage UUID=fbaa39cb-ff4b-43d0-9ff2-1e9b189a07f1 /persist/hdd.key noauto,nofail
  # '';

  systemd.services.decrypt-external-hdd = {
    description = "Decrypt and mount external HDD";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Open LUKS and trigger the systemd mount unit
      ExecStart = pkgs.writeShellScript "decrypt-start" ''
        if [ ! -b /home/alex/shared/storage ]; then
          # Open the partition using your local key file
          ${pkgs.cryptsetup}/bin/cryptsetup luksOpen /dev/disk/by-uuid/fbaa39cb-ff4b-43d0-9ff2-1e9b189a07f1 external_crypt --key-file /persist/hdd.key
          # Start the fileSystem mount service (escaped name for '/media/external-drive')
          ${pkgs.systemd}/bin/systemctl start home-alex-shared-storage.mount
        fi
      '';
      # Safely unmount and lock the drive when stopped or pulled
      ExecStop = pkgs.writeShellScript "decrypt-stop" ''
        ${pkgs.systemd}/bin/systemctl stop home-alex-shared-storage.mount
        if [ -b /home/alex/shared/storage ]; then
          ${pkgs.cryptsetup}/bin/cryptsetup luksClose external_crypt
        fi
      '';
    };
  };

  virtualisation.vmware.guest.enable = true;

  services = {
    k3s = {
      enable = false;
      role = "server";
    };

    samba.settings.storage = shares.share "/home/alex/shared/storage";

    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="fbaa39cb-ff4b-43d0-9ff2-1e9b189a07f1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="decrypt-external-hdd.service"
    '';
  };

  networking = {
    hostName = "nixos-vm-fusion";
    firewall.enable = false;
    networkmanager = {enable = true;};
  };

  system.stateVersion = "25.11";
}
