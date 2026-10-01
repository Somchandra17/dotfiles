# Hyprland dotfiles (Linux)

My Hyprland desktop, built on end-4's [dots-hyprland](https://github.com/end-4/dots-hyprland) ("illogical-impulse") with my own overrides.

| | |
|---|---|
| Machine | Acer Swift SF314-510G (single built-in display `eDP-1`, 1920x1080) |
| OS | EndeavourOS (Linux 6.12 LTS) at last update; the package lists in `packages/` come from an earlier Ubuntu install |
| WM | Hyprland 0.54 |
| Shell UI | Quickshell config `ii` (from dots-hyprland, **not in this repo**) |

`home/` mirrors `$HOME`: `home/.config/hypr/hyprland.conf` goes to `~/.config/hypr/hyprland.conf`.

## What is active and what is a leftover

`~/.config/hypr/hyprland.conf` loads only these files:

```
hyprland/{env,execs,general,rules,colors,keybinds}.conf   dots-hyprland defaults
custom/{env,execs,general,rules,keybinds}.conf            my overrides (edit these)
workspaces.conf, monitors.conf                            monitors.conf defers to kanshi
```

Everything else in `.config/hypr/` is **not loaded**. It's left over from earlier setups and kept for reference:

- `bindings.conf`, `autostart.conf`, `input.conf`, `looknfeel.conf` and others at the top level, from Omarchy (they call `omarchy-*` commands).
- `UserConfigs/`, plus most of `scripts/` and `UserScripts` references, from JaKooLit's Hyprland-Dots. `custom/keybinds.conf` still calls a few of these scripts (`KillActiveProcess.sh`, `ChangeLayout.sh`, `Dropterminal.sh`).

## Contents

| Component | Path under `home/` | Notes |
|---|---|---|
| Hyprland | `.config/hypr/` | See above; `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf` |
| Displays | `.config/kanshi/config`, `.config/autostart/kanshi.desktop` | Laptop-only fallback profile plus external-monitor profiles |
| Terminal | `.config/kitty/` | Plus `kitty-themes/` |
| Shells | `.zshrc`, `.p10k.zsh`, `.bashrc`, `.profile`, `.zprofile`, `.config/fish/` | Zsh with Powerlevel10k; Fish with Hyprland autostart (`auto-Hypr.fish`) |
| Bar, launcher, notifications | `.config/waybar/`, `.config/rofi/`, `.config/swaync/`, `.config/wlogout/` | Used by the JaKooLit-era scripts; Quickshell `ii` replaces most of them |
| Theming | `.config/wallust/`, `.config/gtk-3.0/`, `.config/gtk-4.0/`, `.config/qt5ct/`, `.config/qt6ct/` | Wallust generates colors from the wallpaper |
| Widgets (older) | `.config/ags/` | AGS config from before Quickshell |
| Tools | `.config/btop/`, `.config/cava/`, `.config/fastfetch/`, `.config/swappy/`, `.config/terminator/`, `.config/neofetch/` | |
| Scripts | `.local/bin/` | `cliphist-rofi`, `code-hyprland`, `fix-display` |
| Fonts | `.fonts/` | Inter, Rubik, Bebas Neue, Material, feather, and others |
| Icons and cursor | `.icons/` | Bibata-Modern-Ice, Flat-Remix-Blue Dark/Light, Gruvbox-Plus Dark/Light |
| Packages | `../packages/` | `apt-manual.txt` (305), `apt-packages.txt` (3125), `flatpak.txt`, `snap.txt` |

## Install

Run this on Linux, from a clone made on Linux (see Gotchas).

1. **Install dots-hyprland first.** It provides Quickshell, the `ii` config and its dependencies. Follow its README; on Arch-based systems its installer handles the packages.
2. **Optional extra packages.** The lists come from Ubuntu and need translating on Arch. On Ubuntu/Debian:

   ```bash
   xargs -a hyprland/packages/apt-manual.txt sudo apt install -y
   xargs -a hyprland/packages/flatpak.txt flatpak install -y
   xargs -a hyprland/packages/snap.txt -n1 sudo snap install
   ```

