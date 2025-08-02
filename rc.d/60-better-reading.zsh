# Better reading tools configuration
# Sets up ov, bat, and bat-extras for enhanced terminal reading experience

# Require both core tools
if ! command -v ov >/dev/null 2>&1 || ! command -v bat >/dev/null 2>&1; then
    return 1
fi

# Ov as primary pager
export PAGER="ov"

# Configure bat to use ov as its pager  
export BAT_PAGER="ov --quit-if-one-screen --header 3"

# Batman for enhanced man pages
eval "$(batman --export-env)"

# Bat-extras aliases
alias bg='batgrep'
alias bd='batdiff' 
alias bw='batwatch'

# Replace cat with bat  
alias cat='bat'