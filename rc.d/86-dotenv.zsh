# Manual .env application helper. This file only defines apply_env() and
# never sources anything automatically so users can opt in per-shell.
#
# apply_env [path]
#   - Defaults to reading ./.env when no path is provided
#   - Works with regular files or FIFOs (single read via cat)
#   - Syntax-checks with zsh -fn before exporting variables via allexport
apply_env() {
    emulate -L zsh

    local target=${1:-.env}

    if [[ -z "$target" ]]; then
        echo "apply_env: missing target file" >&2
        return 1
    fi

    if [[ ! -e "$target" ]]; then
        echo "apply_env: '$target' does not exist" >&2
        return 1
    fi

    if [[ -d "$target" ]]; then
        echo "apply_env: '$target' is a directory" >&2
        return 1
    fi

    if [[ ! -r "$target" ]]; then
        echo "apply_env: '$target' is not readable" >&2
        return 1
    fi

    local env_data
    if ! env_data=$(cat -- "$target"); then
        echo "apply_env: failed to read '$target'" >&2
        return 1
    fi

    if [[ -n $env_data ]]; then
        env_data+=$'\n'
    fi

    if ! zsh -fn >/dev/null 2>&1 <<<"$env_data"; then
        echo "apply_env: syntax error while parsing '$target'" >&2
        return 1
    fi

    setopt localoptions allexport
    eval "$env_data"
}
