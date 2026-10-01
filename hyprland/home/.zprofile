# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/.local/share/amazon-q/shell/zprofile.pre.zsh"
#if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
#       Hyprland 
#fi

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/.local/share/amazon-q/shell/zprofile.post.zsh"
