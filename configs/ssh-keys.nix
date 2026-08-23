# Shared SSH public keys, kept in one place so a key rotation only needs to
# happen here instead of being hunted down across every machine file.
{
  # Full set: interactive user login (~/.ssh/authorized_keys).
  personal = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH77R8HUxwajhXf4ibEeKxIBukhjz63nHLM9/1Om5OdM alex@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIxdlhkXa8xVZDgZwwnBI1oMzAvIyYQdAZujmnRYIpL Android"
  ];

  borg = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPjxTUEclBMOYixTd457wF/0N5HIZRp0kvAMAT/UK74Z bernd@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/tghG2pBTrqYT4+1nF1266lteRBf2bPL+OZAOjyFHL alex@vps-arm"
  ];

  # Subset used to unlock LUKS over SSH in the initrd (no phone key: unlocking
  # disks from a phone isn't a real scenario).
  initrd = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYEaT0gH9yJM2Al0B+VGXdZB/b2qjZK7n01Weq0TcmQ alex@framework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN99h5reZdz9+DOyTRh8bPYWO+Dtv7TbkLbMdvi+Beio alex@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkURF5v9vRyEPhsK80kUgYh1vsS0APL4XyH4F3Fpyic alex@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH77R8HUxwajhXf4ibEeKxIBukhjz63nHLM9/1Om5OdM alex@macbook"
  ];
}
