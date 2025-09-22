# Zush Core Utilities
# Foundational functions used throughout the Zush system

# Debug logging with optional timing
zush_debug() {
    [[ "${ZUSH_DEBUG}" == "1" ]] || return
    if [[ "${ZUSH_PROFILE:-0}" == "1" ]]; then
        # Calculate elapsed time since script start
        local elapsed_ms
        if [[ -n "${ZUSH_START_TIME:-}" ]]; then
            local current_time=$(date +%s%3N)  # seconds since epoch
            elapsed_ms=$((current_time - $ZUSH_START_TIME))
        else
            elapsed_ms="???"
        fi
        echo "[ZUSH DEBUG +${elapsed_ms}ms] $*" >&2
    else
        echo "[ZUSH DEBUG] $*" >&2
    fi
}

# Error handling
zush_error() {
    echo "[ZUSH ERROR] ${funcstack[2]:-unknown}:${funcfiletrace[1]##*:}: $*" >&2
}

# Source a file with error handling
_zush_source() {
    local file="$1"
    if [[ -r "$file" ]]; then
        zush_debug "Sourcing: $file"
        source "$file"
        return $?
    else
        zush_error "Cannot source: $file (not readable)"
        return 1
    fi
}

# Clean all Zush caches and data
zush_clean() {
    local confirm
    echo -n "Clean all Zush caches, compiled files, and plugins? [y/N] "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "Cleaning Zush system..."

        # Clean compiled files
        if (( ${+functions[_zushc_clean]} )); then
            echo "  - Removing compiled files..."
            _zushc_clean
        fi

        # Clean plugins
        if (( ${+functions[_zushp_clean]} )); then
            echo "  - Removing plugins..."
            # Call the internal function directly without prompt since we already confirmed
            [[ -d "$ZUSH_PLUGINS_DIR" ]] && rm -rf "$ZUSH_PLUGINS_DIR"
            [[ -f "$ZUSH_PLUGINS_MANIFEST" ]] && rm -f "$ZUSH_PLUGINS_MANIFEST"
            mkdir -p "$ZUSH_PLUGINS_DIR" 2>/dev/null
        fi

        # Clean lazy loading caches
        if (( ${+functions[_zush_lazy_clear]} )); then
            echo "  - Clearing lazy loading caches..."
            _zush_lazy_clear
        fi

        # Clean eval caches
        if (( ${+functions[_zush_eval_clear]} )); then
            echo "  - Clearing eval caches..."
            _zush_eval_clear
        fi

        echo "Zush system cleaned successfully!"
    else
        echo "Cancelled"
    fi
}

# Automatic cache invalidation
_zush_check_cache_invalidation() {
    local timestamp_file="${ZUSH_CACHE_DIR}/eval-timestamp"
    local max_age=$((7 * 24 * 60 * 60)) # 7 days in seconds

    if [[ -f "$timestamp_file" ]]; then
        local last_check=$(stat -c %Y "$timestamp_file")
        local now=$(date +%s)
        if (( now - last_check > max_age )); then
            zush_debug "Eval cache is older than 7 days, clearing in background."
            _zush_eval_clear &!
            touch "$timestamp_file"
        fi
    else
        touch "$timestamp_file"
    fi
}

_zush_check_cache_invalidation
