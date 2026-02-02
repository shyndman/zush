alias _='sudo'
alias %='whence -p'

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
