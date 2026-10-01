
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# ── Performance Flags (must be set before Oh-My-Zsh / plugins) ───
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

# ╔══════════════════════════════════════════════════════════════════╗
# ║                        ZSH — macOS Rice                        ║
# ║         Ghostty · Starship · Catppuccin · Crazy Completions    ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Instant Prompt ────────────────────────────────────────────────
# Reduce perceived latency by deferring compinit

# ── Homebrew (cached — saves ~150ms per shell start) ──────────────
# Regenerates the cache only when the brew binary itself changes.
_brew_cache="${HOME}/.zsh/brew_env.zsh"
_brew_bin=""
if [[ -x /opt/homebrew/bin/brew ]]; then
    _brew_bin="/opt/homebrew/bin/brew"
elif [[ -x /usr/local/bin/brew ]]; then
    _brew_bin="/usr/local/bin/brew"
fi

if [[ -n "$_brew_bin" ]]; then
    if [[ ! -f "$_brew_cache" || "$_brew_bin" -nt "$_brew_cache" ]]; then
        mkdir -p "${HOME}/.zsh"
        "$_brew_bin" shellenv >| "$_brew_cache"
    fi
    source "$_brew_cache"
fi
unset _brew_cache _brew_bin

# ── PATH ──────────────────────────────────────────────────────────
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
export PATH="$HOME/.opencode/bin:$PATH"

if [[ -d "$HOME/Library/Android/sdk" ]]; then
    export ANDROID_HOME=$HOME/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools
fi

# Deduplicate PATH — prevents bloat across nested shells
typeset -U PATH

# ── History (massive, deduplicated) ───────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
# NOTE: HIST_IGNORE_ALL_DUPS is a superset of HIST_IGNORE_DUPS — only need one
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
# NOTE: SHARE_HISTORY already implies incremental appending — INC_APPEND_HISTORY removed
setopt SHARE_HISTORY

# ── Shell Options ─────────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt CORRECT
setopt CDABLE_VARS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt MULTIOS
setopt EXTENDED_GLOB
setopt GLOB_DOTS

# ── Environment ───────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='bat --style=plain --paging=auto'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
export GREP_COLORS='mt=1;32:fn=1;33:ln=1;36'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ── Completion Engine (before plugins!) ───────────────────────────
# Cache brew --prefix to avoid calling it twice (two fewer forks)
if (( $+commands[brew] )); then
    _brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    FPATH="${_brew_prefix}/share/zsh-completions:${_brew_prefix}/share/zsh/site-functions:$FPATH"
    unset _brew_prefix
fi

# Smarter completion initialization — only rebuild once per day
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

# Completion styling — the juicy part
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' verbose true
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format $'\e[1;38;2;122;162;247m→  %d\e[0m'
zstyle ':completion:*:messages' format $'\e[1;38;2;224;175;104m⚡ %d\e[0m'
zstyle ':completion:*:warnings' format $'\e[1;38;2;247;118;142m✗  No matches for: %d\e[0m'
zstyle ':completion:*:corrections' format $'\e[1;38;2;158;206;106m↻  %d (errors: %e)\e[0m'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' file-sort modification
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt GLOB_COMPLETE
setopt NO_MENU_COMPLETE
setopt FLOW_CONTROL
setopt LIST_PACKED

# Guard mkdir — don't run stat every shell start if dir already exists
[[ -d ~/.zsh/cache ]] || mkdir -p ~/.zsh/cache

# ── fzf-tab (MUST be loaded after compinit, before other plugins) ─
[[ -f ~/.zsh/fzf-tab/fzf-tab.plugin.zsh ]] && source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

# fzf-tab styling — fuzzy completion popups
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --style=numbers --color=always --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --style=numbers --color=always --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --style=numbers --color=always --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --style=numbers --color=always --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:export:*' fzf-preview 'echo $realpath'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word} 2>/dev/null'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | bat --style=numbers --color=always 2>/dev/null || echo $word'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --oneline --graph --color=always $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always $word 2>/dev/null'
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview 'brew info $word 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,command 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'

