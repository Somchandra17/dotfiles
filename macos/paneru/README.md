# Paneru (macOS tiling window manager)

A niri/Hyprland-style setup for [Paneru](https://github.com/karinushka/paneru), a sliding, scrollable tiling window manager for macOS, plus [JankyBorders](https://github.com/FelixKratz/JankyBorders) for the active-window outline.

Built and tested on a MacBook Pro (M4 Pro, built-in keyboard, ProMotion display), macOS 27, Paneru 0.5.1, borders 1.9.0.

## Contents

Everything under `home/` mirrors `$HOME`.

| File | Purpose |
|---|---|
| `home/.config/paneru/paneru.toml` | Paneru config: options, keybindings, gestures, window rules |
| `home/.config/paneru/cheatsheet.html` | Keybinding cheat sheet (opens at login and via `paneru-help`) |
| `home/.config/borders/bordersrc` | Active-window border: blue `0xff0a84ff`, 6px, rounded |
| `home/Library/LaunchAgents/com.somchandra.paneru-cheatsheet.plist` | Opens the cheat sheet 5 s after login |
| `install.sh` | Idempotent installer (packages, configs, services, alias) |

## Install

```bash
cd macos/paneru
./install.sh
```

The script installs `paneru` and `felixkratz/formulae/borders` with Homebrew, backs up anything it replaces as `<file>.bak-<timestamp>`, copies the files, adds a `paneru-help` alias to `~/.zshrc`, and starts the services. It is safe to re-run.

Then do the manual steps it prints. **Steps 2 and 3 are required for the fn bindings.**

1. **Accessibility**: System Settings > Privacy & Security > Accessibility > enable `paneru`.
2. **Globe key as Control**: System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys > *Apple Internal Keyboard* > Globe key = `^ Control`.
3. **Free up Control shortcuts**: Keyboard Shortcuts > Mission Control > turn off *Move left a space*, *Move right a space*, *Switch to Desktop 1-3*.
4. **Trackpad**: Trackpad > More Gestures > set *Swipe between full-screen applications* and *Mission Control* to four fingers (Paneru owns three-finger swipes).
5. Optional: Keyboard > *Press Globe key to* > Do Nothing.

## How the fn key works (read this before changing bindings)

The goal is a niri-style `Mod` key on the fn/Globe key. Paneru's own `fn` modifier is unreliable: it only matches when the event flags equal exactly `0x800100`, and fn combined with any other modifier is never seen.

Instead, macOS remaps Globe to Control (step 2 above). The built-in keyboard then reports fn as **right Control**, a key a MacBook does not physically have. So in `paneru.toml`:

- `rctrl` = the fn key. All "Mod" bindings use `rctrl`.
- Backup bindings use `lctrl` (the physical Control key), never plain `ctrl`, so the two sets cannot overlap.
- fn + Control cannot be bound: it produces both Control bits, which Paneru cannot tell apart from fn alone.
- fn + an unbound key still acts as Control in apps.

An external keyboard may report the remapped Globe key as left Control, or not send fn to macOS at all. In that case only the `lctrl + alt` backup bindings work.

## Keybindings

`fn` is Mod. The backup column uses the physical Control key.

| Keys | Action | Backup |
|---|---|---|
| fn + ← / → | Focus window left / right | ⌃⌥ + , / . |
| fn + ↑ / ↓ | Focus up / down in a stack, then switch row | ⌃⌥ + ↑ / ↓ |
| fn + ⌥ + ← / → | Jump to first / last window | |
| fn + 1 / 2 / 3 | Go to row (virtual workspace) 1-3 | ⌃⌥ + 1-3 |
| fn + ⇧ + 1 / 2 / 3 | Move window to row 1-3 | ⌃⌥⇧ + 1-3 |
| fn + ⇧ + ↑ / ↓ | Move window to row above / below | ⌃⌥⇧ + ↑ / ↓ |
| fn + ⇧ + ← / → | Move window left / right | ⌘⌃⌥ + , / . |
| fn + ⌥ + ↑ / ↓ | Move window up / down within a stack | ⌘⌃⌥ + ↑ / ↓ |
| fn + ⌥ + ⇧ + ← / → | Move window to first / last position | |
| fn + ⌘ + ← / → | Narrower / wider (presets 50-100%) | ⌃⌥ + [ / ] |
| fn + - / = | Narrower / wider | |
| fn + ⌘ + ↑ / ↓ | Taller / shorter (inside a stack) | |
| fn + F or fn + ⇧ + F | Toggle full width | ⌃⌥ + ' |
| fn + C | Center window | ⌃⌥ + C |
| fn + B | Balance: all columns match the focused width | ⌃⌥ + B |
| fn + , / . | Stack into left column / unstack | ⌃⌥ + S / U |
| fn + E | Equalize heights in a stack | ⌃⌥ + E |
| fn + Space | Toggle tiled / floating | ⌃⌥ + ; |
| | Quit Paneru | ⌃⌥ + Q |

Trackpad and mouse: three-finger swipe left/right slides the strip, up/down switches rows; ⌥ + scroll slides windows, ⌥⌘ + scroll switches rows.

## Notable settings

| Setting | Value | Why |
|---|---|---|
| `animation_speed` | 22 | Exponential ease-out; about 0.26 s per slide. Higher is snappier. |
| `virtual_workspace_animations` | true | Animated row switching, niri-style |
| `create_virtual_workspace_automatically` / `reap_empty_workspaces` | true / true | Rows appear when you move past the last one and vanish when empty |
| `auto_center` | false | Lets two 50% windows sit side by side; center manually with fn + C |
| `continuous` | true | The strip can scroll past the first and last window |
| `[swipe]` sensitivity / deceleration | 0.2 / 2.0 | Fine-grained swipes with a long glide |
| `[swipe.gesture]` fingers_count | 3 | Requires macOS gestures moved to four fingers |
| `[windows.all]` width | 0.5 | New windows open at half width |

## Known limits

- **Frame rate**: Paneru 0.5.1 paces animations with a 16 ms timeout (about 60 fps) regardless of display refresh rate. Display-synced pacing (120/144 Hz) is in open upstream PR [#311](https://github.com/karinushka/paneru/pull/311), stacked on #308 and #307. It arrives with a normal `brew upgrade paneru` once merged and released.
- The Finder "Get Info" float rule matches the Turkish title `Bilgisi` (inherited from the dotfiles this config started from). On an English system those windows tile.

## Troubleshooting

| Symptom | Check |
|---|---|
| Nothing responds | `pgrep -fl paneru`; Accessibility permission; `paneru restart` |
| Config edits ignored | A Lua config (`~/.config/paneru/init.lua`, `~/.paneru.lua`) silently replaces the TOML. `install.sh` moves these aside. |
| fn bindings dead, ⌃⌥ backups work | Modifier Keys > Globe must be `^ Control` for *Apple Internal Keyboard* |
| fn + ← / → switches Spaces | Disable the Mission Control shortcuts (install step 3) |
| Config errors | Log: `/tmp/com.github.karinushka.paneru_$(id -u).err.log`. Each restart logs one `bind: Keybinding` line per binding (60 expected). |
| `brew install` refuses borders | `brew trust --formula felixkratz/formulae/borders` |

## Updating this backup

After changing the live config, copy it back into the repo:

```bash
cd macos/paneru/home
for f in .config/paneru/paneru.toml .config/paneru/cheatsheet.html .config/borders/bordersrc \
         Library/LaunchAgents/com.somchandra.paneru-cheatsheet.plist; do cp ~/"$f" "$f"; done
```
