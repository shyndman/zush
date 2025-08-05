# Better editing key-bindings

# We alter WORDCHARS (special characters treated the same as [a-zA-Z0-9] for
# subword navigation) so that it behaves more like VS Code does.
#
# This is the default set of wordchars, with /, ., and - removed.
export WORDCHARS='*?[]~=&;!#$%^(){}<>'

zushp marlonrichert/zsh-edit

bindkey -M main "^[[1;3D" backward-subword        # Alt+Left for subword movement
bindkey -M main "^[[1;3C" forward-subword         # Alt+Right for subword movement
bindkey -M main "^[[1;5D" _vscode_backward_word   # Ctrl+Left for VSCode-like word movement
bindkey -M main "^[[1;5C" _vscode_forward_word    # Ctrl+Right for VSCode-like word movement
