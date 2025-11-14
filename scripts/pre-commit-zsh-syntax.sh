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

    local status=0
    local path
    for path in "${candidates[@]}"; do
        [[ -f "$path" ]] || continue
        case "$path" in
        plugins/* | worktrees/*) continue ;;
        esac
        case "$path" in
        *.zsh | *.sh | home/.zshenv | install.sh | completions/*)
            if ! zsh -n "$path" >/dev/null; then
                echo "zsh -n failed: $path" >&2
                status=1
            fi
            ;;
        esac
    done

    return "$status"
}

main "$@"
