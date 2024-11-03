{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    insomnia
    meld
    virt-manager

    #rust
    cargo
    nodejs

    ruby
  ];
}
