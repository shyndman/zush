# Eza (modern ls replacement) configuration
# Enhanced directory listings with colors, git integration, and tree views

# Only set up eza aliases if eza is available
if ! command -v eza >/dev/null 2>&1; then
    return 1
fi

# Ensure eza theme is available
_eza_theme_file="$HOME/.config/eza/theme.yml"
if [[ ! -f "$_eza_theme_file" ]]; then
    if ! command -v curl >/dev/null 2>&1; then
        zush_error "Cannot download eza theme: curl not available"
        return 1
    fi

    zush_debug "Installing eza rose-pine theme"
    mkdir -p "${_eza_theme_file:h}"
    if ! curl -sSL "https://gist.githubusercontent.com/shyndman/01c8e8bfc197cfe8c56f41ca195921d1/raw/d7e584ec00689b55223f76e255991f71616d7051/eza.rose-pine.yml" -o "$_eza_theme_file"; then
        zush_error "Failed to download eza theme"
        rm -f "$_eza_theme_file"
        # Continue without theme - eza will use defaults
    fi
fi
unset _eza_theme_file

# Base eza configuration with preferred options
_EZA_BASE=(
    --hyperlink
    --color-scale=size
    --color-scale-mode=gradient
    --icons=never
    --group-directories-first
)

# Core aliases
alias ls="eza --group ${_EZA_BASE[*]}"
alias l="eza --long --all --header ${_EZA_BASE[*]}"
alias ll="eza --long --header ${_EZA_BASE[*]}"

# Clean up
unset _EZA_BASE
