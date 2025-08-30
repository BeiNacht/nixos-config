{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    insomnia # rest tool
    meld # diff tool
    dbeaver-bin # db viewer

    pgadmin4-desktopmode

    # rust
    cargo
    nodejs

    # harlequin # tui sql client
  ];

  # programs = {
  #   adb.enable = true;
  # };
}