zstyle ':fzf-tab:*' fzf-flags \
    '--color=bg+:#292e42,bg:#1a1b26,spinner:#c0caf5,hl:#f7768e' \
    '--color=fg:#a9b1d6,header:#f7768e,info:#bb9af7,pointer:#7dcfff' \
    '--color=marker:#9ece6a,fg+:#c0caf5,prompt:#bb9af7,hl+:#f7768e' \
    '--color=border:#3b4261'
zstyle ':fzf-tab:*' fzf-min-height 20
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' continuous-trigger '/'

# ── Key Bindings ──────────────────────────────────────────────────
bindkey -e

WORDCHARS='*?_-[]~=&;!#$%^(){}<>'

bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char
bindkey '^W' backward-kill-word
bindkey '^[d' kill-word
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^Y' yank
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ══════════════════════════════════════════════════════════════════
# ║                           ALIASES                              ║
# ══════════════════════════════════════════════════════════════════

# ── Navigation ────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

# ── Grep ──────────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# ── Safety Nets ───────────────────────────────────────────────────
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ── Quick Edits ───────────────────────────────────────────────────
alias zshrc='${EDITOR} ~/.zshrc'
alias reload='exec zsh'

# ── System Info ───────────────────────────────────────────────────
alias sysinfo='system_profiler SPSoftwareDataType SPHardwareDataType'
alias cpu='sysctl -n machdep.cpu.brand_string'
alias mem='top -l 1 -s 0 | grep PhysMem'

# ── Python ────────────────────────────────────────────────────────
alias py='python3'
alias pip='python3 -m pip'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'
(( $+commands[go-ip-color] )) && alias ip='go-ip-color'

# ── Git ───────────────────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gb='git branch'
alias gf='git fetch --all --prune'
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias gwip='git add -A && git commit -m "wip"'

# ── Docker ────────────────────────────────────────────────────────
alias dk='docker'
alias dcp='docker-compose'
alias dps='docker ps'
alias dimg='docker images'
alias dprune='docker system prune -af'
alias dlogs='docker logs -f'

# ── Kubernetes ────────────────────────────────────────────────────
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'

# ── macOS ─────────────────────────────────────────────────────────
alias copy='pbcopy'
alias paste='pbpaste'
alias sleepnow='pmset sleepnow'
alias lock='pmset displaysleepnow'
alias show='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hide='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias finder='open -a Finder'

# ── Network ───────────────────────────────────────────────────────
alias myip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias ports='lsof -i -P | grep LISTEN'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# ── Homebrew ──────────────────────────────────────────────────────
alias brewup='brew update && brew upgrade && brew cleanup'
alias brewlist='brew list'
alias brewinfo='brew info'
alias serve='python3 -m http.server'

# ── Custom ────────────────────────────────────────────────────────
alias claer='clear'
alias c='clear'
alias r='ranger'
alias mobsf='docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest'
alias ghostyhelp='bat ~/terminal-cheatsheet.md'
if [[ -d "$ANDROID_HOME" ]]; then
    alias emulateroot='$ANDROID_HOME/emulator/emulator -avd Pixel_6a_API_29 -writable-system'
    alias emulateburp='$ANDROID_HOME/emulator/emulator -avd Pixel_4a_API_33 -writable-system'
fi

# ══════════════════════════════════════════════════════════════════
# ║                          FUNCTIONS                              ║
# ══════════════════════════════════════════════════════════════════

mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"                                        ;;
            *.tar.gz)    tar xzf "$1"                                        ;;
            *.bz2)       bunzip2 "$1"                                        ;;
            *.rar)       (( $+commands[unrar] )) && unrar x "$1" \
                         || echo "Install: brew install unrar"               ;;
            *.gz)        gunzip "$1"                                         ;;
            *.tar)       tar xf "$1"                                         ;;
            *.tbz2)      tar xjf "$1"                                        ;;
            *.tgz)       tar xzf "$1"                                        ;;
            *.zip)       unzip "$1"                                          ;;
            *.Z)         uncompress "$1"                                     ;;
            *.7z)        (( $+commands[7z] )) && 7z x "$1" \
                         || echo "Install: brew install p7zip"               ;;
            *.xz)        xz -d "$1"                                          ;;
            *.zst)       (( $+commands[zstd] )) && zstd -d "$1" \
                         || echo "Install: brew install zstd"                ;;
            *)           echo "'$1' cannot be extracted"                      ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

