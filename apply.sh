#!/usr/bin/env zsh

sudo rsync -ah --delete --progress `pwd`/ /root/nixos/
sudo rm /etc/nixos/configuration.nix
sudo ln -s /root/nixos/machine/`hostname`.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch
