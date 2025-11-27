# Zush Completions System
# shellcheck shell=bash

# Tab-completion behavior (case-folding plus substring/mid-word matches)
zstyle ':completion:*' matcher-list \
    'm:{[:lower:]}={[:upper:]}' \
    'm:{[:lower:]}={[:upper:]} r:|=* l:|=*' \
    'm:{[:lower:]}={[:upper:]} r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select # use menu selection for completions

# Sets up completion loading and custom completions directory. Runs late in
# startup sequence after tools and environments are set up

# Add Zush completions directory to FPATH
typeset -g ZUSH_COMPLETIONS_DIR="${ZUSH_HOME}/completions"

if [[ -d "$ZUSH_COMPLETIONS_DIR" ]]; then
    # Add to beginning of FPATH for priority
    fpath=("$ZUSH_COMPLETIONS_DIR" "${fpath[@]}")
    zush_debug "Added completions directory to FPATH: $ZUSH_COMPLETIONS_DIR"
fi

# Add user site-functions directory to FPATH
if [[ -d ~/.local/share/zsh/site-functions ]]; then
    fpath=(~/.local/share/zsh/site-functions "${fpath[@]}")
    zush_debug "Added user site-functions to FPATH: ~/.local/share/zsh/site-functions"
fi

# Completion system is initialized early in .zshrc
# Just set up caching optimization here
_zush_manage_completion_cache() {
    local zcompdump="${ZUSH_CACHE_DIR}/.zcompdump"
    local cache_max_age=$((24 * 60 * 60)) # 24 hours
    local zcompdump_fresh=0

    if [[ -f "$zcompdump" ]] && zmodload zsh/stat 2>/dev/null; then
        local now zcompdump_mtime
        (( now = EPOCHSECONDS ))
        zcompdump_mtime=$(zstat -L +mtime -- "$zcompdump" 2>/dev/null)
        if [[ -n "$zcompdump_mtime" ]] && (( zcompdump_mtime >= now - cache_max_age )); then
            zcompdump_fresh=1
        fi
    fi

    if (( zcompdump_fresh )); then
        zush_debug "Completion cache is fresh"
    else
        # Rebuild cache in background to avoid blocking startup
        (compinit -d "$zcompdump" &)
        zush_debug "Rebuilding completion cache in background"
    fi
}

_zush_manage_completion_cache
