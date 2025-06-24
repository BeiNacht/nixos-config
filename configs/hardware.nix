{
  hardware = {
    bluetooth.enable = true;
    sane.enable = true;
  };

  # optional for pipewire
  security.rtkit.enable = true;
  services = {
    fwupd.enable = true;
    power-profiles-daemon.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/bluetooth"
      ];
    };
  };
}
