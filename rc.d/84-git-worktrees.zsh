# Git worktree helper
# Provides `gwt` for creating worktrees under <repo>/worktrees

gwt() {
    emulate -L zsh
    local stay=0
    local auto_yes=0

    _gwt_require_git || return 1

    while (( $# )); do
        case "$1" in
            --stay)
                stay=1
                ;;
            -y|--yes)
                auto_yes=1
                ;;
            --help|-h)
                _gwt_usage
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                _gwt_error "Unknown option: $1"
                _gwt_usage >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    if (( $# == 0 )); then
        _gwt_error "Missing worktree name"
        _gwt_usage >&2
        return 1
    fi

    local worktree_name=$1
    shift

    local repo_root=$(_gwt_repo_root) || return 1
    local worktrees_dir=$(_gwt_worktrees_dir "$repo_root") || return 1
    local target_path=$(_gwt_target_path "$worktrees_dir" "$worktree_name") || return 1

    if [[ -d "$target_path" ]]; then
        if (( $# )); then
            _gwt_error "Extra arguments are not allowed when switching to an existing worktree"
            return 1
        fi
        _gwt_message "Switching to existing worktree: ${worktree_name}"
        (( stay )) || _gwt_enter_worktree "$target_path" || return 1
        return 0
    fi

    _gwt_confirm_create "$worktree_name" "$target_path" "$auto_yes" || return 1

    _gwt_run_git_worktree_add "$target_path" "$@" || return 1

    if (( ! stay )); then
        _gwt_enter_worktree "$target_path" || return 1
    fi
}

_gwt_usage() {
    cat <<'USAGE'
Usage: gwt [--stay] [--yes] <name> [<base-ref>]

Creates or enters a git worktree located at <repo>/worktrees/<name>. When the
worktree already exists, gwt simply switches to it. When it does not, gwt asks
for confirmation (unless --yes is supplied) and then runs `git worktree add`,
optionally using <base-ref>.

Options:
  --stay        Do not cd into the target worktree after completion.
  -y, --yes     Automatically confirm creation of missing worktrees.
  -h, --help    Show this help message.
USAGE
}

_gwt_error() {
    printf 'gwt: %s\n' "$*" >&2
}

_gwt_message() {
    printf 'gwt: %s\n' "$*"
}

_gwt_require_git() {
    if ! command -v git >/dev/null 2>&1; then
        _gwt_error "git is not available"
        return 1
    fi
}

_gwt_repo_root() {
    local root
    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        _gwt_error "Not inside a git repository"
        return 1
    fi
    printf '%s\n' "$root"
}

_gwt_worktrees_dir() {
    local repo_root=$1
    local dir="${repo_root}/worktrees"
    if [[ ! -d "$dir" ]] && ! mkdir -p "$dir"; then
        _gwt_error "Unable to create worktrees directory at $dir"
        return 1
    fi
    printf '%s\n' "$dir"
}

_gwt_target_path() {
    local worktrees_dir=$1
    local name=$2
    local relative=$(_gwt_sanitize_name "$name") || return 1
    printf '%s/%s\n' "$worktrees_dir" "$relative"
}

_gwt_sanitize_name() {
    local name=$1
    name=${name#./}
    name=${name%/}
    if [[ -z "$name" || "$name" == "." ]]; then
        _gwt_error "Worktree name cannot be empty"
        return 1
    fi
    if [[ "$name" == /* ]]; then
        _gwt_error "Worktree name must be relative to the repo root"
        return 1
    fi

    local IFS='/'
    local -a segments
    local segment
    read -rA segments <<< "$name"
    for segment in "${segments[@]}"; do
        if [[ "$segment" == ".." ]]; then
            _gwt_error "Worktree name cannot traverse outside worktrees directory"
            return 1
        fi
    done

    printf '%s\n' "$name"
}

_gwt_run_git_worktree_add() {
    local target_path=$1
    shift
    if ! git worktree add "$target_path" "$@"; then
        _gwt_error "git worktree add failed"
        return 1
    fi
}

_gwt_confirm_create() {
    local name=$1
    local path=$2
    local auto_yes=$3
    local reply
    local prompt="Create worktree '${name}' at '${path}'? [Y/n] "

    if (( auto_yes )); then
        _gwt_message "Creating worktree '${name}' (auto-confirmed)"
        return 0
    fi

    if ! read -r "reply?$prompt"; then
        _gwt_error "Confirmation aborted"
        return 1
    fi

    if [[ -z "$reply" || "$reply" == [Yy] ]]; then
        return 0
    fi

    _gwt_error "Aborted"
    return 1
}

_gwt_enter_worktree() {
    local target_path=$1
    if ! builtin cd "$target_path"; then
        _gwt_error "Failed to cd into $target_path"
        return 1
    fi
}
