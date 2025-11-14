#!/usr/bin/env bash
set -euo pipefail

main() {
    local root
    root=$(git rev-parse --show-toplevel)
    cd "$root"

    local -a candidates=()
    if [[ $# -gt 0 ]]; then
        candidates=("$@")
    else
        while IFS= read -r -d '' path; do
            candidates+=("$path")
        done < <(git ls-files -z)
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    local status=0
    local index=0
    local path
    for path in "${candidates[@]}"; do
        [[ -f "$path" ]] || continue
        case "$path" in
        plugins/* | worktrees/*) continue ;;
        lib/*.zsh | rc.d/*.zsh | home/.zshenv)
            local compiled="$tmpdir/$index.zwc"
            if ! zsh -c 'zcompile -R "$1" "$2"' -- "$compiled" "$path" >/dev/null 2>&1; then
                echo "zcompile failed: $path" >&2
                status=1
            fi
            ((index++))
            ;;
        esac
    done

    return "$status"
}

main "$@"
