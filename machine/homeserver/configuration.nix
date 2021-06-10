{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ../../configs/common.nix
      ../../configs/virtualisation.nix
      (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homeserver"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  networking.useDHCP = false;
  networking.interfaces.enp2s0.useDHCP = true;

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
#      theme = "powerlevel10k/powerlevel10k";
      customPkgs = [
        pkgs.zsh-autosuggestions
        pkgs.zsh-syntax-highlighting
        pkgs.zsh-powerlevel10k
      ];
      plugins = [
        "cp"
        "common-aliases"
        "docker "
        "systemd"
        "wd"
        "kubectl"
#        "zsh-autosuggestions"
#        "zsh-syntax-highlightin"
        "git"
      ];
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.alex = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    snapraid
    mergerfs
    samba
    openssl
    hdparm
    docker-compose
  ];

  systemd.mounts = [
    {
      requires = [ 
        "mnt-disk1.mount"
        "mnt-disk2.mount"
        "mnt-disk3.mount"
      ];
      after = [
        "mnt-disk1.mount"
        "mnt-disk2.mount"
        "mnt-disk3.mount"
      ];
      what = "/mnt/disk1:/mnt/disk2:/mnt/disk3";
      where = "/mnt/storage";
      type = "fuse.mergerfs";
      options = "defaults,allow_other,use_ino,fsname=mergerfs,minfreespace=50G,func.getattr=newest,noforget";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  powerManagement.powerUpCommands = ''
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/sda
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/sdb
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/sdc
    ${pkgs.hdparm}/sbin/hdparm -S 241 /dev/sdf
    ${pkgs.hdparm}/sbin/hdparm -Y /dev/sda
    ${pkgs.hdparm}/sbin/hdparm -Y /dev/sdb
    ${pkgs.hdparm}/sbin/hdparm -Y /dev/sdc
    ${pkgs.hdparm}/sbin/hdparm -Y /dev/sdf
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.vscode-server.enable = true;

  services.openssh.enable = true;

  services.netdata.enable = true;

  services.jellyfin.enable = true;

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = server
      netbios name = server
      security = user
      guest account = nobody
      map to guest = bad user
      logging = systemd
      max log size = 50      
    '';
    shares = {
      storage = {
        path = "/mnt/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";    };
    };
  };
   
  # Open ports in the firewall.
  # networking.firewall.enable = true;
  # networking.firewall.allowPing = true;
  # networking.firewall.allowedTCPPorts = [ 445 139 19999 ];
  # networking.firewall.allowedUDPPorts = [ 137 138 19999 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}