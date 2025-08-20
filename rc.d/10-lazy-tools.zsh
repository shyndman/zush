# Lazy loading for performance-heavy tools
# Sets up lazy loading with environment caching for nvm, pyenv, cargo, and homebrew

# Homebrew - IMPORTANT: This must run before other tools
[[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && \
    zush_lazy_eval brew '/home/linuxbrew/.linuxbrew/bin/brew shellenv' brew

# Node.js via nvm
[[ -f /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh ]] && \
    zush_lazy_load nvm 'source /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh' nvm node npm npx yarn pnpm

# Python via pyenv
command -v pyenv >/dev/null 2>&1 && \
    zush_lazy_eval pyenv 'pyenv init -' pyenv python pip uv uvx 

# Rust via cargo
[[ -f ~/.cargo/env ]] && \
    zush_lazy_load cargo 'source ~/.cargo/env' cargo rustc rustup
