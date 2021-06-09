sudo rsync -ah --delete --progress /home/alex/Workspace/nixos-config/ /root/nixos/
sudo rm /etc/nixos/configuration.nix
sudo ln -s /root/nixos/machine/`hostname`/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch