{
  hardware = {
    bluetooth.enable = true;
    sane.enable = true;
  };

  # optional for pipewire
  security.rtkit.enable = true;
  services = {
    # fwupd.enable = true;
    power-profiles-daemon.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # disable autosuspend for razer mouse
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1532", ATTR{idProduct}=="009c", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"
    '';
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/bluetooth"
      ];
    };
  };
}
