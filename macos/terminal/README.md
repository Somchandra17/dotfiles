# macOS Terminal

My macOS terminal setup: Ghostty or Kitty running Zsh with a Starship prompt, themed TokyoNight Night throughout, with Atuin for history and Ranger as the file manager. `home/` mirrors `$HOME`, so every file sits at the path it should have under `~` and deploying is one copy. The `.zshrc` has no framework (no Oh My Zsh). It sources Homebrew-installed plugins directly and caches `brew shellenv` and the zoxide, fzf, atuin and starship init scripts to keep startup fast.

For keybindings, aliases and functions, see [terminal-cheatsheet.md](terminal-cheatsheet.md). The window manager setup is in [../paneru/README.md](../paneru/README.md).

## Components

| Component | File(s) under `home/` | Notes |
|---|---|---|
| Zsh | `.zshrc` | Completions, fzf-tab, aliases, functions, plugin loading |
| Ghostty | `.config/ghostty/config` | Uses Ghostty's built-in `TokyoNight Night` theme |
| Kitty | `.config/kitty/kitty.conf`, `.config/kitty/tokyonight_night.conf` | `kitty.conf` includes the theme file |
| Starship | `.config/starship.toml` | Two-line prompt, `tokyonight` palette |
| Atuin | `.config/atuin/config.toml` | Local only (`auto_sync = false`), fuzzy search, bound to `Ctrl+R` |
| Ranger | `.config/ranger/rc.conf`, `.config/ranger/scope.sh`, `.config/ranger/colorschemes/tokyonight.py` | `scope.sh` must stay executable |
| Fastfetch | `.config/fastfetch/config.jsonc` | The startup splash is commented out in `.zshrc`, so run `fastfetch` yourself |

The config uses these, but they are not in this folder:

- fzf-tab plugin at `~/.zsh/fzf-tab` (cloned, see below)
- bat theme at `~/.config/bat/themes/tokyonight_night.tmTheme` (downloaded, see below)

## Prerequisites

