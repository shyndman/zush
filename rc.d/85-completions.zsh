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

# Add user site-functions directory to FPATH
if [[ -d ~/.local/share/zsh/site-functions ]]; then
    fpath=(~/.local/share/zsh/site-functions $fpath)
    zush_debug "Added user site-functions to FPATH: ~/.local/share/zsh/site-functions"
fi

# Completion system is initialized early in .zshrc
# Just set up caching optimization here
local zcompdump="${ZUSH_CACHE_DIR}/.zcompdump"
if [[ -f "$zcompdump" && "$zcompdump" -nt "$zcompdump"(mh+24) ]]; then
    zush_debug "Completion cache is fresh"
else
    # Rebuild cache in background to avoid blocking startup
    (compinit -d "$zcompdump" &)
    zush_debug "Rebuilding completion cache in background"
fi
