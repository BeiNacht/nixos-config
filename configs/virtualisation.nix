{ config, pkgs, lib, ... }:

{
  virtualisation = {
    docker.enable = true;
    libvirtd = {
      enable = true;
      qemuPackage = pkgs.qemu_kvm;
    };
    spiceUSBRedirection.enable = true;
  };
}
