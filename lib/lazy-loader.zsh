#!/usr/bin/env zsh
# Zush Lazy Loader - High-performance lazy loading with environment caching

# --- Environment Caching ---

# Applies a tool's cached environment. Returns 1 if no cache exists.
_zush_apply_cached_env() {
    local tool=$1
    local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
    [[ -f $cache_file ]] || { zush_debug "No cached environment for $tool"; return 1; }
    zush_debug "Applying cached environment for $tool"
    source "$cache_file"
}

# Captures and caches environment changes after a tool is initialized.
_zush_do_tool_initialization() {
    local tool=$1
    local init_command=$2
    local warn_on_no_changes=${3:-1}

    zush_debug "Initializing environment for $tool"
    local _baseline_path=$PATH
    local _baseline_fpath=$FPATH
    local _baseline_env_file=$(mktemp)
    printenv | sort > "$_baseline_env_file"

    # Initialize the tool
    if ! eval "$init_command"; then
        zush_error "Failed to initialize $tool: eval command returned non-zero status"
        rm -f "$_baseline_env_file"
        return 1
    fi

    # Check for environment changes
    local _new_env_file=$(mktemp)
    printenv | sort > "$_new_env_file"
    local has_changes=0
    [[ $PATH != $_baseline_path ]] && has_changes=1
    [[ $FPATH != $_baseline_fpath ]] && has_changes=1
    [[ $(comm -13 "$_baseline_env_file" "$_new_env_file" | wc -l) -gt 0 ]] && has_changes=1

    if [[ $has_changes -eq 0 && $warn_on_no_changes -eq 1 ]]; then
        zush_error "WARNING: Tool '$tool' initialization produced no environment changes!"
    fi

    # Cache environment changes in the background
    (
        local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
        {
            echo "# Zush environment cache for $tool, generated: $(date)"
            # Process PATH additions
            if [[ $PATH != $_baseline_path ]]; then
                echo '\n# PATH additions:'
                local IFS=:
                local -a old_paths=(${=_baseline_path}) new_paths=(${=PATH})
                for p in "${new_paths[@]}"; do
                    (( ${old_paths[(Ie)$p]} )) || printf 'path=(%q $path)\n' "$p"
                done
            fi
            # Process FPATH additions
            if [[ $FPATH != $_baseline_fpath ]]; then
                echo '\n# FPATH additions:'
                local IFS=:
                local -a old_fpaths=(${=_baseline_fpath}) new_fpaths=(${=FPATH})
                for f in "${new_fpaths[@]}"; do
                    (( ${old_fpaths[(Ie)$f]} )) || printf 'fpath=(%q $fpath)\n' "$f"
                done
            fi
            # Process new environment variables
            echo '\n# Environment variables:'
            comm -13 "$_baseline_env_file" "$_new_env_file" | while IFS= read -r line; do
                [[ $line =~ ^([^=]+)=(.*)$ ]] || continue
                local var=${match[1]} value=${match[2]}
                [[ $var == PATH || $var == FPATH || -z $var ]] && continue
                printf 'export %s=%q\n' "$var" "$value"
            done
        } > "$cache_file"
        zush_debug "Environment cached to $cache_file"
        rm -f "$_baseline_env_file" "$_new_env_file"
    ) &!
}

# --- Standard Lazy Loading ---

zush_lazy_load() {
    local tool=$1
    local init_command=$2

    # Validate required parameters
    if [[ -z "$tool" ]]; then
        zush_error "zush_lazy_load: tool name is required (got: '$tool')"
        return 1
    fi

    if [[ -z "$init_command" ]]; then
        zush_error "zush_lazy_load: init command is required (got: '$init_command')"
        return 1
    fi

    shift 2
    local -a commands=("$@")

    # If no cache exists, initialize immediately and create the cache.
    if ! _zush_apply_cached_env "$tool"; then
        _zush_do_tool_initialization "$tool" "$init_command" 1
        return
    fi

    # If cache exists, create placeholder functions.
    local cmd
    for cmd in "${commands[@]}"; do
        eval "
        function $cmd() {
            zush_debug 'Lazy loading $tool via command: $cmd'
            local _cmd
            for _cmd in ${commands[*]}; do unfunction \"\$_cmd\" 2>/dev/null; done
            eval \"$init_command\" || {
                zush_error \"Failed to initialize $tool via lazy load\"
                return 1
            }
            \"\$0\" \"\$@\"
        }
        "
    done
}

