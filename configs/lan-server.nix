# Always-on headless boxes on the home LAN (mini, homeserver): remote LUKS
# unlock, tailscale subnet routing, no host firewall (LAN + tailnet only).
{...}: {
  imports = [
    ./initrd-ssh.nix
  ];

  networking = {
    useDHCP = false;
    firewall.enable = false;
    nftables.enable = false;
  };

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    locate.prunePaths = ["/mnt" "/nix"];
  };
}