psgrep() { ps aux | grep -v grep | grep -i -e VSZ -e "$1"; }
killp() { ps aux | grep -v grep | grep -i "$1" | awk '{print $2}' | xargs kill -9; }
backup() { cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}; }
weather() { curl -s "wttr.in/${1:-}" | head -n 7; }

# Fuzzy-find and cd into directory
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls {}' +m) && cd "$dir"
}

# Fuzzy-find and open file in editor
fe() {
    local file
    file=$(fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'bat --style=numbers --color=always --line-range=:300 {} 2>/dev/null' +m) && ${EDITOR} "$file"
}

# Quick git commit with message
gcm() { git add -A && git commit -m "$*"; }

# Show top N processes by CPU
topcpu() { ps aux | sort -nrk 3,3 | head -n "${1:-10}"; }

# Show top N processes by memory
topmem() { ps aux | sort -nrk 4,4 | head -n "${1:-10}"; }

# Port finder — who's listening on what
whoisport() { lsof -nP -iTCP:${1} | grep LISTEN; }

# ══════════════════════════════════════════════════════════════════
# ║                     MODERN TOOL OVERRIDES                       ║
# ══════════════════════════════════════════════════════════════════

# ── eza (ls replacement) ─────────────────────────────────────────
# (( $+commands[eza] )) is a zsh builtin hash lookup — no subprocess fork
if (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first --color=always'
    alias ll='eza -lah --icons --group-directories-first --git --color=always'
    alias la='eza -a --icons --group-directories-first --color=always'
    alias l='eza -F --icons --color=always'
    alias lt='eza -lah --icons --sort=modified --color=always'
    alias lsize='eza -lah --icons --sort=size --color=always'
    alias tree='eza --tree --icons --color=always --level=3'
    alias treea='eza --tree --icons --color=always -a --level=3'
else
    alias ls='ls -G'
    alias ll='ls -lAh'
    alias la='ls -A'
    alias l='ls -CF'
    alias lt='ls -lAht'
    alias lsize='ls -lAhS'
fi

# ── bat (cat replacement) ────────────────────────────────────────
if (( $+commands[bat] )); then
    alias cat='bat --style=plain --paging=never'
    alias catn='bat --style=numbers --paging=never'
    alias catt='/bin/cat'
    export BAT_THEME="tokyonight_night"
fi

# ── zoxide (cd replacement — cached init) ────────────────────────
if (( $+commands[zoxide] )); then
    _zoxide_cache="${HOME}/.zsh/init_cache/zoxide.zsh"
    if [[ ! -f "$_zoxide_cache" || "$(command -v zoxide)" -nt "$_zoxide_cache" ]]; then
        [[ -d "${HOME}/.zsh/init_cache" ]] || mkdir -p "${HOME}/.zsh/init_cache"
        zoxide init zsh >| "$_zoxide_cache"
    fi
    source "$_zoxide_cache"
    alias cd='z'
    unset _zoxide_cache
fi

# ── thefuck (command correction — lazy loaded) ───────────────────
if (( $+commands[thefuck] )); then
    fuck() { eval "$(thefuck --alias)" && unfunction fuck && fuck "$@"; }
fi

# ── ripgrep ───────────────────────────────────────────────────────
if (( $+commands[rg] )); then
    alias rga='rg --hidden --no-ignore'
fi

# ══════════════════════════════════════════════════════════════════
# ║                     PLUGINS & INTEGRATIONS                      ║
# ══════════════════════════════════════════════════════════════════

# ── zsh-autosuggestions ───────────────────────────────────────────
# Set vars BEFORE sourcing so the plugin reads them at init time
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1
# Prevents rebinding widgets on every precmd — significant speedup
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ── fzf (cached init — avoids process substitution fork) ─────────
if (( $+commands[fzf] )); then
    _fzf_cache="${HOME}/.zsh/init_cache/fzf.zsh"
    if [[ ! -f "$_fzf_cache" || "$(command -v fzf)" -nt "$_fzf_cache" ]]; then
        [[ -d "${HOME}/.zsh/init_cache" ]] || mkdir -p "${HOME}/.zsh/init_cache"
        fzf --zsh >| "$_fzf_cache" 2>/dev/null
    fi
    [[ -f "$_fzf_cache" ]] && source "$_fzf_cache" || { [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh; }
    unset _fzf_cache
fi

export FZF_DEFAULT_OPTS=" \
    --height 60% --layout=reverse --border=rounded \
    --color=bg+:#292e42,bg:#1a1b26,spinner:#c0caf5,hl:#f7768e \
    --color=fg:#a9b1d6,header:#f7768e,info:#bb9af7,pointer:#7dcfff \
    --color=marker:#9ece6a,fg+:#c0caf5,prompt:#bb9af7,hl+:#f7768e \
    --color=selected-bg:#364a82 \
    --color=border:#3b4261,label:#c0caf5 \
    --multi --info=inline-right --border-label='' \
    --preview-window='right:50%:wrap' \
    --bind='ctrl-y:accept,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down'"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:300 {} 2>/dev/null'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls {}'"

# ── Atuin (magical shell history — cached init) ───────────────────
if (( $+commands[atuin] )); then
    _atuin_cache="${HOME}/.zsh/init_cache/atuin.zsh"
    if [[ ! -f "$_atuin_cache" || "$(command -v atuin)" -nt "$_atuin_cache" ]]; then
        [[ -d "${HOME}/.zsh/init_cache" ]] || mkdir -p "${HOME}/.zsh/init_cache"
        atuin init zsh --disable-up-arrow >| "$_atuin_cache"
    fi
    source "$_atuin_cache"
    unset _atuin_cache
    bindkey '^r' atuin-search
fi

# ── Starship Prompt (cached init) ────────────────────────────────
if (( $+commands[starship] )); then
    _starship_cache="${HOME}/.zsh/init_cache/starship.zsh"
    if [[ ! -f "$_starship_cache" || "$(command -v starship)" -nt "$_starship_cache" ]]; then
        [[ -d "${HOME}/.zsh/init_cache" ]] || mkdir -p "${HOME}/.zsh/init_cache"
        starship init zsh >| "$_starship_cache"
    fi
    source "$_starship_cache"
    unset _starship_cache
elif [[ -f ~/.local/bin/oh-my-posh ]]; then
    eval "$(~/.local/bin/oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/amro.omp.json)"
else
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f '
    setopt PROMPT_SUBST
    PROMPT='%F{green}%n@%m%f %F{blue}%~%f ${vcs_info_msg_0_}%F{yellow}❯%f '
fi

# ── zsh-syntax-highlighting (MUST be last plugin sourced) ────────
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# TokyoNight colors for syntax highlighting
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#9ece6a,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#9ece6a,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#9ece6a,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#7aa2f7,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#e0af68,bold,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=#ff9e64,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#f7768e,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#9ece6a,bold'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#c0caf5'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#bb9af7,bold'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#565f89,italic'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#bb9af7,bold'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#bb9af7,bold'

# ── fastfetch (minimal splash) ────────────────────────────────────
#if (( $+commands[fastfetch] )) && [[ $- == *i* ]] && [[ -z "$VSCODE_PID" ]] && [[ -z "$CURSOR_TRACE_ID" ]] && [[ -z "$FASTFETCH_DONE" ]]; then
#    export FASTFETCH_DONE=1
#    fastfetch
#fi

# ── Local Overrides ───────────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
