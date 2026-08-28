copy-command-to-clipboard() {
  print -rn -- "$BUFFER" | kitty +kitten clipboard
}

zle -N copy-command-to-clipboard
bindkey $'\eC' copy-command-to-clipboard