# --- Eval-Cached Lazy Loading ---

zush_lazy_eval() {
    local tool=$1
    local command_to_execute=$2
    shift 2
    local -a placeholders=("$@")

    local eval_cache_dir="${ZUSH_CACHE_DIR}/eval"
    mkdir -p "$eval_cache_dir"
    local command_hash=$(echo -n "$command_to_execute" | md5sum | cut -d' ' -f1)
    local eval_cache_file="${eval_cache_dir}/${command_hash}"

    # If no environment cache exists, we need to create both caches now.
    if ! _zush_apply_cached_env "$tool"; then
        zush_debug "No environment cache for '$tool'. Generating all caches."
        if [[ ! -f "$eval_cache_file" ]]; then
            zush_debug "No eval cache for '$tool'. Executing command to create it."
            if ! eval "$command_to_execute" > "$eval_cache_file"; then
                zush_error "Failed to execute command for $tool eval cache"
                rm -f "$eval_cache_file"
                return 1
            fi
        fi
        # Now that the eval cache exists, use it to initialize the environment
        _zush_do_tool_initialization "$tool" "eval \"\$(<'$eval_cache_file')\"" 1
        return
    fi

    # If environment cache exists, create placeholder functions.
    local placeholder
    for placeholder in "${placeholders[@]}"; do
        eval "
        function $placeholder() {
            zush_debug 'Lazy loading eval for $tool via command: $placeholder'
            local _placeholder
            for _placeholder in ${placeholders[*]}; do unfunction \"\$_placeholder\" 2>/dev/null;
       done

            if [[ ! -f '$eval_cache_file' ]]; then
                zush_debug \"Cache miss for '$tool' eval, executing command.\"
                if ! eval \"$command_to_execute\" > '$eval_cache_file'; then
                    zush_error \"Failed to create eval cache for $tool\"
                    rm -f '$eval_cache_file'
                    return 1
                fi
            fi

            eval \"\$(<'$eval_cache_file')\"
            \"\$0\" \"\$@\"
        }
        "
    done
}

# --- Cache Management ---

_zush_lazy_clear() {
    local tool=$1
    if [[ -n $tool ]]; then
        rm -f "${ZUSH_CACHE_DIR}/${tool}-env" && echo "Cleared cache for $tool"
    else
        rm -f "${ZUSH_CACHE_DIR}"/*-env(N) && echo "Cleared all lazy-load caches"
        _zush_eval_clear
    fi
}

# Refresh cache for a tool (clear and reinitialize on next use)
_zush_lazy_refresh() {
    local tool=$1
    [[ -n $tool ]] || { echo "Usage: _zush_lazy_refresh <tool>"; return 1; }

    _zush_lazy_clear "$tool"
    echo "Cache cleared for $tool. It will be regenerated on next use."
}

# Show status of lazy-loaded tools
_zush_lazy_status() {
    local cache_file tool cache_date
    local -a cache_files=("${ZUSH_CACHE_DIR}"/*-env(N))

    [[ ${#cache_files} -eq 0 ]] && { echo "No lazy-loaded tools cached"; return; }

    echo "Lazy-loaded tools:"
    for cache_file in "${cache_files[@]}"; do
        tool=${cache_file:t:r}
        tool=${tool%-env}

        if [[ -f $cache_file ]]; then
            # Try GNU stat first, fall back to BSD stat
            cache_date=$(stat -c '%y' "$cache_file" 2>/dev/null | cut -d' ' -f1-2 ||
                        stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$cache_file" 2>/dev/null)
            echo "  $tool: cached (${cache_date:-unknown date})"
        fi
    done
}

# Show environment diff for a cached tool
_zush_lazy_diff() {
    local tool=$1
    [[ -n $tool ]] || { echo "Usage: _zush_lazy_diff <tool>"; return 1; }

    local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
    [[ -f $cache_file ]] || { echo "No cached environment for $tool"; return 1; }

    echo "Environment diff for $tool:"
    echo "Cache file: $cache_file"
    echo
cat "$cache_file"
}

# Trigger eval cache maintenance once the lazy loader is available.
if (( ${+functions[_zush_check_cache_invalidation]} )); then
    _zush_check_cache_invalidation
fi
