# OpenCode Aliases

LW_MODEL='google/gemini-live-2.5-flash'
HW_MODEL='openai/gpt-5.1-codex --variant=high'

alias oc='opencode'
alias occ='opencode --continue'
alias ocrl="opencode run --model=$LW_MODEL"
alias ocrh="opencode run --model=$HW_MODEL"

# Queries an LLM, displaying the result with glow
q() {
  if [ -z "$1" ]; then
    echo "Usage: ask \"<prompt>\"" >&2
    return 1
  fi

  local response status
  response=$(llm -o web_search 1 "$@" 2>&1)
  status=$?

  if [ $status -ne 0 ] && [[ $response == *"Error: Web search is not supported by model"* ]]; then
    response=$(llm "$@" 2>&1)
    status=$?
  fi

  if [ $status -eq 0 ]; then
    printf '%s' "$response" | glow
    echo -e "Continue conversation with: \033[1;37mllm chat --continue\033[0m"
  else
    printf '%s' "$response" >&2
  fi

  return $status
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

# Launch OpenCode with a Firefox DevTools MCP for browser debugging.
# All arguments are passed through to the opencode binary.
#
# Usage: opencode-firefox [opencode args...]
#
# This function:
#   1. Finds an available port for Firefox remote debugging
#   2. Launches Firefox with remote debugging enabled
#   3. Passes MCP config via OPENCODE_CONFIG_CONTENT env var
#   4. Invokes opencode with any provided arguments
#   5. Cleans up the browser on exit
opencode-firefox() {
    local FIREFOX_DEBUG_PORT_MIN=9222
    local FIREFOX_DEBUG_PORT_MAX=9322

    local id port mcp_name user_data_dir firefox_pid mcp_config

    # Generate short random identifier (3 hex chars)
    id=$(head -c 2 /dev/urandom | xxd -p | head -c 3)
    mcp_name="firefox-${id}"
    user_data_dir="/tmp/opencode-firefox-debug-${id}"

    # Find an available port in the range
    _opencode_firefox_find_port() {
        local candidate
        for _ in {1..20}; do
            candidate=$((RANDOM % (FIREFOX_DEBUG_PORT_MAX - FIREFOX_DEBUG_PORT_MIN + 1) + FIREFOX_DEBUG_PORT_MIN))
            if ! ss -tuln 2>/dev/null | grep -q ":${candidate} "; then
                echo "$candidate"
                return 0
            fi
        done
        return 1
    }

    port=$(_opencode_firefox_find_port)
    if [[ -z "$port" ]]; then
        echo "Error: Could not find an available port in range ${FIREFOX_DEBUG_PORT_MIN}-${FIREFOX_DEBUG_PORT_MAX}" >&2
        return 1
    fi

    # Cleanup function to kill browser
    _opencode_firefox_cleanup() {
        echo "Cleaning up opencode-firefox session ${id}..." >&2
        if [[ -n "$firefox_pid" ]] && kill -0 "$firefox_pid" 2>/dev/null; then
            kill "$firefox_pid" 2>/dev/null
        fi
        rm -rf "$user_data_dir" 2>/dev/null
    }
    trap _opencode_firefox_cleanup EXIT INT TERM

    # Construct inline MCP config for chrome-devtools
    mcp_config=$(jq -n \
        --arg name "$mcp_name" \
        --arg url "http://127.0.0.1:${port}" \
        '{
            "$schema": "https://opencode.ai/config.json",
            "mcp": {
                ($name): {
                    "type": "local",
                    "command": ["npx", "-y", "chrome-devtools-mcp@latest", "--browserUrl=\($url)"]
                }
            }
        }')

    mkdir -p "$user_data_dir"

    # Launch Firefox with remote debugging
    firefox-devedition \
        --remote-debugging-port="$port" \
        --profile "$user_data_dir" \
        --no-remote \
        &>/dev/null &
    firefox_pid=$!

    # Give Firefox a moment to start
    sleep 1

    if ! kill -0 "$firefox_pid" 2>/dev/null; then
        echo "Error: Firefox failed to start" >&2
        return 1
    fi

    echo "Started Firefox (PID: ${firefox_pid}) on debug port ${port}" >&2
    echo "MCP server: ${mcp_name}" >&2

    # Invoke opencode with inline MCP config
    OPENCODE_CONFIG_CONTENT="$mcp_config" opencode "$@"
}
