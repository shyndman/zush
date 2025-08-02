# Lazy loading for performance-heavy tools
# Sets up lazy loading with environment caching for nvm, pyenv, cargo, and homebrew
#
# TODO: Add eval caching for expensive commands like 'pyenv init -' and 'brew shellenv'
#       These commands can take 50-200ms each and their output rarely changes.
#       We should cache the eval output and provide zush_clear_eval_cache function.

# Node.js via nvm
zush_lazy_load nvm 'source ~/.nvm/nvm.sh' nvm node npm npx

# Python via pyenv  
zush_lazy_load pyenv 'eval "$(pyenv init -)"' pyenv python pip

# Rust via cargo
zush_lazy_load cargo 'source ~/.cargo/env' cargo rustc rustup

# Homebrew
zush_lazy_load brew 'eval "$(/opt/homebrew/bin/brew shellenv)"' brew