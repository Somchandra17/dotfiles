# Lean zsh. No Oh My Zsh, no oh-my-posh, no Amazon Q, no linuxbrew.
# History, completion, and aliases are the ones from the old machine.

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt AUTO_CD CORRECT

# The Grok installer only writes this into bashrc. Login is zsh, so without
# it `grok` is missing from every terminal.
export PATH="$HOME/.grok/bin:$PATH"
fpath=("$HOME/.grok/completions/zsh" $fpath)

# Same socket as ~/.config/environment.d/99-ssh-auth-sock.conf. A terminal
# started before the next login does not inherit that file.
if [[ -z ${SSH_AUTH_SOCK:-} && -S ${XDG_RUNTIME_DIR:-}/keyring/ssh ]]; then
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/keyring/ssh"
fi

autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END GLOB_COMPLETE
setopt NO_MENU_COMPLETE FLOW_CONTROL

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose true
mkdir -p ~/.zsh/cache

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
export EDITOR=nvim
export VISUAL=nvim
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias py='python3'
alias pp='python3 -m pip install --break-system-packages'
alias vir='python3 -m venv'
alias claer='clear'
alias copy='wl-copy'
alias video='mpv --no-config --vo=kitty'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias emulateroot='~/Android/Sdk/emulator/emulator -avd Pixel_6a_API_29 -writable-system'
alias emulateburp='~/Android/Sdk/emulator/emulator -avd Pixel_4a_API_33 -writable-system'
alias mobsf='docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest'
alias fuckoff='poweroff'
alias pewpew='systemctl suspend'
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-sandbox'

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
bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char
bindkey '^W' backward-kill-word
bindkey '^[d' kill-word
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^Y' yank

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '^[[C' forward-char
bindkey '^I' menu-complete
bindkey '^[[Z' reverse-menu-complete

if [[ -f /usr/share/fzf/shell/key-bindings.zsh ]]; then
    source /usr/share/fzf/shell/key-bindings.zsh
fi
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Syntax highlighting last.
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# opencode
export PATH=/home/som/.opencode/bin:$PATH
