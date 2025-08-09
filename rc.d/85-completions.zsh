# Zush Completions System

# Tab-completion behavior
zstyle ':completion:*' matcher-list \
    'm:{[:lower:]}={[:upper:]}' \
    '+r:|[._-]=* r:|=*' \
    '+l:|=*'
zstyle ':completion:*' menu select # use menu selection for completions

# Sets up completion loading and custom completions directory. Runs late in
# startup sequence after tools and environments are set up

# Add Zush completions directory to FPATH
typeset -g ZUSH_COMPLETIONS_DIR="${ZUSH_HOME}/completions"

if [[ -d "$ZUSH_COMPLETIONS_DIR" ]]; then
    # Add to beginning of FPATH for priority
    fpath=("$ZUSH_COMPLETIONS_DIR" $fpath)
    zush_debug "Added completions directory to FPATH: $ZUSH_COMPLETIONS_DIR"
fi

# Initialize completion system if not already done
if [[ -z "${_comps_loaded:-}" ]]; then
    # Load completions
    autoload -Uz compinit

    # Use cached .zcompdump if it's fresh (less than 24 hours old)
    local zcompdump="${ZUSH_CACHE_DIR}/.zcompdump"
    if [[ -f "$zcompdump" && "$zcompdump" -nt "$zcompdump"(mh+24) ]]; then
        compinit -C -d "$zcompdump"
        zush_debug "Used cached completions"
    else
        compinit -d "$zcompdump"
        zush_debug "Rebuilt completion cache"
    fi

    # Mark as loaded
    typeset -g _comps_loaded=1
fi
