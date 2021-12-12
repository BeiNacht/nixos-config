{ config, pkgs, lib, ... }:

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.package = pkgs.qemu_kvm;
    };
    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [ proot ];
}
