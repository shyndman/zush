#!/usr/bin/env zsh
# Zush - High-Performance ZSH Configuration
# Main orchestrator that loads libraries and sources rc.d scripts

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
            *) zush_source "$lib_file" ;;
        esac
    done
fi

# Source all rc.d scripts in numerical order
if [[ -d "${ZUSH_RC_DIR}" ]]; then
    for script in "${ZUSH_RC_DIR}"/*.zsh(N); do
        zush_source "$script"
    done
fi

# Auto-compile all configuration files in the background
if (( ${+functions[zushc_bg]} )); then
    zushc_bg
fi

# Clean up (core functions stay available)
# unset -f # nothing to clean up currently