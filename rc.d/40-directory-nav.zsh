# Directory navigation configuration
# Sets up enhanced directory navigation with smart stack management

# Directory navigation options
setopt auto_cd              # change directories without typing `cd`
setopt auto_pushd           # have `cd` add directories to the stack
setopt pushd_ignore_dups    # no duplicates on directory stack
setopt pushd_minus          # exchanges the meanings of '+' and '-' when specifying a directory in the stack

# Use only dots to refer to ancestral directories
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

# Just type '-' to return to previous directory
alias -- -='cd -'

# Navigate through your directory history numerically
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'