# Most stuff

### Commands


```
nix flake update

sudo mergerfs -o cache.files=partial,dropcacheonclose=true,category.create=mfs /run/media/alex/disk1:/run/media/alex/disk2:/run/media/alex/disk3 /home/alex/shared/raid

sudo nix-collect-garbage -d

sudo nix-env -p /nix/var/nix/profiles/system --list-generations
```

## Script

- `scripts/set-permissions.sh` — recursively set ownership and permissions under a path:
  - directories to `755`
  - regular files to `644`
  - ownership to `USER:GROUP`
