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
zush_source() {
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
