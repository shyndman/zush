#!/usr/bin/env bash
set -euo pipefail

tmpdir=""

cleanup() {
    local dir=${tmpdir-}
    [[ -n "$dir" ]] && rm -rf "$dir"
}

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

    tmpdir=$(mktemp -d)
    trap cleanup EXIT

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
            ((index += 1))
            ;;
        esac
    done

    return "$status"
}

main "$@"
