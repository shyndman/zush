# Function to query LLM and display with mdcat
q() {
  if [ -z "$1" ]; then
    echo "Usage: ask \"<prompt>\"" >&2
    return 1
  fi
  llm --model=anthropic/claude-sonnet-4-0 $@ | glow
  echo -e "\n\033[1;37mContinue conversation with: llm chat --continue\033[0m"
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
  local result=$(llm complete-command "$old_cmd")
  if [ $? -eq 0 ] && [ ! -z "$result" ]; then
    BUFFER=$result
  else
    BUFFER=$old_cmd
  fi
  zle reset-prompt
}
zle -N __llm_cmdcomp
