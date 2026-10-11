{
  config,
  pkgs,
  ...
}: {
  # Sunshine game-stream host for Moonlight clients. Runs as a user service
  # in alex's graphical session; pairing state and credentials live in
  # ~/.config/sunshine (on /home, so it survives an ephemeral root). Pair a
  # client via the web UI at https://localhost:47990.
  services.sunshine = {
    enable = true;
    # Sunshine 2026.914 rejects (HTTP 401) a client whose certificate matches
    # more than one paired record, yet re-pairing appends a duplicate record,
    # so one re-pair locks the client out for good. Replace instead of append.
    package = pkgs.sunshine.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./sunshine-dedupe-repaired-clients.patch];
    });
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
