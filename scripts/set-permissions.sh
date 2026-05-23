#!/usr/bin/env sh

set -eu

usage() {
    cat <<EOF
Usage: $(basename "$0") USER GROUP [PATH]

Recursively set ownership and permissions under PATH (default: current directory).

- Directories are set to 755
- Regular files are set to 644
- Ownership is set to USER:GROUP for all entries

Examples:
  $(basename "$0") alice staff /var/www
  $(basename "$0") root root
EOF
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage
    exit 1
fi

user=$1
group=$2
path=${3:-.}

if [ ! -e "$path" ]; then
    echo "Error: target path '$path' does not exist." >&2
    exit 2
fi

chown -R "${user}:${group}" "$path"

find "$path" -type d -exec chmod 755 {} +
find "$path" -type f -exec chmod 644 {} +

echo "Permissions and ownership updated for '$path' (user=${user}, group=${group})."
