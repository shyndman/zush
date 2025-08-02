# Editor configuration
# Sets up editor preferences based on environment

# Use VS Code if local (with -w to wait), vim if remote
if [[ -z "$SSH_CONNECTION" ]] && command -v code >/dev/null 2>&1; then
    export EDITOR="code -w"
    export VISUAL="code -w"
else
    export EDITOR="vim"
    export VISUAL="vim"
fi