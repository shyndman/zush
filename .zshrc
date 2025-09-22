#!/usr/bin/env zsh
# Zush - High-Performance ZSH Configuration
# Main orchestrator that loads libraries and sources rc.d scripts

# Early exit if Zush is disabled
[[ -n "${ZUSH_DISABLE}" ]] && return

# Capture start time for timing debug logs
# Start timing for startup measurement
typeset -g ZUSH_START_TIME=$(date +%s%3N)

# Configuration - ZDOTDIR should be set to ~/.config/zush
typeset -g ZUSH_HOME="$ZDOTDIR"
typeset -g ZUSH_LIB_DIR="${ZUSH_HOME}/lib"
typeset -g ZUSH_RC_DIR="${ZUSH_HOME}/rc.d"
typeset -g ZUSH_CACHE_DIR="${HOME}/.cache/zush"
typeset -g ZUSH_DEBUG="${ZUSH_DEBUG:-0}"

# Create cache directory if needed
[[ ! -d "${ZUSH_CACHE_DIR}" ]] && mkdir -p "${ZUSH_CACHE_DIR}"

# Enable profiling as early as possible
if [[ "${ZUSH_PROFILE:-0}" == "1" ]]; then
    zmodload zsh/zprof
fi

# Show instant prompt as early as possible (before any heavy loading)
if [[ -f "${ZUSH_LIB_DIR}/instant-prompt.zsh" ]]; then
    # Load core functions first for zush_debug (but preserve ZUSH_START_TIME)
    [[ -f "${ZUSH_LIB_DIR}/core.zsh" ]] && source "${ZUSH_LIB_DIR}/core.zsh"
    source "${ZUSH_LIB_DIR}/instant-prompt.zsh"
    _zush_show_instant_prompt
fi


# Load utility libraries first
# These provide functions used by rc.d scripts
if [[ -d "${ZUSH_LIB_DIR}" ]]; then
    # Load in specific order if they exist
    for lib in core compiler lazy-loader utils; do
        local lib_file="${ZUSH_LIB_DIR}/${lib}.zsh"
        [[ -f "$lib_file" ]] && source "$lib_file"
    done

    # Load profiler only if profiling is enabled
    if [[ "${ZUSH_PROFILE:-0}" == "1" ]]; then
        local profiler_file="${ZUSH_LIB_DIR}/profiler.zsh"
        [[ -f "$profiler_file" ]] && source "$profiler_file"
    fi

    # Load any other libraries not in the priority list
    for lib_file in "${ZUSH_LIB_DIR}"/*.zsh(N); do
        local basename="${lib_file:t:r}"
        case "$basename" in
            core|profiler|compiler|lazy-loader|utils) continue ;;
            *) _zush_source "$lib_file" ;;
        esac
    done
fi

# Source all rc.d scripts in numerical order
if [[ -d "${ZUSH_RC_DIR}" ]]; then
    for script in "${ZUSH_RC_DIR}"/*.zsh(N); do
        _zush_source "$script"
    done
fi

# Load machine-specific Zush configuration
[[ -f "${HOME}/.zushrc" ]] && _zush_source "${HOME}/.zushrc"

# Auto-compile all configuration files in the background
if (( ${+functions[_zushc_bg]} )); then
    _zushc_bg
fi

# Hand off instant prompt to real starship
if (( ${+functions[_zush_handoff_to_real_prompt]} )); then
    _zush_handoff_to_real_prompt
fi

# Check for available updates and prompt, or start background check if needed
if (( ${+functions[_zush_prompt_available_update]} )); then
    _zush_prompt_available_update
elif (( ${+functions[_zush_start_update_check]} )); then
    _zush_start_update_check
fi

# Clean up (core functions stay available)
# unset -f # nothing to clean up currently
