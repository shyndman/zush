# Better editing key-bindings

# We alter WORDCHARS (special characters treated the same as [a-zA-Z0-9] for
# subword navigation) so that it behaves more like VS Code does.
#
# This is the default set of wordchars, with /, ., and - removed.
export WORDCHARS='*?[]~=&;!#$%^(){}<>'

zushp marlonrichert/zsh-edit

# VSCode-like word movement functions
_vscode_backward_word() {
    # Move backward by word, but stop at more boundaries than shell words
    # This mimics VSCode's Ctrl+Left behavior
    local WORDCHARS_SAVE=$WORDCHARS
    WORDCHARS='*?[]~=&;!#$%^(){}<>/'  # Add / back for path navigation
    zle backward-word
    WORDCHARS=$WORDCHARS_SAVE
}

_vscode_forward_word() {
    # Move forward by word, but stop at more boundaries than shell words  
    # This mimics VSCode's Ctrl+Right behavior
    local WORDCHARS_SAVE=$WORDCHARS
    WORDCHARS='*?[]~=&;!#$%^(){}<>/'  # Add / back for path navigation
    zle forward-word
    WORDCHARS=$WORDCHARS_SAVE
}

# Register the custom widgets
zle -N _vscode_backward_word
zle -N _vscode_forward_word

# Widget for inserting newlines
_insert_newline() {
    LBUFFER="${LBUFFER}
"
}
zle -N _insert_newline

# Movement keys
bindkey -M main "^[[1;3D" backward-subword        # Alt+Left for subword movement
bindkey -M main "^[[1;3C" forward-subword         # Alt+Right for subword movement  
bindkey -M main "^[[1;5D" _vscode_backward_word   # Ctrl+Left for VSCode-like word movement
bindkey -M main "^[[1;5C" _vscode_forward_word    # Ctrl+Right for VSCode-like word movement

# Newline insertion
bindkey -M main "^[^M" _insert_newline            # Alt+Enter for newline

# Fix deletion logic: Alt=subword (precise), Ctrl=word (larger chunks)
# Override zsh-edit's defaults which are backwards
bindkey -M main "^[[3;3~" kill-subword            # Alt+Delete for subword deletion
bindkey -M main "^[[27;3;8~" backward-kill-subword # Alt+Backspace for subword deletion  
bindkey -M main "^[^?" backward-kill-subword      # Alt+Backspace (alternative sequence)

bindkey -M main "^[[3;5~" kill-word               # Ctrl+Delete for word deletion
bindkey -M main "^[[27;5;8~" backward-kill-word   # Ctrl+Backspace for word deletion
bindkey -M main "^H" backward-kill-word           # Ctrl+Backspace (alternative sequence)

# Fix Ctrl+W to delete single words instead of entire quoted sections
bindkey -M main "^W" backward-kill-subword

