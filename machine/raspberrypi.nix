{ config, pkgs, lib, ... }:
let secrets = import ../configs/secrets.nix;
in {
  imports = [
    "${
      fetchTarball
      "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz"
    }/raspberry-pi/4"
    ../configs/docker.nix
    ../configs/common.nix
    ../configs/user.nix
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  time.timeZone = "Europe/Berlin";
  networking = {
    hostName = "raspberrypi";
    wireless = {
      enable = true;
      networks.Skynet.psk = secrets.wifipassword;
      interfaces = [ "wlan0" ];
    };
  };

  environment.systemPackages = with pkgs; [ vim nano git rsync ];

  # Enable GPU acceleration
  # hardware.raspberry-pi."4".fkms-3d.enable = true;

  # services.xserver = {
  #   enable = true;
  #   displayManager.lightdm.enable = true;
  #   desktopManager.xfce.enable = true;
  # };

  # hardware.pulseaudio.enable = true;
  system.stateVersion = "22.05";
}
