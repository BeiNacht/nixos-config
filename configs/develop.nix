{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    insomnia # rest tool
    meld # diff tool
    dbeaver-bin # db viewer

    # rust
    cargo
    nodejs

    claude-code

    # harlequin # tui sql client
  ];

  # programs = {
  #   adb.enable = true;
  # };
}
