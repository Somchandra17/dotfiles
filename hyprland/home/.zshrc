# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/.local/share/amazon-q/shell/zshrc.pre.zsh"
# Basic zsh configuration
# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Basic settings
setopt AUTO_CD
setopt CORRECT
setopt MENU_COMPLETE

# Completion system configuration with caching
autoload -Uz compinit
# Only regenerate compdump once a day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Completion options
setopt AUTO_MENU         # Show completion menu on successive tab press
setopt COMPLETE_IN_WORD  # Complete from both ends of a word
setopt ALWAYS_TO_END     # Move cursor to the end of a completed word
setopt GLOB_COMPLETE     # Use glob completion
setopt NO_MENU_COMPLETE  # Don't autoselect the first completion entry
setopt FLOW_CONTROL      # Enable start/stop characters in shell editor

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# Additional completion improvements
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose true

# Create cache directory
mkdir -p ~/.zsh/cache

# Path configuration
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Basic aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Key bindings and line editor settings
# Use Emacs-style keybindings (Ctrl-A, Ctrl-E, etc.)
bindkey -e

# Treat / and . as word boundaries for word-wise movement
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'

# Ctrl+Left/Right to move by word (common sequences)
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
# Some terminals send these
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word
# Meta+b / Meta+f as fallbacks
bindkey '^[b' backward-word
bindkey '^[f' forward-word

# Home/End keys (common sequences)
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Optional: Delete/Backspace consistency
bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char

# Additional useful bindings
# Ctrl+W to delete word backward
bindkey '^W' backward-kill-word
# Alt+D to delete word forward
bindkey '^[d' kill-word
# Ctrl+K to kill line from cursor to end
bindkey '^K' kill-line
# Ctrl+U to kill line from beginning to cursor
bindkey '^U' backward-kill-line
# Ctrl+Y to yank (paste)
bindkey '^Y' yank

# Zsh plugins
# Load zsh-autosuggestions (must be loaded before zsh-syntax-highlighting)
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Configure autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'  # Gray color for suggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # Use history and completion
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20  # Don't suggest for long commands

# Autosuggestion key bindings
bindkey '^[[C' forward-char  # Right arrow to accept suggestion
bindkey '^I' menu-complete   # Tab for completion menu
bindkey '^[[Z' reverse-menu-complete  # Shift-Tab for reverse completion

# Load zsh-syntax-highlighting (must be loaded last)
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Oh My Posh with amro theme
eval "$(~/.local/bin/oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/amro.omp.json)"
# Paths and aliases copied from ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:/usr/lib/python3/dist-packages
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Additional aliases from ~/.bashrc
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias emulateroot="~/Android/Sdk/emulator/emulator -avd Pixel_6a_API_29 -writable-system"
alias emulateburp="~/Android/Sdk/emulator/emulator -avd Pixel_4a_API_33 -writable-system"
alias pp="python3 -m pip install --break-system-packages"
alias py="python3"
alias claer="clear"
alias vir="python3 -m venv"
alias mobsf="docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest"
alias video="mpv --no-config --vo=kitty"
alias fuckoff="poweroff"
alias k="kanshi"
alias copy="wl-copy"
alias pewpew="systemctl suspend"
alias waybar-restart="killall waybar 2>/dev/null; sleep 0.5; waybar & disown"
# Cargo environment
. "$HOME/.cargo/env"

# Load bash aliases if they exist
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Disable Q CLI version check notifications
export Q_DISABLE_VERSION_CHECK=1

# TLP power profile aliases
alias powersave='sudo tlp bat && echo "Switched to power save mode"'
alias performance='sudo tlp ac && echo "Switched to performance mode"'
alias powerstatus='sudo tlp-stat -s'

# Amazon Q post block. Keep at the bottom of this file.
## Lazy load NVM for faster startup
export NVM_DIR="$HOME/.nvm"
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/.local/share/amazon-q/shell/zshrc.post.zsh"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
alias code="code --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-sandbox"
