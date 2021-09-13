{ config, pkgs, lib, ... }:

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemuPackage = pkgs.qemu_kvm;
    };
    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [ proot ];
}
