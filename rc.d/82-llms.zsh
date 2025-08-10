# Claude Coded
alias claude="/home/shyndman/.claude/local/claude"

# Gemini CLI
export GEMINI_SYSTEM_MD=~/.gemini/prompts/core.md

gemini-mode() {
  local mode="${1:-core}"
  local prompt_file="$HOME/.gemini/prompts/${mode}.md"
  
  if [ -f "$prompt_file" ]; then
    export GEMINI_SYSTEM_MD="$prompt_file"
    echo "Gemini mode set to: $mode"
  else
    echo "Error: Prompt file not found: $prompt_file" >&2
    return 1
  fi
}

# Queries an LLM, displaying the result with glow
q() {
  if [ -z "$1" ]; then
    echo "Usage: ask \"<prompt>\"" >&2
    return 1
  fi

  llm --model=anthropic/claude-sonnet-4-0 $@ | glow
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

  # echo # Start the program on a blank line
  local result=$(llm complete "$old_cmd")
  if [ $? -eq 0 ] && [ ! -z "$result" ]; then
    BUFFER=$result
  else
    BUFFER=$old_cmd
  fi
  zle reset-prompt
}
zle -N __llm_cmdcomp
