# Terminal Cheatsheet

> Ghostty / Kitty + ZSH + Starship + TokyoNight — Quick Reference

---

## Setup Overview

| Component | Choice |
|-----------|--------|
| Terminals | Ghostty, Kitty |
| Shell | ZSH |
| Prompt | Starship |
| Theme | TokyoNight Night |
| Font | RobotoMono Nerd Font (15pt) |
| Completions | fzf-tab + zsh-completions + brew completions |
| History | Atuin (fuzzy, cross-session) |
| Suggestions | zsh-autosuggestions (inline, fish-style) |
| Highlighting | zsh-syntax-highlighting (TokyoNight palette) |
| File listing | eza (icons, git status) |
| File viewer | bat (syntax highlighting) |
| Navigation | zoxide (smart cd) |
| File search | fzf + fd |
| Typo fixer | thefuck |

### Quick Install (fresh Mac)

```bash
brew install starship zoxide eza bat fzf fd thefuck ripgrep \
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions \
  atuin fastfetch btop tldr jq neovim
brew install --cask font-roboto-mono-nerd-font ghostty kitty
git clone --depth 1 https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
brew completions link
```

---

## Kitty Keybinds

### Tabs

| Key | Action |
|-----|--------|
| `Cmd + T` | New tab (inherits cwd) |
| `Cmd + W` | Close tab |
| `Cmd + Shift + ]` | Next tab |
| `Cmd + Shift + [` | Previous tab |
| `Cmd + 1-9` | Jump to tab 1–9 |

### Splits (Windows)

| Key | Action |
|-----|--------|
| `Cmd + D` | Split vertical (side by side) |
| `Cmd + Shift + D` | Split horizontal (stacked) |
| `Cmd + Shift + Enter` | New OS window (inherits cwd) |
| `Cmd + Option + Arrow` | Navigate between splits |
| `Cmd + Ctrl + Arrow` | Resize split |
| `Cmd + Enter` | Toggle zoom (stack layout) |

### Text & Scrolling

| Key | Action |
|-----|--------|
| `Cmd + C` | Copy |
| `Cmd + V` | Paste |
| `Cmd + K` | Clear screen to cursor |
| `Cmd + +` | Increase font size |
| `Cmd + -` | Decrease font size |
| `Cmd + 0` | Reset font size |
| `Cmd + Up` | Scroll to top |
| `Cmd + Down` | Scroll to bottom |

### Config

| Key | Action |
|-----|--------|
| `Cmd + Shift + ,` | Reload config |

---

## Ghostty Keybinds

### Window Management

| Key | Action |
|-----|--------|
| `Cmd + N` | New window |
| `Cmd + Shift + Enter` | New window (custom) |
| `Cmd + T` | New tab |
| `Cmd + W` | Close tab / pane |
| `Cmd + Shift + W` | Close window |
| `Cmd + Q` | Quit Ghostty |
| `Cmd + 1-9` | Switch to tab 1–9 |
| `Cmd + Shift + [` | Previous tab |
| `Cmd + Shift + ]` | Next tab |

### Splits

| Key | Action |
|-----|--------|
| `Cmd + D` | Split right (vertical) |
| `Cmd + Shift + D` | Split down (horizontal) |
| `Cmd + Option + Arrow` | Navigate between splits |
| `Cmd + Ctrl + Arrow` | Resize split |
| `Cmd + Enter` | Toggle split zoom |

### Text & Scrolling

| Key | Action |
|-----|--------|
| `Cmd + C` | Copy |
| `Cmd + V` | Paste |
| `Cmd + K` | Clear screen |
| `Cmd + +` | Increase font size |
| `Cmd + -` | Decrease font size |
| `Cmd + 0` | Reset font size |
| `Cmd + Up` | Scroll to top |
| `Cmd + Down` | Scroll to bottom |
| `Page Up / Down` | Scroll page up / down |
| `Shift + Scroll` | Scroll by line |

