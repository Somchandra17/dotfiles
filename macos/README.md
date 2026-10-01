# macOS dotfiles

Two independent parts. Each has its own README and can be installed on its own.

| Folder | What it is | Install |
|---|---|---|
| [`terminal/`](terminal/README.md) | Ghostty / Kitty, ZSH, Starship, Atuin, Ranger, Fastfetch, TokyoNight theme | Copy `terminal/home/.` to `~` (see its README) |
| [`paneru/`](paneru/README.md) | Paneru tiling window manager with niri-style fn-key bindings, JankyBorders, keybinding cheat sheet | `./paneru/install.sh` plus the manual System Settings steps |

Both folders keep their files in `home/`, which mirrors `$HOME` exactly: `home/.config/x` belongs at `~/.config/x`.
