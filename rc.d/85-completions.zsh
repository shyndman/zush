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
typeset -g ZUSH_BASH_COMPLETIONS_DIR="${ZUSH_COMPLETIONS_DIR}/bash"

if [[ -d "$ZUSH_COMPLETIONS_DIR" ]]; then
    # Add to beginning of FPATH for priority
    fpath=("$ZUSH_COMPLETIONS_DIR" "${fpath[@]}")
    zush_debug "Added completions directory to FPATH: $ZUSH_COMPLETIONS_DIR"
fi

# Add user ~/.zfunc directory to FPATH
if [[ -d ~/.zfunc ]]; then
    fpath=(~/.zfunc "${fpath[@]}")
    zush_debug "Added user zfunc directory to FPATH: ~/.zfunc"
fi

# Add user site-functions directory to FPATH
if [[ -d ~/.local/share/zsh/site-functions ]]; then
    fpath=(~/.local/share/zsh/site-functions "${fpath[@]}")
    zush_debug "Added user site-functions to FPATH: ~/.local/share/zsh/site-functions"
fi

# Mirror non-root-owned fpath directories when running as root (if configured via zstyle)
_zush_mirror_insecure_completions
