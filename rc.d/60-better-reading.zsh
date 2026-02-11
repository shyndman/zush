# Better reading tools configuration

# Preview markdown in browser
mdp() {
    local source_file="$1"
    local zush_home="${ZUSH_HOME:-${ZDOTDIR:-$HOME/.config/zush}}"
    local diagram_filter="${zush_home}/vendor/pandoc-ext/diagram/_extensions/diagram/diagram.lua"
    local preview_css="${zush_home}/assets/mdp-preview.css"
    local mermaid_bin="${commands[mmdc]:-${zush_home}/scripts/mmdc-wrapper.sh}"
    local preview_file

    if [[ -z "$source_file" || ! -f "$source_file" ]]; then
        zush_error "Usage: mdp <markdown-file>"
        return 1
    fi

    [[ -f "$diagram_filter" ]] || {
        zush_error "Missing diagram filter: $diagram_filter"
        return 1
    }
    [[ -f "$preview_css" ]] || {
        zush_error "Missing preview CSS: $preview_css"
        return 1
    }
    [[ -x "$mermaid_bin" ]] || {
        zush_error "Mermaid binary is not executable: $mermaid_bin"
        return 1
    }

    preview_file=$(mktemp /tmp/mdpreview-XXXX.html) || return 1

    MERMAID_BIN="$mermaid_bin" pandoc \
        --standalone \
        --embed-resources \
        --css "$preview_css" \
        --lua-filter "$diagram_filter" \
        --metadata title="${source_file:t:r}" \
        -t html "$source_file" -o "$preview_file" && xdg-open "$preview_file"
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
