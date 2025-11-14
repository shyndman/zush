# Lazy loading for performance-heavy tools
# Sets up lazy loading with environment caching for nvm, pyenv, cargo, and homebrew

# Homebrew - IMPORTANT: This must run before other tools
[[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && \
    zush_lazy_eval brew '/home/linuxbrew/.linuxbrew/bin/brew shellenv' brew

ZUSH_ESP_IDF_EXPORT_SCRIPT=${ZUSH_ESP_IDF_EXPORT_SCRIPT:-~/dev/lib/esp/current/esp-idf/export.sh}

export-esp() {
    if [[ ! -r $ZUSH_ESP_IDF_EXPORT_SCRIPT ]]; then
        zush_error "ESP-IDF export script missing: $ZUSH_ESP_IDF_EXPORT_SCRIPT"
        echo "Install or update ESP-IDF, then retry." >&2
        return 1
    fi

    source "$ZUSH_ESP_IDF_EXPORT_SCRIPT"
}

# Node.js via nvm
[[ -f /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh ]] && \
    zush_lazy_load nvm 'source /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh' nvm node npm npx yarn pnpm

# Python via pyenv
command -v pyenv >/dev/null 2>&1 && \
    zush_lazy_eval pyenv 'pyenv init -' pyenv python pip uv uvx 

# Rust via cargo
[[ -f ~/.cargo/env ]] && \
    zush_lazy_load cargo 'source ~/.cargo/env' cargo rustc rustup

[[ -f $ZUSH_ESP_IDF_EXPORT_SCRIPT ]] && \
    zush_lazy_load esp-idf export-esp esp-idf.py idf.py