- macOS with the Xcode Command Line Tools (`xcode-select --install`), which provide `git`.
- [Homebrew](https://brew.sh). `.zshrc` finds it at `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel).

### Packages

```bash
brew install starship zoxide eza bat fzf fd ripgrep thefuck atuin neovim ranger \
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions \
  fastfetch btop tldr jq
brew install --cask ghostty kitty font-roboto-mono-nerd-font
git clone --depth 1 https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
brew completions link
```

This is the cheatsheet's Quick Install line plus `ranger`, which the `r` alias and the Ranger configs need.

### bat theme

`BAT_THEME`, `PAGER`, `MANPAGER`, the `cat` alias and Kitty's scrollback pager all use the `tokyonight_night` bat theme:

```bash
mkdir -p ~/.config/bat/themes
curl -fsSL -o ~/.config/bat/themes/tokyonight_night.tmTheme \
  https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
bat cache --build
```

### Font

The `font-roboto-mono-nerd-font` cask above installs RobotoMono Nerd Font. Ghostty and Kitty already use it at 15pt. Without a Nerd Font, Starship, eza and fastfetch icons show up as empty boxes.

### Optional

| Tool | Used by | Install |
|---|---|---|
| p7zip, zstd | `extract` for `.7z` / `.zst` | `brew install p7zip zstd` |
| unrar | `extract` for `.rar` | Not in homebrew-core any more. `brew install --cask rar` ships an `unrar` binary |
| Docker, kubectl | `dk`, `dcp`, `dps`, `k`, `kgp`, ... aliases | Docker Desktop or OrbStack, `brew install kubectl` |
| Android SDK | `ANDROID_HOME`, `emulateroot`, `emulateburp` | Android Studio, SDK at `~/Library/Android/sdk` |
| go-ip-color | `ip` alias | Not in Homebrew. The alias is set only if it is on `PATH` |
| Pillow | Ranger image previews | Must be importable by Ranger's Python |

## Install

Run from the repo:

```bash
cd <path-to>/hyperland-dotfiles/macos/terminal

# 1. Back up every file that will be overwritten, as <file>.bak-<timestamp>
ts=$(date +%Y%m%d-%H%M%S)
(cd home && find . -type f) | while IFS= read -r f; do
  f=${f#./}
  [ -e "$HOME/$f" ] && command cp -p "$HOME/$f" "$HOME/$f.bak-$ts" && echo "backed up ~/$f"
done

# 2. Copy. `command cp` skips the `cp -i` alias if this .zshrc is already loaded
command cp -R home/. ~/
chmod +x ~/.config/ranger/scope.sh

# 3. Optional: the `ghostyhelp` alias opens ~/terminal-cheatsheet.md
[ -e ~/terminal-cheatsheet.md ] && command cp -p ~/terminal-cheatsheet.md ~/terminal-cheatsheet.md.bak-$ts
command cp terminal-cheatsheet.md ~/

# 4. Start a fresh shell
exec zsh
```

`cp -R home/. ~/` merges into the existing `~/.config` and leaves files that are not in `home/` alone.

### First run

1. The first `exec zsh` is slower than later starts. It writes `~/.zsh/brew_env.zsh`, `~/.zsh/init_cache/{zoxide,fzf,atuin,starship}.zsh` and `~/.zcompdump`.
2. Import your existing history into Atuin:

   ```bash
   atuin import auto
   ```

3. Restart Ghostty or Kitty, or reload the config with `Cmd+Shift+,`, so the font and theme apply. In Terminal.app or iTerm2, choose "RobotoMono Nerd Font" in the profile settings yourself.
4. macOS has used zsh as the default shell since Catalina. If `echo $SHELL` shows something else, run `chsh -s /bin/zsh`.

## Post-install checks

```zsh
# Homebrew prefix resolved (expect /opt/homebrew on Apple Silicon)
echo $HOMEBREW_PREFIX

# Required tools on PATH. Prints only what is missing
for t in starship zoxide eza bat fzf fd rg atuin thefuck nvim ranger fastfetch; do
  (( $+commands[$t] )) || echo "missing: $t"
done

# Plugins loaded. Each should report "function"
whence -w fzf-tab-complete _zsh_autosuggest_start _zsh_highlight

# Init caches generated (atuin.zsh fzf.zsh starship.zsh zoxide.zsh)
ls ~/.zsh/init_cache

# Theme and font
bat --list-themes | grep tokyonight_night
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-themes --plain | grep 'TokyoNight Night'
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
ls ~/Library/Fonts | grep -i robotomono

# Startup time
time zsh -i -c exit
```

By hand: open a new terminal window. You should see a two-line Starship prompt, `Tab` should open the fzf completion popup with previews, `Ctrl+R` should open Atuin, and `ls` should show icons.

## Gotchas

- **Homebrew prefix.** Homebrew itself is found at `/opt/homebrew` or `/usr/local`. The `source` lines for zsh-autosuggestions and zsh-syntax-highlighting are hardcoded to those same two prefixes instead of using `$HOMEBREW_PREFIX`, so with a custom prefix both plugins are silently skipped.
- **Stale caches.** `~/.zsh/brew_env.zsh` and `~/.zsh/init_cache/*.zsh` are only regenerated when the tool binary is newer than the cache. Delete them after moving Homebrew (for example, migrating from Intel to Apple Silicon) or after changing init flags in `.zshrc`:

  ```bash
  rm -rf ~/.zsh/brew_env.zsh ~/.zsh/init_cache && exec zsh
  ```

- **No hardcoded username.** Every path uses `$HOME` or `~`, so the files work under any account.
- **Machine-specific entries.** Each of these is guarded and does nothing if the target is missing:
  - Kiro CLI pre/post hooks at the very top and bottom of `.zshrc` (`~/Library/Application Support/kiro-cli/shell/`). Keep them first and last when you edit the file.
  - `PATH` entries for `~/bin`, `~/.local/bin`, `~/go/bin`, `~/.opencode/bin`, and `~/.cargo/env`.
  - Android aliases with hardcoded AVD names `Pixel_6a_API_29` and `Pixel_4a_API_33`.
  - The oh-my-posh fallback, used only if Starship is missing. It expects `~/.config/oh-my-posh/themes/amro.omp.json`, which is not in this repo.
- **Missing tools fail silently.** Almost every integration is wrapped in `(( $+commands[tool] ))`. If a tool is missing, its feature just disappears: plain `ls` instead of eza, a basic prompt instead of Starship. Use the check loop above.
- **Core commands are aliased.** `cd` runs `z` (zoxide), `cat` runs `bat`, `ls` runs `eza`, and `rm`, `cp` and `mv` run with `-i`. For the originals, use `command cp`, `\cd`, or `catt` (`/bin/cat`). `LC_ALL` is forced to `en_US.UTF-8`.
- **Missing bat theme.** If the theme is not installed, bat warns about an unknown theme and falls back to its default colors.
- **Ranger image previews.** Ranger is set to `preview_images_method kitty`, which needs Pillow and a terminal that supports the Kitty graphics protocol. Previews work in Kitty. If they don't render elsewhere, press `zi` in Ranger to toggle them off.
- **Ghostty theme names** have changed between releases. If the theme does not apply, check the exact name with `+list-themes`.
- **macOS only.** `.zshrc` uses BSD `stat -f`, `pbcopy`, `pmset`, `defaults` and `system_profiler`. The Linux setup lives under `hyprland/`.
- **Local overrides.** Put machine-specific settings and secrets in `~/.zshrc.local`, which is sourced near the end and not tracked here, rather than editing `.zshrc`. `~/.bash_aliases` is also sourced if it exists.
