# OpenCode Aliases

LW_MODEL='google/gemini-2.5-flash-lite'
HW_MODEL='openai/gpt-5.1-codex'

alias ompc='omp --continue'
alias omprl="omp --model=$LW_MODEL"
alias omprh="omp --model=$HW_MODEL --thinking=high"

alias oc='opencode'
alias occ='opencode --continue'
alias ocrl="opencode run --model=$LW_MODEL"
alias ocrh="opencode run --model=$HW_MODEL --variant=high"

# Queries an LLM, displaying the result with glow.
# Uses llm-tools-exa package (https://github.com/daturkel/llm-tools-exa)
# with -T Exa to provide web search, get_answer, and get_contents tools.
q() {
  if [ $# -eq 0 ]; then
    echo "Usage: q [llm args] -- \"<prompt>\"" >&2
    return 1
  fi

  local -a passthrough_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --)
        shift
        break
        ;;
      -* )
        passthrough_args+=("$1")
        shift
        if [ $# -gt 0 ] && [ "$1" != "--" ] && [[ "$1" != -* ]]; then
          passthrough_args+=("$1")
          shift
        fi
        ;;
      * )
        break
        ;;
    esac
  done

  if [ $# -eq 0 ]; then
    echo "Usage: q [llm args] -- \"<prompt>\"" >&2
    return 1
  fi

  local user_prompt="$*"
  local kernel_release os_release

  if ! kernel_release=$(uname -r 2>/dev/null); then
    kernel_release="unknown"
  fi

  if ! os_release=$(cat /etc/os-release 2>/dev/null); then
    os_release="unknown"
  fi

  local contextual_prompt
  contextual_prompt=$(printf 'System context:\n  Kernel: %s\n  /etc/os-release:\n%s\n\nUser request:\n%s\n' \
    "$kernel_release" "$os_release" "$user_prompt")

  local add_system_prompt=1 arg
  for arg in "${passthrough_args[@]}"; do
    case "$arg" in
      -s|--system|--system=*)
        add_system_prompt=0
        break
        ;;
    esac
  done

  local -a llm_cmd=(llm -T Exa)

  if [ $add_system_prompt -eq 1 ]; then
    llm_cmd+=(--system "You are a helpful assistant appearing in the context of the user's terminal.

		* Please be concise. It's unpleasant for the user to read too much in this environment.
		* Respond quickly — the terminal is blocked awaiting your complete response. Only use search if up-to-date information is required or requested.
		* Use Markdown in your response.")
  fi

  llm_cmd+=("${passthrough_args[@]}")

  local response exit_status
  response=$(printf '%s' "$contextual_prompt" | "${llm_cmd[@]}" 2>&1)
  exit_status=$?

  if [ $exit_status -eq 0 ]; then
    printf '%s' "$response" | glow
    echo -e "Continue conversation with: \033[1;37mllm chat --continue\033[0m"
  else
    printf '%s' "$response" >&2
  fi

  return $exit_status
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
# Usage: opencode-firefox [--url <browser-url>] [opencode args...]
#
# Options:
#   --url <url>  Connect to an already-running browser at this URL (e.g.
#                http://localhost:9222). Skips launching Firefox.
#
# This function:
#   1. Finds an available port for Firefox remote debugging (or uses --url)
#   2. Launches Firefox with remote debugging enabled (unless --url given)
#   3. Passes MCP config via OPENCODE_CONFIG_CONTENT env var
#   4. Invokes opencode with any provided arguments
#   5. Cleans up the browser on exit (unless --url given)
opencode-firefox() {
    local FIREFOX_DEBUG_PORT_MIN=9222
    local FIREFOX_DEBUG_PORT_MAX=9322

    local browser_url="" id port mcp_name user_data_dir firefox_pid mcp_config

    # Parse our own options, leaving the rest for opencode
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)
                browser_url="$2"
                shift 2
                ;;
            --url=*)
                browser_url="${1#--url=}"
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # Generate short random identifier (3 hex chars)
    id=$(head -c 2 /dev/urandom | xxd -p | head -c 3)
    mcp_name="firefox-${id}"

    if [[ -n "$browser_url" ]]; then
        # Connect to an existing browser — no launch, no cleanup
        mcp_config=$(jq -n \
            --arg name "$mcp_name" \
            --arg url "$browser_url" \
            '{
                "$schema": "https://opencode.ai/config.json",
                "mcp": {
                    ($name): {
                        "type": "local",
                        "command": ["npx", "-y", "chrome-devtools-mcp@latest", "--browserUrl=\($url)"]
                    }
                }
            }')

        echo "Connecting to existing browser at ${browser_url}" >&2
        echo "MCP server: ${mcp_name}" >&2

        OPENCODE_CONFIG_CONTENT="$mcp_config" opencode "$@"
        return $?
    fi

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
