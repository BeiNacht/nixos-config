/opt/homebrew/bin/brew list --cask | while read -r cask; do
  file="$(/opt/homebrew/bin/brew cat "$cask" 2>/dev/null)"

  if echo "$file" | grep -q "auto_updates true"; then
    echo "$cask"
  elif echo "$file" | grep -q "version :latest" \
       && echo "$file" | grep -q "sha256 :no_check"; then
    echo "$cask"
  fi
done | sort -u
