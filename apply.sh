#!/usr/bin/env bash

sudo rsync -ah --delete --progress `pwd`/ /root/nixos/
sudo rm /etc/nixos/configuration.nix
sudo ln -s /root/nixos/machine/`hostname`/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch