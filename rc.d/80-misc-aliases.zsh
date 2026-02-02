alias _='sudo'
alias %='whence -p'

# I hate that by default, fd can't find anything
alias fd='fd --no-ignore-vcs'

alias md='mkdir -p'
mdc() { mkdir -p "$1" && cd "$1"; }
alias rm='trash-put'
alias g='git'

# 1Password CLI Run
alias opr='op run --no-masking --env-file .env -- '

# Kittens
alias kssh='kitten ssh'
alias icat="kitten icat"

# Clipboard
alias -g cbcopy='kitten clipboard'
alias -g cbpaste='kitten clipboard --get'
