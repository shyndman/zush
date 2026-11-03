# Zush Completion Utilities
# Internal helpers for completion system setup and root fpath mirroring
# shellcheck shell=bash

# Safely removes a path inside the completion mirror directory
_zush_remove_mirror_path() {
    local target="$1"
    local mirror_root="${ZUSH_CACHE_DIR}/mirrored-completions"

    [[ -e "$target" ]] || return 0

    if [[ -z "${ZUSH_CACHE_DIR}" || "$target" != "${mirror_root}/"* ]]; then
        zush_error "Refusing to remove path outside mirror root: $target"
        return 1
    fi

    if command -v trash-put >/dev/null 2>&1; then
        trash-put "$target"
    else
        rm -rf "$target"
    fi
}

# Syncs a single non-root-owned completion directory into a root-owned cache directory
_zush_sync_completion_mirror() {
    local src_dir="$1"
    local mirror_dir="$2"

    if [[ -d "$mirror_dir" && ! "$src_dir" -nt "$mirror_dir" ]]; then
        zush_debug "Completion mirror is fresh: $mirror_dir"
        return 0
    fi

    zush_debug "Mirroring insecure completion directory: $src_dir -> $mirror_dir"
    local tmp_mirror="${mirror_dir}.tmp.$$"
    _zush_remove_mirror_path "$tmp_mirror" || return 1

    if ! mkdir -p -m 0755 "$tmp_mirror"; then
        zush_error "Failed to create completion mirror directory: $tmp_mirror"
        return 1
    fi

    if ! cp -RLf "$src_dir"/. "$tmp_mirror"/ 2>/dev/null; then
        zush_error "Failed to dereference-copy completions from $src_dir to $tmp_mirror"
        _zush_remove_mirror_path "$tmp_mirror"
        return 1
    fi

    chown -R 0:0 "$tmp_mirror"
    chmod -R u=rwX,go=rX "$tmp_mirror"
    touch -r "$src_dir" "$tmp_mirror"

    _zush_remove_mirror_path "$mirror_dir" || return 1
    mv "$tmp_mirror" "$mirror_dir"
    zush_debug "Mirrored completions ready: $mirror_dir"
    return 0
}

# Scans fpath for non-root-owned directories, syncs mirrors, and writes cached fpath
_zush_rebuild_mirrored_fpath() {
    local fpath_cache="$1"
    local mirror_root="${ZUSH_CACHE_DIR}/mirrored-completions"

    if ! mkdir -p -m 0755 "${ZUSH_CACHE_DIR}" "$mirror_root"; then
        zush_error "Failed to create mirrored completions root: $mirror_root"
        return 1
    fi
    chmod 0755 "${ZUSH_CACHE_DIR}" "$mirror_root"

    local -a updated_fpath=()
    local dir parent_dir sanitized mirror_dir
    for dir in "${fpath[@]}"; do
        if [[ ! -d "$dir" ]]; then
            updated_fpath+=("$dir")
            continue
        fi

        parent_dir=$(dirname "$dir")
        if [[ -z $(find -L "$dir" -maxdepth 1 ! -user 0 -print -quit 2>/dev/null) ]] &&
            [[ -z $(find -L "$parent_dir" -maxdepth 0 ! -user 0 -print -quit 2>/dev/null) ]]; then
            updated_fpath+=("$dir")
            continue
        fi

        sanitized="${dir#/}"
        sanitized="${sanitized//\//_}"
        mirror_dir="${mirror_root}/${sanitized}"

        if _zush_sync_completion_mirror "$dir" "$mirror_dir"; then
            updated_fpath+=("$mirror_dir")
        else
            updated_fpath+=("$dir")
        fi
    done

    local tmp_cache="${fpath_cache}.tmp.$$"
    {
        printf 'fpath=('
        printf '%q ' "${updated_fpath[@]}"
        printf ')\n'
    } >"$tmp_cache" && mv "$tmp_cache" "$fpath_cache"
}

# Mirrors non-root-owned fpath directories into root-owned cache when running as root
_zush_mirror_insecure_completions() {
    if ((EUID != 0)) || ! zstyle -t ':zush:completions' 'mirror-insecure'; then
        return 0
    fi

    local fpath_cache="${ZUSH_CACHE_DIR}/mirrored-fpath.zsh"
    local cache_max_age=$((24 * 60 * 60))

    if [[ ! -f "$fpath_cache" ]]; then
        _zush_rebuild_mirrored_fpath "$fpath_cache" || return 1
        source "$fpath_cache"
        return 0
    fi

    local cache_fresh=0
    if zmodload zsh/stat 2>/dev/null; then
        local cache_mtime
        cache_mtime=$(zstat -L +mtime -- "$fpath_cache" 2>/dev/null)
        if [[ -n "$cache_mtime" ]] && ((cache_mtime >= EPOCHSECONDS - cache_max_age)); then
            cache_fresh=1
        fi
    fi

    if ((!cache_fresh)); then
        zush_debug "Refreshing mirrored fpath cache in background"
        (_zush_rebuild_mirrored_fpath "$fpath_cache" &)
    else
        zush_debug "Mirrored fpath cache is fresh"
    fi

    source "$fpath_cache"
}
