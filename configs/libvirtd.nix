{pkgs, ...}: {
  users.extraGroups.libvirtd.members = ["alex"];

  virtualisation = {
    libvirtd = {
      enable = true;
      # Used for UEFI boot of Home Assistant OS guest image
      qemu.ovmf.enable = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      # For virt-install
      virt-manager
      # For lsusb
      usbutils
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/libvirt"
      ];
    };
  };
}
