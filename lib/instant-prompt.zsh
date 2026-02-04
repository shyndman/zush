#!/usr/bin/env zsh
# Zush Instant Prompt System
# Shows fast starship prompt immediately, then hands off to real starship after loading

# Configuration
typeset -g ZUSH_INSTANT_STARSHIP_CONFIG="${HOME}/.config/starship/instant-starship.toml"
typeset -g ZUSH_PROMPT_WAIT_MESSAGE="Startup errors detected. Press any key to continue..."

# Show instant prompt if conditions are met
_zush_show_instant_prompt() {
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
_zush_handoff_to_real_prompt() {
    # Only do handoff if we showed an instant prompt
    [[ "${_ZUSH_INSTANT_PROMPT_SHOWN:-0}" != "1" ]] && return

    # Return to start of line and let real starship overwrite
    echo -ne "\x1b8" # Just return to start, real prompt will overwrite

    # Unset the marker
    unset _ZUSH_INSTANT_PROMPT_SHOWN

    zush_debug "Handed off to real starship prompt"
}

_zush_wait_before_handoff_if_needed() {
    (( ${+functions[_zush_handoff_to_real_prompt]} )) || return

    if [[ "${_ZUSH_INSTANT_PROMPT_SHOWN:-0}" == "1" && "${_ZUSH_STARTUP_ERROR:-0}" == "1" ]]; then
        print -r -- ""
        print -r -- "$ZUSH_PROMPT_WAIT_MESSAGE"

        local _zush_key
        if [[ -n "${ZUSH_PROMPT_WAIT_TEST_INPUT:-}" ]]; then
            _zush_key="$ZUSH_PROMPT_WAIT_TEST_INPUT"
        else
            read -sk 1 _zush_key
        fi
        print -r -- ""

        unset _ZUSH_STARTUP_ERROR
    fi

    _zush_handoff_to_real_prompt
}
