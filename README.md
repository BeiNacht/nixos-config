# Most stuff

## Borg Backup
it's important to add the ssh host key to known hosts

```
[u278697.your-storagebox.de]:23 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs
[u278697.your-storagebox.de]:23 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==
[u278697.your-storagebox.de]:23 ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==
```
### Commands


```
nix flake update .

sudo mergerfs -o cache.files=partial,dropcacheonclose=true,category.create=mfs /run/media/alex/disk1:/run/media/alex/disk2:/run/media/alex/disk3 /home/alex/shared/raid

sudo nix-collect-garbage -d

sudo nix-env -p /nix/var/nix/profiles/system --list-generations
```
