#!/usr/bin/env bash
# Installs the Paneru (sliding tiling WM) setup from this folder onto macOS.
# Idempotent: safe to re-run. Anything it replaces is backed up with a timestamp suffix.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/home"
TS="$(date +%Y%m%d-%H%M%S)"
CHEATSHEET_AGENT="com.somchandra.paneru-cheatsheet"
PANERU_AGENT_PLIST="$HOME/Library/LaunchAgents/com.github.karinushka.paneru.plist"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }

[[ "$(uname -s)" == "Darwin" ]] || { echo "macOS only." >&2; exit 1; }
command -v brew >/dev/null || { echo "Homebrew is required: https://brew.sh" >&2; exit 1; }

backup() {
  if [[ -e "$1" || -L "$1" ]]; then
    mv "$1" "$1.bak-$TS"
    warn "backed up $1 -> $1.bak-$TS"
  fi
}

say "Installing packages (paneru, borders)"
brew list --formula paneru >/dev/null 2>&1 || brew install paneru
brew tap felixkratz/formulae >/dev/null 2>&1 || true
# Newer Homebrew refuses third-party formulae until they are explicitly trusted.
if brew trust --help >/dev/null 2>&1; then
  brew trust --formula felixkratz/formulae/borders >/dev/null
fi
brew list --formula borders >/dev/null 2>&1 || brew install felixkratz/formulae/borders

say "Removing configs that would override paneru.toml"
# A Lua config replaces the TOML entirely, so paneru.toml would be silently ignored.
backup "$HOME/.config/paneru/init.lua"
backup "$HOME/.paneru.lua"
backup "$HOME/.paneru.toml"
backup "$HOME/.paneru"

say "Copying config files"
for rel in .config/paneru/paneru.toml .config/paneru/cheatsheet.html .config/borders/bordersrc \
           "Library/LaunchAgents/$CHEATSHEET_AGENT.plist"; do
  dest="$HOME/$rel"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]] && ! cmp -s "$SRC/$rel" "$dest"; then backup "$dest"; fi
  cp "$SRC/$rel" "$dest"
done
chmod +x "$HOME/.config/borders/bordersrc"

say "Adding 'paneru-help' alias to ~/.zshrc"
touch "$HOME/.zshrc"
grep -qF "alias paneru-help=" "$HOME/.zshrc" ||
  printf "\nalias paneru-help='open ~/.config/paneru/cheatsheet.html'\n" >> "$HOME/.zshrc"

say "Starting services"
if [[ -f "$PANERU_AGENT_PLIST" ]]; then paneru restart; else paneru install; paneru start || true; fi
brew services restart felixkratz/formulae/borders >/dev/null
launchctl bootout "gui/$(id -u)/$CHEATSHEET_AGENT" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/$CHEATSHEET_AGENT.plist"

cat <<'EOF'

Done. Finish these MANUAL steps (they are what make the fn-key bindings work):

 1. System Settings > Privacy & Security > Accessibility: enable "paneru".
 2. System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys
      (Apple Internal Keyboard): Globe (fn) key -> "^ Control".
 3. System Settings > Keyboard > Keyboard Shortcuts > Mission Control: turn OFF
      "Move left a space", "Move right a space", "Switch to Desktop 1/2/3".
 4. System Settings > Trackpad > More Gestures: set "Swipe between full-screen
      applications" and "Mission Control" to FOUR fingers (Paneru uses three).
 5. Optional: System Settings > Keyboard > "Press Globe key to" -> Do Nothing.

Then run:  paneru restart     and open the cheat sheet with:  paneru-help
EOF
