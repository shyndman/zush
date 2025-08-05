# History configuration
# Sets up comprehensive history management with large buffer and smart deduplication

# History file location
HISTFILE="${ZUSH_HOME}/.zhistory"

# Large history buffers for comprehensive tracking
SAVEHIST=1000000
HISTSIZE=1000000

# History behavior options
setopt extended_history        # save timestamps with history entries
setopt inc_append_history      # write to history file immediately, not on shell exit
setopt hist_expire_dups_first  # expire duplicate entries first when trimming history
setopt hist_ignore_all_dups    # delete old entry if new entry is a duplicate
setopt hist_find_no_dups       # don't display previously found duplicates in search
setopt hist_save_no_dups       # don't write duplicate entries to history file
setopt hist_reduce_blanks      # remove superfluous blanks before recording

# Hishtory integration (optional - only loads if available)
# Note: paths should be customized for your setup
if [[ -f "$HOME/.hishtory/config.zsh" ]]; then
    export HISHTORY_SERVER="${HISHTORY_SERVER:-http://lmnop.don}"
    path=($HOME/.hishtory $path)
    source "$HOME/.hishtory/config.zsh"
fi