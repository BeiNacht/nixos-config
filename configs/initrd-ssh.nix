# SSH server in the initrd so the LUKS root can be unlocked remotely
# (mini, homeserver, vps-arm). The host still has to add its NIC driver to
# boot.initrd.availableKernelModules and get an address (e.g. ip=dhcp).
{...}: let
  sshKeys = import ./ssh-keys.nix;
in {
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 22;
      authorizedKeys = sshKeys.initrd;
      hostKeys = ["/persist/pre_boot_ssh_key"];
    };
  };
}
