alias oc='opencode'
alias occ='opencode --continue'

# Queries an LLM, displaying the result with glow
q() {
  if [ -z "$1" ]; then
    echo "Usage: ask \"<prompt>\"" >&2
    return 1
  fi

  llm -o web_search 1 "$@" | glow
  echo -e "Continue conversation with: \033[1;37mllm chat --continue\033[0m"
}

# Provide a ctrl+\ shortcut that attempts to generate your shell command
# based on the description written on the prompt.
bindkey '\e\\' __llm_cmdcomp
__llm_cmdcomp() {
  local old_cmd=$BUFFER
  local cursor_pos=$CURSOR
  if [[ "$old_cmd" =~ ^[[:space:]]*$ ]]; then
    return
  fi

  echo # Start the program on a blank line
  local result=$(llm complete "$old_cmd")
  if [ $? -eq 0 ] && [ ! -z "$result" ]; then
    BUFFER=$result
  else
    BUFFER=$old_cmd
  fi
  zle reset-prompt
}
zle -N __llm_cmdcomp

# Launch Claude with a Chrome DevTools MCP for browser debugging.
# All arguments are passed through to the claude binary.
#
# Usage: claude-chrome [claude args...]
#
# This function:
#   1. Finds an available port for Chrome remote debugging
#   2. Registers a chrome-devtools-mcp server with Claude
#   3. Launches Chrome with remote debugging enabled
#   4. Invokes claude with any provided arguments
#   5. Cleans up the MCP and browser on exit
claude-chrome() {
    local CHROME_DEBUG_PORT_MIN=9222
    local CHROME_DEBUG_PORT_MAX=9322

    local id port mcp_name user_data_dir chrome_pid

    # Generate short random identifier (8 hex chars)
    id=$(head -c 4 /dev/urandom | xxd -p)
    mcp_name="claude-chrome-${id}"
    user_data_dir="/tmp/claude-browser-debug-${id}"

    # Find an available port in the range
    _claude_chrome_find_port() {
        local candidate
        for _ in {1..20}; do
            candidate=$((RANDOM % (CHROME_DEBUG_PORT_MAX - CHROME_DEBUG_PORT_MIN + 1) + CHROME_DEBUG_PORT_MIN))
            if ! ss -tuln 2>/dev/null | grep -q ":${candidate} "; then
                echo "$candidate"
                return 0
            fi
        done
        return 1
    }

    port=$(_claude_chrome_find_port)
    if [[ -z "$port" ]]; then
        echo "Error: Could not find an available port in range ${CHROME_DEBUG_PORT_MIN}-${CHROME_DEBUG_PORT_MAX}" >&2
        return 1
    fi

    # Cleanup function to remove MCP and kill browser
    _claude_chrome_cleanup() {
        echo "Cleaning up claude-chrome session ${id}..." >&2
        claude mcp remove "$mcp_name" 2>/dev/null
        if [[ -n "$chrome_pid" ]] && kill -0 "$chrome_pid" 2>/dev/null; then
            kill "$chrome_pid" 2>/dev/null
        fi
        rm -rf "$user_data_dir" 2>/dev/null
    }
    trap _claude_chrome_cleanup EXIT INT TERM

    # Register the MCP server with Claude
    if ! claude mcp add --transport stdio "$mcp_name" -- \
        npx -y 'chrome-devtools-mcp@latest' "--browserUrl=http://127.0.0.1:${port}"; then
        echo "Error: Failed to add MCP server" >&2
        return 1
    fi

    # Launch Chrome with remote debugging
    google-chrome \
        --remote-debugging-port="$port" \
        --user-data-dir="$user_data_dir" \
        &>/dev/null &
    chrome_pid=$!

    # Give Chrome a moment to start
    sleep 1

    if ! kill -0 "$chrome_pid" 2>/dev/null; then
        echo "Error: Chrome failed to start" >&2
        return 1
    fi

    echo "Started Chrome (PID: ${chrome_pid}) on debug port ${port}" >&2
    echo "MCP server: ${mcp_name}" >&2

    # Invoke claude with pass-through arguments
    claude "$@"
}

# Run claude with dangerous permissions skipped (for automation/testing)
dangerclaude() {
    claude --dangerously-skip-permissions "$@"
}
