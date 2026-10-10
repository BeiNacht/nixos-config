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

    codegraph # pre-indexed code knowledge graph for AI coding agents

    harlequin # tui sql client
    python313
  ];

  # programs = {
  #   adb.enable = true;
  # };
}