### Custom (from config)

| Key | Action |
|-----|--------|
| `Cmd + Shift + ,` | Reload config |
| `Cmd + Shift + I` | Toggle inspector |

---

## ZSH Line Editing

### Cursor Movement

| Key | Action |
|-----|--------|
| `Ctrl + A` | Jump to start of line |
| `Ctrl + E` | Jump to end of line |
| `Ctrl + F` or `Right` | Move forward one char |
| `Ctrl + B` or `Left` | Move back one char |
| `Option + F` | Move forward one word |
| `Option + B` | Move back one word |
| `Ctrl + Right` | Move forward one word (alt) |
| `Ctrl + Left` | Move back one word (alt) |

### Editing

| Key | Action |
|-----|--------|
| `Ctrl + W` | Delete word backward |
| `Option + D` | Delete word forward |
| `Ctrl + U` | Delete from cursor to start of line |
| `Ctrl + K` | Delete from cursor to end of line |
| `Ctrl + Y` | Paste (yank) last deleted text |
| `Ctrl + _` | Undo last edit |
| `Delete` | Delete char under cursor |
| `Backspace` | Delete char before cursor |

### History

| Key | Action |
|-----|--------|
| `Up` | Search history backward (prefix match) |
| `Down` | Search history forward (prefix match) |
| `Ctrl + R` | **Atuin** fuzzy history search |
| `Ctrl + P` | Previous command |
| `Ctrl + N` | Next command |

---

## fzf — Fuzzy Finder

### Global Triggers

| Key | Action |
|-----|--------|
| `Ctrl + T` | Find files in current dir (inserts path) |
| `Option + C` | Find and cd into directory |
| `Ctrl + R` | Fuzzy history (overridden by Atuin) |

### Inside fzf Popup

| Key | Action |
|-----|--------|
| `↑ / ↓` | Navigate results |
| `Tab` | Select/deselect (multi-select mode) |
| `Shift + Tab` | Deselect |
| `Enter` | Confirm selection |
| `Ctrl + Y` | Accept selection |
| `Ctrl + U` | Preview scroll up |
| `Ctrl + D` | Preview scroll down |
| `Esc` | Cancel |

---

## fzf-tab — Fuzzy Tab Completion

| Key | Action |
|-----|--------|
| `Tab` | Open fuzzy completion popup |
| `↑ / ↓` | Navigate completions |
| `Enter` | Accept completion |
| `/` | Accept and continue (for paths) |
| `<` / `>` | Switch completion group |
| `Esc` | Cancel completion |

> Previews are automatic: directories show `eza` listing, files show `bat` syntax-highlighted content, git commands show diffs/logs, `kill` shows process info, `brew install` shows package info.

---

## Atuin — Shell History

