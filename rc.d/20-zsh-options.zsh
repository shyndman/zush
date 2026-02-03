# Core zsh behavioral options
# Sets up essential zsh options for better interactive behavior

# Error handling and corrections
unsetopt correct              # auto correct mistakes
setopt nonomatch            # hide error message if there is no match for the pattern

# Interactive features
setopt interactivecomments  # allow comments in interactive mode
setopt notify               # report the status of background jobs immediately
setopt HIST_IGNORE_SPACE    # commands with leading spaces are not written to history

# Globbing and expansion
setopt extended_glob        # enable extended globbing
setopt glob_dots            # include dotfiles in globbing
setopt numericglobsort      # sort filenames numerically when it makes sense
setopt magicequalsubst      # enable filename expansion for arguments of the form 'anything=expression'

# Job control
setopt auto_resume          # attempt to resume existing job before creating a new process
setopt long_list_jobs       # list jobs in the long format by default
