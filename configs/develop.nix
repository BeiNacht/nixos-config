{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs.unstable; [
    insomnia
    meld
    virt-manager

    #rust
    cargo
    nodejs

    ruby
  ];
}
