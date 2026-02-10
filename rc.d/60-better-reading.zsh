# Better reading tools configuration

# Preview markdown in browser
mdp() {
  local tmp=$(mktemp /tmp/mdpreview-XXXX.html)
  pandoc -s --metadata title="${1:t:r}" -t html "$1" -o "$tmp" && xdg-open "$tmp"
}

# Sets Moor as our pager

export MOOR='--no-linenumbers'
export PAGER="$(which moor)"

# Sets up bat and bat-extras for enhanced terminal reading experience

# Require bat
if ! command -v bat >/dev/null 2>&1; then
    return 1
fi

# Batman for enhanced man pages
if command -v batman >/dev/null 2>&1; then
    eval "$(batman --export-env)" || {
        zush_error "Failed to initialize batman environment"
        return 1
    }
fi

# Bat-extras aliases
alias bg='batgrep'
alias bd='batdiff'
alias bw='batwatch'

# Replace cat with bat (no line numbers by default)
alias cat='bat --style=plain'

# Render CLI help with bat
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

# Used for rendering Mermaid charts
mermaid() {
    npx -p @mermaid-js/mermaid-cli mmdc
}
