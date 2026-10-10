# Share presets for `services.samba.settings.<share>`, used by hosts that
# import samba.nix:
#   let shares = import ../configs/samba-shares.nix; in
#   services.samba.settings.storage = shares.share "/path/to/storage";
{
  # Read/write share for authenticated users.
  share = path: {
    inherit path;
    browseable = "yes";
    "guest ok" = "no";
    "read only" = "no";
    "create mask" = "0644";
    "directory mask" = "0755";
  };

  # macOS Time Machine backup target (vfs_fruit), owned by alex.
  timeMachine = path: {
    inherit path;
    "valid users" = "alex";
    public = "no";
    writeable = "yes";
    "force user" = "alex";
    "fruit:aapl" = "yes";
    "fruit:time machine" = "yes";
    "vfs objects" = "catia fruit streams_xattr";
  };
}
