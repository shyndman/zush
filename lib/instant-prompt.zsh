#!/usr/bin/env zsh
# Zush Instant Prompt System
# Shows fast starship prompt immediately, then hands off to real starship after loading

# Configuration
typeset -g ZUSH_INSTANT_STARSHIP_CONFIG="${HOME}/.config/starship/instant-starship.toml"

# Show instant prompt if conditions are met
zush_show_instant_prompt() {
    # Skip instant prompt if debugging or profiling
    [[ "${ZUSH_PROFILE:-0}" == "1" || "${ZUSH_DEBUG:-0}" == "1" ]] && return

    # Skip if not interactive shell
    [[ ! -o interactive ]] && return

    # Skip if starship not available
    (( ! ${+commands[starship]} )) && return

    # Skip if instant config doesn't exist
    [[ ! -f "$ZUSH_INSTANT_STARSHIP_CONFIG" ]] && return

    # Generate and show instant prompt
    local instant_prompt
    if instant_prompt=$(STARSHIP_CONFIG="$ZUSH_INSTANT_STARSHIP_CONFIG" starship prompt --logical-path="$PWD" --status=0 2>/dev/null); then
        if [[ "${ZUSH_DEBUG:-0}" == "1" ]]; then
            # Debug mode - show what we would print but don't actually print it
            zush_debug "Would show instant prompt: ${instant_prompt}"
            return
        fi

        # Save cursor position
        echo -ne "\x1b7"

        # Output the instant prompt (use print -P to interpret zsh prompt codes)
        print -P -n "$instant_prompt"

        # Mark that we showed an instant prompt (for handoff)
        typeset -g _ZUSH_INSTANT_PROMPT_SHOWN=1

        zush_debug "Instant prompt displayed"
    else
        zush_debug "Failed to generate instant prompt"
        # Don't render anything if starship fails
    fi
}

# Handle handoff from instant to real prompt
zush_handoff_to_real_prompt() {
    # Only do handoff if we showed an instant prompt
    [[ "${_ZUSH_INSTANT_PROMPT_SHOWN:-0}" != "1" ]] && return

    # Return to start of line and let real starship overwrite
    echo -ne "\x1b8" # Just return to start, real prompt will overwrite

    # Unset the marker
    unset _ZUSH_INSTANT_PROMPT_SHOWN

    zush_debug "Handed off to real starship prompt"
}