3. **Back up, then copy.** Leave out the machine-specific files listed under Gotchas:

   ```bash
   cp -a ~/.config ~/.config.bak-$(date +%Y%m%d-%H%M%S)
   rsync -a --exclude '.config/pulse/' --exclude '.config/btop/btop.log' \
     --exclude '.config/fish/fish_variables' --exclude '.config/systemd/' \
     --exclude '.config/autostart/amazon-q.desktop' \
     hyprland/home/ ~/
   chmod +x ~/.local/bin/* ~/.config/hypr/scripts/* ~/.config/hypr/custom/scripts/* 2>/dev/null
   fc-cache -fv
   ```

   `~/.fonts` and `~/.icons` are still read by fontconfig and GTK. Moving them to `~/.local/share/fonts` and `~/.local/share/icons` is optional.

4. **Displays.** Edit `~/.config/kanshi/config` for your outputs. kanshi starts from `~/.config/autostart/kanshi.desktop`.
5. **Shell.** `chsh -s "$(which zsh)"`, or keep Fish.
6. Log out, pick the Hyprland session, and press `Super + /` for the keybinding cheat sheet.

## Keybindings

`Super` is the main modifier. These are the most useful binds from `hyprland/keybinds.conf` and `custom/keybinds.conf`; press `Super + /` for the full list.

| Keys | Action |
|---|---|
| Super (tap) | Search / launcher (Quickshell) |
| Super + Return / Super + T | Terminal (`$TERMINAL`, falls back to kitty) |
| Super + Shift + Return | Dropdown terminal |
| Super + E | File manager |
| Super + C | Code editor |
| Super + Q | Close window |
| Super + Shift + Q | Kill the active process |
| Super + Arrows | Move focus |
| Super + Ctrl + Arrows | Move window |
| Super + Alt + Arrows | Swap window |
| Super + Shift + Arrows | Resize window |
| Super + Space | Toggle floating |
| Super + Shift + F / Super + Ctrl + F | Fullscreen / fake fullscreen |
| Super + Alt + L | Toggle master / dwindle layout |
| Super + 1-0 / Super + Shift + 1-0 | Go to / send window to workspace |
| Super + Tab | Overview |
| Super + V / Super + . | Clipboard history / emoji picker |
| Super + Shift + S | Region screenshot |
| Super + Shift + X | OCR a region to the clipboard |
| Super + Shift + C | Color picker |
| Super + Shift + R | Record a region |
| Super + W | Wallpaper selector |
| Super + A / Super + N | Left / right sidebar |
| Super + L | Lock |
| Super + / or Super + H | Cheat sheet |
| Super + Alt + R | Restart Quickshell |
| Ctrl + Alt + Delete | Session menu |

## Gotchas

- **Case-colliding icon files.** `.icons/` contains about 1,300 paths that differ only in letter case. Clone and deploy on a case-sensitive filesystem (Linux). A clone on macOS shows about 200 icon files as modified or typechanged. Never commit those.
- **Absolute symlinks.** These only resolve for user `somchandra` with the same files present:

  | Link | Target |
  |---|---|
  | `.config/waybar/config` | `/home/somchandra/.config/waybar/configs/[TOP] Default Laptop` |
  | `.config/waybar/style.css` | `/home/somchandra/.config/waybar/style/[Light] Monochrome Contrast.css` |
  | `.config/rofi/.current_wallpaper` | `/home/somchandra/Pictures/wallpapers/Retro - Programmer.jpeg` (wallpapers are not in the repo) |
  | `.config/autostart/amazon-q.desktop` | `/usr/share/applications/amazon-q.desktop` |
  | `.config/systemd/user/*.wants/snap.*` | `/etc/xdg/systemd/user/snap.*` (Ubuntu snapd units) |

  Re-point the Waybar links with `ln -sf` after copying.
- **Machine-specific files** (excluded in the install command above): `.config/pulse/cookie` (PulseAudio auth cookie), `.config/btop/btop.log`, `.config/fish/fish_variables`, the snap systemd units and `amazon-q.desktop`. `kanshi/config` is tuned to this laptop's panel.
- **Not in the repo:** the Quickshell `ii` config (from dots-hyprland), `~/.config/illogical-impulse/config.json` (opened by `Ctrl + Super + /`), wallpapers (`~/Pictures/wallpapers`), and `.gitconfig`.
- **Known bind bug:** in `custom/keybinds.conf`, `Super + Shift + Down` resizes by `0 -50`, the same as Up. It should be `0 50`.
