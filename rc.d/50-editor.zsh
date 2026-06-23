# Editor configuration
# Sets up editor preferences based on environment

# Use Zed if local (with -w to wait), neovim if remote
if [[ -z "$SSH_CONNECTION" ]] && (( ${+commands[code]} )); then
    export EDITOR="zed -w"
    export VISUAL="zed -w"
else
    export EDITOR="nvim"
    export VISUAL="nvim"
fi

