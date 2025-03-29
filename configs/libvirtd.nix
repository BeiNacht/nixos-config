{pkgs, ...}: {
  users.extraGroups.libvirtd.members = ["alex"];

  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      # Used for UEFI boot of Home Assistant OS guest image
      qemu = {
        ovmf.enable = true;
        swtpm.enable = true;
        # vhostUserPackages = [pkgs.virtiofsd];
      };
    };

    spiceUSBRedirection.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      # For virt-install
      virt-manager
      # For lsusb
      usbutils
      # quick install vms
      quickemu
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/libvirt"
      ];
    };
  };

  systemd.tmpfiles.rules = [ "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware" ];
}
