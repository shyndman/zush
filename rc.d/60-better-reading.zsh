# Better reading tools configuration
# Sets up bat and bat-extras for enhanced terminal reading experience

# Require bat
if ! command -v bat >/dev/null 2>&1; then
    return 1
fi

# Batman for enhanced man pages
eval "$(batman --export-env)"

# Bat-extras aliases
alias bg='batgrep'
alias bd='batdiff'
alias bw='batwatch'

# Replace cat with bat
alias cat='bat'

# Used for rendering Mermaid charts
mermaid() {
    npx -p @mermaid-js/mermaid-cli mmdc
}
