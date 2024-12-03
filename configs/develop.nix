{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    insomnia
    meld

    # rust
    cargo
    nodejs

    ruby
  ];

  programs = {
    adb.enable = true;
  };
}
