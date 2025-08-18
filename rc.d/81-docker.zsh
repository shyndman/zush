# Docker Compose shortcuts
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcps='docker compose ps'
alias dcex='docker compose exec'

# Docker Compose logs variants
alias dcl='docker compose logs'
alias dclf='docker compose logs --since 0s --follow'
alias dcl30s='docker compose logs --since 30s'
alias dcl5m='docker compose logs --since 5m'
alias dcl10m='docker compose logs --since 10m'
alias dcl1h='docker compose logs --since 1h'