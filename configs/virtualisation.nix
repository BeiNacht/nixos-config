{ config, pkgs, lib, ... }:

{
  # container virtualization
  virtualisation.docker.enable = true;

  # hypervisor virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemuPackage = pkgs.qemu_kvm;
  };
}
