#### Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# # Check dependencies first: magick for image list, fd/rg for fzf commands
if ! command -v magick > /dev/null 2>&1; then
  echo "Warning: magick command not found. Skipping fzf image preview configuration." >&2
  echo "         Install ImageMagick for image previews in fzf." >&2
elif ! command -v fd > /dev/null 2>&1 || ! command -v rg > /dev/null 2>&1; then
  echo "Warning: fd or rg command not found. Skipping fzf preview configuration." >&2
  echo "         Install fd-find and ripgrep for fzf file finding and preview support." >&2
else
  # Set fzf commands using fd
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_CTRL_R_OPTS="--height 50% --preview 'echo {3..} | bat --color=always -pl sh' --preview-window 'wrap,up,5'"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

  # Set fzf options to use the preview function
  export FZF_DEFAULT_OPTS=" \
    --preview 'fzf-preview.sh {}' \
    --bind 'ctrl-/:change-preview-window(down|hidden|right|)' \
    --bind '?:toggle-preview' \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-y:execute-silent(echo {} | pbcopy)+abort' \
    --bind 'ctrl-e:execute(echo {} | xargs -o \$EDITOR)+abort' \
    --color fg:-1,bg:-1,hl:230,fg+:3,bg+:233,hl+:229 \
    --color info:150,prompt:110,spinner:150,pointer:167,marker:174 \
    --height 80% --layout=reverse --border"

  # Optional: Define a function for ripgrep + fzf + bat/icat preview
  # Usage: rgf <pattern>
  rvfs() {
    rg --line-number --no-heading --color=always "${1:-}" |
      fzf --ansi \
          --delimiter ':' \
          --preview 'fzf_preview.sh {1}' \
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' # Adjust preview window as needed
  }
fi
