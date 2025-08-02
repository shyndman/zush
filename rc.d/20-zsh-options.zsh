# Core zsh behavioral options
# Sets up essential zsh options for better interactive behavior

# Error handling and corrections
setopt CORRECT              # auto correct mistakes
setopt NONOMATCH            # hide error message if there is no match for the pattern

# Interactive features
setopt INTERACTIVECOMMENTS  # allow comments in interactive mode
setopt NOTIFY               # report the status of background jobs immediately
setopt PROMPTSUBST          # enable command substitution in prompt

# Globbing and expansion
setopt EXTENDED_GLOB        # enable extended globbing
setopt GLOB_DOTS            # include dotfiles in globbing
setopt NUMERICGLOBSORT      # sort filenames numerically when it makes sense
setopt MAGICEQUALSUBST      # enable filename expansion for arguments of the form 'anything=expression'

# Job control
setopt AUTO_RESUME          # attempt to resume existing job before creating a new process
setopt LONG_LIST_JOBS       # list jobs in the long format by default

# Completion behavior
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case insensitive completion
zstyle ':completion:*' menu select                         # use menu selection for completions