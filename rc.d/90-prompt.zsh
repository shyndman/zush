# Starship prompt configuration
# Sets up starship with custom config if needed

# Require starship
if ! command -v starship >/dev/null 2>&1; then
    return 1
fi

# Ensure starship config is available
_starship_config_file="$HOME/.config/starship/starship.toml"
if [[ ! -f "$_starship_config_file" ]]; then
    if ! command -v curl >/dev/null 2>&1; then
        zush_error "Cannot download starship config: curl not available"
        return 1
    fi
    
    zush_debug "Installing starship config"
    mkdir -p "${_starship_config_file:h}"
    curl -sSL "https://gist.githubusercontent.com/shyndman/01c8e8bfc197cfe8c56f41ca195921d1/raw/2615d222b3b297938987cba40beb8a83cc3a8233/starship.toml" -o "$_starship_config_file"
fi
unset _starship_config_file

# Initialize Starship prompt
eval "$(starship init zsh)"