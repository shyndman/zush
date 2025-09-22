#!/usr/bin/env zsh
# Zush Update Check System
# Background check for updates, prompt on next shell start if available

# Configuration
typeset -g ZUSH_UPDATE_CHECK_INTERVAL=${ZUSH_UPDATE_CHECK_INTERVAL:-1}  # days
typeset -g ZUSH_UPDATE_CHECK_FILE="${ZUSH_CACHE_DIR}/last-update-check"
typeset -g ZUSH_UPDATE_AVAILABLE_FILE="${ZUSH_CACHE_DIR}/update-available"

# Check if we should run background update check
_zush_should_background_check() {
    # Skip if disabled
    [[ "${ZUSH_UPDATE_CHECK_INTERVAL}" == "0" ]] && return 1

    # Skip if not a git repository
    [[ ! -d "$ZUSH_HOME/.git" ]] && return 1

    # Check if enough time has elapsed
    local current_time=$(date +%s)
    local interval_seconds=$((ZUSH_UPDATE_CHECK_INTERVAL * 24 * 60 * 60))

    if [[ -f "$ZUSH_UPDATE_CHECK_FILE" ]]; then
        local last_check=$(cat "$ZUSH_UPDATE_CHECK_FILE" 2>/dev/null || echo "0")
        local time_since_check=$((current_time - last_check))

        [[ $time_since_check -ge $interval_seconds ]] && return 0
    else
        # No check file exists, time to check
        return 0
    fi

    return 1
}

# Background update check (runs in background process)
_zush_background_update_check() {
    local current_time=$(date +%s)
    echo "$current_time" > "$ZUSH_UPDATE_CHECK_FILE"

    local current_dir="$PWD"
    cd "$ZUSH_HOME" || return 1

    # Fetch latest changes silently
    if ! git fetch origin main --quiet 2>/dev/null; then
        cd "$current_dir"
        return 1
    fi

    # Check if updates are available
    local local_commit=$(git rev-parse HEAD 2>/dev/null)
    local remote_commit=$(git rev-parse origin/main 2>/dev/null)

    cd "$current_dir"

    if [[ "$local_commit" != "$remote_commit" ]]; then
        # Update available - write to file with timestamp
        echo "$current_time" > "$ZUSH_UPDATE_AVAILABLE_FILE"
    else
        # No update - remove available file if it exists
        [[ -f "$ZUSH_UPDATE_AVAILABLE_FILE" ]] && rm -f "$ZUSH_UPDATE_AVAILABLE_FILE"
    fi
}

# Start background update check if needed
_zush_start_update_check() {
    if _zush_should_background_check; then
        zush_debug "Starting background update check"
        (_zush_background_update_check &) &!
    fi
}

# Check if update is available and prompt user
_zush_prompt_available_update() {
    # Skip if not interactive
    [[ ! -o interactive ]] && return

    # Skip if debugging/profiling
    [[ "${ZUSH_PROFILE:-0}" == "1" || "${ZUSH_DEBUG:-0}" == "1" ]] && return

    # Check if update is available
    if [[ -f "$ZUSH_UPDATE_AVAILABLE_FILE" ]]; then
        echo ""
        echo "🦥 Zush update available!"
        echo -n "   Update now? [Y/n] "
        read -r response

        case "$response" in
            [nN][oO]|[nN])
                echo "   Update postponed. You'll be reminded next time."
                ;;
            *)
                echo "   Updating Zush..."
                local current_dir="$PWD"
                cd "$ZUSH_HOME" || return 1

                if git pull --quiet 2>/dev/null; then
                    echo "   ✅ Zush updated successfully!"
                    echo "   Restart your shell to use the latest version."
                    # Remove update available file
                    rm -f "$ZUSH_UPDATE_AVAILABLE_FILE"
                else
                    echo "   ⚠️  Update failed. Try manually: cd ~/.config/zush && git pull"
                fi
                cd "$current_dir"
                ;;
        esac
        echo ""
    fi
}

# Manual update check command
update-zush() {
    # Force an immediate update check regardless of interval
    zush_debug "Running manual update check"
    
    # Perform the check (reusing background check logic)
    if _zush_background_update_check; then
        # Check if update is available and prompt user (ignoring debug/profile flags)
        # Skip if not interactive
        [[ ! -o interactive ]] && return
        
        # Check if update is available
        if [[ -f "$ZUSH_UPDATE_AVAILABLE_FILE" ]]; then
            echo ""
            echo "🦥 Zush update available!"
            echo -n "   Update now? [Y/n] "
            read -r response

            case "$response" in
                [nN][oO]|[nN])
                    echo "   Update postponed. You'll be reminded next time."
                    ;;
                *)
                    echo "   Updating Zush..."
                    local current_dir="$PWD"
                    cd "$ZUSH_HOME" || return 1

                    if git pull --quiet 2>/dev/null; then
                        echo "   ✅ Zush updated successfully!"
                        echo "   Restart your shell to use the latest version."
                        # Remove update available file
                        rm -f "$ZUSH_UPDATE_AVAILABLE_FILE"
                    else
                        echo "   ⚠️  Update failed. Try manually: cd ~/.config/zush && git pull"
                    fi
                    cd "$current_dir"
                    ;;
            esac
            echo ""
        else
            echo "🦥 Zush is already up to date!"
        fi
    else
        echo "🦥 Failed to check for updates. Check your internet connection."
        return 1
    fi
}
