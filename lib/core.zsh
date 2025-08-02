# Zush Core Utilities
# Foundational functions used throughout the Zush system

# Debug logging
zush_debug() {
    [[ "${ZUSH_DEBUG}" == "1" ]] && echo "[ZUSH DEBUG] $*" >&2
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