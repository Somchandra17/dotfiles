function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end
    
    # Aliases

    # eza / ls
    alias ll 'eza -alF --icons'
    alias la 'eza -A --icons'
    alias l  'eza -CF --icons'
    alias ls 'eza --icons'
    
    # pacman
    alias pamcan pacman
    
    # clear (full reset)
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    
    # grep colors
    alias grep  'grep --color=auto'
    alias fgrep 'fgrep --color=auto'
    alias egrep 'egrep --color=auto'
    
    # Android emulators
    alias emulateroot '~/Android/Sdk/emulator/emulator -avd Pixel_6a_API_29 -writable-system'
    alias emulateburp '~/Android/Sdk/emulator/emulator -avd Pixel_4a_API_33 -writable-system'
    
    # Python
    alias pp 'python3 -m pip install --break-system-packages'
    alias py python3
    alias vir 'python3 -m venv'
    
    # typo fix
    alias claer clear
    
    # Docker / security
    alias mobsf 'docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest'
    
    # media
    alias video 'mpv --no-config --vo=kitty'
    
    # power / system
    alias fuckoff poweroff
    alias pewpew 'systemctl suspend'
    
    # Wayland / wlroots
    alias k kanshi
    alias copy wl-copy
    
    
    # TLP
    alias powersave 'sudo tlp bat; and echo "Switched to power save mode"'
    alias performance 'sudo tlp ac; and echo "Switched to performance mode"'
    alias powerstatus 'sudo tlp-stat -s'


end