| Key | Action |
|-----|--------|
| `Ctrl + R` | Open Atuin search |
| Inside Atuin: | |
| `↑ / ↓` | Navigate results |
| `Tab` | Select result (don't run) |
| `Enter` | Run selected command |
| `Ctrl + D` | Delete entry from history |
| `Esc` | Close search |

---

## Aliases — Quick Reference

### Navigation

| Alias | Expands To |
|-------|-----------|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `.....` | `cd ../../../..` |
| `c` | `clear` |
| `claer` | `clear` (typo-proof) |
| `d` | `dirs -v` (numbered dir stack) |
| `1`–`9` | `cd +N` (jump to dir stack entry) |

### Files & Listing (eza)

| Alias | What it does |
|-------|-------------|
| `ls` | List with icons, dirs first |
| `ll` | Long list, all files, git status |
| `la` | List all including hidden |
| `l` | List with classifiers |
| `lt` | Long list, sorted by modified time |
| `lsize` | Long list, sorted by size |
| `tree` | Tree view (3 levels) |
| `treea` | Tree view with hidden files |
| `cat` | Syntax-highlighted view (bat) |
| `catn` | Same but with line numbers |
| `catt` | Original `/bin/cat` |

### Git

| Alias | Expands To |
|-------|-----------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git log --oneline --graph --all` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `gf` | `git fetch --all --prune` |
| `grc` | `git rebase --continue` |
| `gra` | `git rebase --abort` |
| `gwip` | Stage all + commit "wip" |

### Docker

| Alias | Expands To |
|-------|-----------|
| `dk` | `docker` |
| `dc` | `docker-compose` |
| `dps` | `docker ps` |
| `dimg` | `docker images` |
| `dprune` | `docker system prune -af` |
| `dlogs` | `docker logs -f` |

### Kubernetes

| Alias | Expands To |
|-------|-----------|
| `k` | `kubectl` |
| `kgp` | `kubectl get pods` |
| `kgs` | `kubectl get services` |
| `kgd` | `kubectl get deployments` |

### Python

| Alias | Expands To |
|-------|-----------|
| `py` | `python3` |
| `pip` | `python3 -m pip` |
| `venv` | `python3 -m venv` |
| `activate` | `source venv/bin/activate` |

### macOS

| Alias | What it does |
|-------|-------------|
| `copy` | Copy stdin to clipboard (`pbcopy`) |
| `paste` | Paste from clipboard (`pbpaste`) |
| `sleepnow` | Put Mac to sleep |
| `lock` | Lock screen |
| `show` / `hide` | Toggle hidden files in Finder |
| `finder` | Open Finder here |
| `myip` | Show public IP |
| `localip` | Show local IP |
| `ports` | List listening ports |
| `flushdns` | Flush DNS cache |

### Homebrew

| Alias | What it does |
|-------|-------------|
| `brewup` | Update + upgrade + cleanup |
| `brewlist` | List installed packages |
| `brewinfo` | Show package info |

### Other

| Alias | What it does |
|-------|-------------|
| `zshrc` | Edit `~/.zshrc` in nvim |
| `reload` | Restart shell (`exec zsh`) |
| `fuck` | Fix last mistyped command (thefuck) |
| `rga` | ripgrep including hidden/ignored files |
| `serve` | Start HTTP server (`python3 -m http.server`) |
| `mobsf` | Run MobSF in Docker |

### Android (if SDK installed)

| Alias | What it does |
|-------|-------------|
| `emulateroot` | Pixel 6a API 29 (writable system) |
| `emulateburp` | Pixel 4a API 33 (writable system) |

---

## Functions

| Function | Usage | What it does |
|----------|-------|-------------|
| `mkcd` | `mkcd mydir` | Create dir and cd into it |
| `extract` | `extract file.tar.gz` | Extract any archive format |
| `fcd` | `fcd` | Fuzzy-find and cd into a directory |
| `fe` | `fe` | Fuzzy-find and open file in editor |
| `gcm` | `gcm fix bug` | Stage all + commit with message |
| `psgrep` | `psgrep node` | Find process by name |
| `killp` | `killp node` | Kill process by name |
| `backup` | `backup file.txt` | Copy file with timestamp suffix |
| `weather` | `weather tokyo` | Show weather for a city |
| `topcpu` | `topcpu 5` | Top N processes by CPU |
| `topmem` | `topmem 5` | Top N processes by memory |
| `whoisport` | `whoisport 3000` | Who's listening on port |

---

## Config File Locations

| File | Purpose |
|------|---------|
| `~/.zshrc` | Shell configuration |
| `~/.config/ghostty/config` | Ghostty terminal config |
| `~/.config/kitty/kitty.conf` | Kitty terminal config |
| `~/.config/kitty/tokyonight_night.conf` | Kitty color theme |
| `~/.config/starship.toml` | Starship prompt theme |
| `~/.config/fastfetch/config.jsonc` | Fastfetch system info |
| `~/.config/atuin/config.toml` | Atuin history config |
| `~/.config/bat/themes/` | Bat color themes |

---

*Open this file anytime: `cat ~/terminal-cheatsheet.md`*
