{
  hardware = {
    bluetooth.enable = true;
    sane.enable = true;
  };

  services = {
    fwupd.enable = true;
  };

  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/bluetooth"
      ];
    };
  };
}
