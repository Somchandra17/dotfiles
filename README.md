# dotfiles

Personal configuration for three machines: a Linux laptop running Hyprland, a Fedora desktop running niri, and a MacBook Pro.

```
.
├── hyprland/            Linux laptop (Hyprland)
│   ├── home/            mirror of $HOME: .config, .local, fonts, icons, shell rc files
│   ├── packages/        apt / flatpak / snap package lists
│   └── README.md
├── niri/                Fedora desktop (niri + Noctalia)
│   ├── home/            mirror of $HOME: niri, kitty, zsh, Noctalia settings, Wallhaven
│   ├── system/          mirror of /etc, /usr/local, and the GRUB theme
│   ├── packages/        kernel, NVIDIA, and Flatpak list
│   ├── docs/            NVIDIA update/boot reliability note
│   ├── maintenance/     tested NVIDIA preparation installer and rollback
│   └── README.md
├── macos/
│   ├── terminal/        Ghostty, Kitty, ZSH, Starship, Atuin, Ranger, Fastfetch
│   │   ├── home/        mirror of $HOME
│   │   └── terminal-cheatsheet.md
│   ├── paneru/          Paneru tiling WM, borders, keybinding cheat sheet
│   │   ├── home/        mirror of $HOME
│   │   └── install.sh
│   └── README.md
├── AGENTS.md            deployment manual for AI agents (CLAUDE.md points here)
└── README.md
```

## Where to start

| I want to... | Read |
|---|---|
| Set up the Hyprland desktop on Linux | [`hyprland/README.md`](hyprland/README.md) |
| Restore the Fedora niri desktop | [`niri/README.md`](niri/README.md) |
| Set up the macOS terminal | [`macos/terminal/README.md`](macos/terminal/README.md) |
| Set up the Paneru window manager on macOS | [`macos/paneru/README.md`](macos/paneru/README.md) |
| Let an AI agent deploy any of these | [`AGENTS.md`](AGENTS.md) |

## Conventions

- Every `home/` folder mirrors `$HOME`: `home/.config/kitty/kitty.conf` goes to `~/.config/kitty/kitty.conf`.
- Back up before copying. Never overwrite a user's existing file without keeping a copy.
- The parts are independent. Installing one never requires another.

## Cloning on macOS

`hyprland/home/.icons/` contains about 1,300 paths that differ only in letter case (for example `KNetAttach.svg` and `knetattach.svg`). macOS filesystems are case-insensitive, so a clone on a Mac shows a couple of hundred icon files as modified or typechanged even though nobody touched them. **Never commit those changes.** Deploy the Hyprland part from a Linux clone, and on a Mac stage only the paths you actually changed (`git add <path>`, never `git add -A`).
