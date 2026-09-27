{config, ...}: {
  # Sunshine game-stream host for Moonlight clients. Runs as a user service
  # in alex's graphical session; pairing state and credentials live in
  # ~/.config/sunshine (on /home, so it survives an ephemeral root). Pair a
  # client via the web UI at https://localhost:47990.
  services.sunshine = {
    enable = true;
    autoStart = true;
    # Needed for KMS/DRM capture, which is the only capture method that
    # works reliably under the Plasma Wayland session.
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      sunshine_name = config.networking.hostName;
    };
  };
}
