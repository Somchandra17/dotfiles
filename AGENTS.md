# Agent manual

Instructions for AI agents (Claude Code, Codex, Cursor, etc.) deploying or updating these dotfiles. Read this file completely before touching the user's machine. Then read the README of the part you are deploying.

## 1. Repo map

| Part | Target | Files | Installer | Docs |
|---|---|---|---|---|
| Hyprland desktop | Linux (Wayland, Hyprland) | `hyprland/home/` mirrors `$HOME`; `hyprland/packages/*.txt` | none (manual copy) | `hyprland/README.md` |
| macOS terminal | macOS (Apple Silicon) | `macos/terminal/home/` mirrors `$HOME` | none (manual copy) | `macos/terminal/README.md` |
| Paneru WM | macOS (Apple Silicon, built-in keyboard) | `macos/paneru/home/` mirrors `$HOME` | `macos/paneru/install.sh` | `macos/paneru/README.md` |

Every `home/` folder is a literal mirror: `X/home/.config/foo` is deployed to `~/.config/foo`.

## 2. Rules

1. **Detect the OS first** (`uname -s`). Deploy only the parts that match. Hyprland files never go on a Mac, and macOS files never go on Linux.
2. **Ask before:** installing packages, changing System Settings or `defaults`, enabling login items or services, and changing the login shell. Tell the user exactly what will change.
3. **Back up before overwriting.** Move existing files to `<path>.bak-<YYYYmmdd-HHMMSS>`, or copy them if they are directories you merge into. Never delete a user's config.
4. **Copy, don't symlink**, unless the user asks for stow or symlinks. Copying keeps the repo clone disposable.
5. **Don't deploy machine-specific files blindly.** The Hyprland part contains display layouts, logs, audio cookies and absolute symlinks into `/home/somchandra` (listed in `hyprland/README.md`). Skip them or confirm each with the user.
6. **Verify after deploying** with the checks in section 4. Don't claim success on file copies alone.
7. **GUI steps belong to the user.** Some steps exist only in System Settings (Accessibility, Modifier Keys). Give the user exact click paths, then verify the result from the shell where possible (section 4).
8. **Read every script before running it**, including this repo's `install.sh`.

## 3. Deploy procedures

### macOS terminal

```bash
cd macos/terminal
# follow README.md: brew dependencies, then:
TS=$(date +%Y%m%d-%H%M%S)
for f in $(cd home && find . -type f | sed 's|^\./||'); do
  [ -e ~/"$f" ] && cp -p ~/"$f" ~/"$f.bak-$TS"
  mkdir -p ~/"$(dirname "$f")" && cp home/"$f" ~/"$f"
done
exec zsh
```

### Paneru (macOS)

```bash
cd macos/paneru && ./install.sh
```

The installer is idempotent. It installs `paneru` and `borders`, moves aside Lua configs that would override `paneru.toml`, copies the files, adds the `paneru-help` alias and starts the services. Afterwards, walk the user through the five manual steps it prints. The fn bindings **do not work** without the Modifier Keys step (Globe = Control).

### Hyprland (Linux)

Follow `hyprland/README.md`. Clone on Linux, not on a Mac (see section 6).

## 4. Verification

### Paneru

```bash
pgrep -fl paneru                     # service running
L=/tmp/com.github.karinushka.paneru_$(id -u).err.log
S=$(grep -n 'is the active configuration' "$L" | tail -1 | cut -d: -f1)
tail -n +"$S" "$L" | grep -c 'bind: Keybinding'   # expect 60
tail -n +"$S" "$L" | grep ' ERROR ' || echo ok    # expect ok
brew services list | grep borders    # started
```

Check that Globe is mapped to Control on the built-in keyboard. Expect a mapping whose Src is `1095216660483` (`0xFF00000003`, Globe) and Dst is `30064771300` (`0x7000000E4`, right Control):

```bash
defaults -currentHost read -g | grep -B1 'HIDKeyboardModifierMappingSrc = 1095216660483;'
# expect the line above it to be: HIDKeyboardModifierMappingDst = 30064771300;
```

Check that the conflicting Mission Control shortcuts are off. IDs 79 and 81 are *Move left/right a space*; 118-120 are *Switch to Desktop 1-3*; each should show `enabled = 0`:

```bash
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys | grep -A1 -E '^ +(79|81|118|119|120) ='
```

Finally, ask the user to press fn + ← and fn + 1 and confirm that focus and rows change.

### Terminal

Run `exec zsh` with no errors; the Starship prompt renders; `z`, `eza`, `bat` and `atuin` resolve with `command -v`.

## 5. Paneru facts that are easy to get wrong

- **A Lua config replaces the TOML.** If `~/.config/paneru/init.lua`, `~/.paneru.lua` or `$PANERU_LUA` exists, `paneru.toml` is never read, and nothing warns you. Paneru creates a commented-out `init.lua` on first launch.
- **Paneru's `fn` modifier is unreliable.** It matches only when the event flags equal exactly `0x800100`, and fn + any other modifier is invisible. This setup therefore remaps Globe to Control in macOS, and the built-in keyboard reports that as right Control. All Mod bindings use `rctrl`.
- **Modifier matching:** `ctrl` matches either side, `lctrl` and `rctrl` match one side, and extra bits are rejected. `lctrl + rctrl` cannot be told apart from either key alone, so fn + Control combos cannot be bound. Backups must use `lctrl`, never `ctrl`, or they collide with the `rctrl` set.
- **Key names:** use `leftarrow`, `rightarrow`, `uparrow`, `downarrow`, `space`, `equal`, `minus`; `,` and `.` work literally. A binding value can be an array of chords.
- **Hot reload exists but isn't reliable.** Run `paneru restart` after editing and check the log.
- **Homebrew tap trust:** newer Homebrew refuses `felixkratz/formulae/borders` until you run `brew trust --formula felixkratz/formulae/borders`.
- **Animations** are capped at about 60 fps in 0.5.1 (16 ms timeout). Display-synced pacing is upstream PR #311. Don't patch or rebuild Paneru unless the user asks.

## 6. Git hygiene for this repo

- `hyprland/home/.icons/` has about 1,300 case-colliding paths. On macOS's case-insensitive filesystem, about 200 icon files show as modified or typechanged right after cloning. **Never stage or commit them.** Never run `git add -A`, `git add .`, `git commit -a`, `git checkout -- .` or `git restore .`; stage explicit paths only.
- Before committing, check that `git diff --cached --name-only` lists only files you meant to change.
- Commit messages are short, lowercase and imperative (see `git log`). Don't add AI attribution or `Co-Authored-By` trailers.
- To refresh a backup from a live machine, copy the live files over the matching `home/` paths. The command for Paneru is in `macos/paneru/README.md` under "Updating this backup". Review `git diff`, then stage those paths.
- Keep the docs in sync. If you change a binding in `paneru.toml`, update `cheatsheet.html` and `macos/paneru/README.md` in the same commit.
