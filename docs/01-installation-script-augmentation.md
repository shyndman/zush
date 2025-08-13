# Installation Script Augmentation Plan

This document outlines the plan to augment the `install.sh` script to systematically install all software dependencies mentioned in the `rc.d` configuration files.

## Analysis

The goal is to create a comprehensive, interactive installation process. The script will use Homebrew as the primary package manager for a consistent experience on both macOS and Linux.

A critical part of the plan is managing the dependency order. Several tools depend on language runtimes (Python, Node.js) which are themselves managed by version managers (`pyenv`, `nvm`). The plan will therefore proceed in a logical sequence:

1.  **Ensure Homebrew is present.**
2.  **Install language version managers** (`pyenv`, `nvm`, `rustup`).
3.  **Install and configure language runtimes** (Python 3.12, Node stable, Rust stable).
4.  **Install applications** that depend on those runtimes (`claude`, `llm`, `uv`, `hishtory`).
5.  **Install all remaining tools** via Homebrew.

Each installation step will be wrapped in a function that first checks if the tool is already available and, if not, prompts the user for confirmation before proceeding. This "tool-by-tool" confirmation meets the requirements for interactivity.

## Implementation Plan

The following functions and modifications will be added to `install.sh`.

### 1. Update `main` function

A call to the new `install_tools` function will be added to `main`.

```bash
main() {
    # ... (existing code)
    check_shell
    check_dependencies
    install_tools
    handle_existing_installation
    # ... (existing code)
}
```

### 2. Create the `install_tools` orchestrator

This function will define the list of all tools and call their individual installation functions in the correct order.

```bash
# Utility function for interactive confirmation
confirm_install() {
    echo -n "   Install $1? [y/N] "
    read -r response </dev/tty 2>/dev/null || response=""
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

install_tools() {
    log_info "Checking for additional tool dependencies..."

    # Phase 1: Core package manager (Homebrew)
    install_brew

    # Phase 2: Language Version Managers & Runtimes
    install_pyenv_and_python
    install_nvm_and_node
    install_rustup_and_rust

    # Phase 3: Language-dependent tools
    install_hishtory
    install_claude_cli
    install_pip_tools

    # Phase 4: Homebrew-based tools
    local brew_tools=(
        eza fd ripgrep trash-cli glow imagemagick bat bat-extras
        direnv 1password-cli kitty ov
    )
    for tool in "${brew_tools[@]}"; do
        install_brew_tool "$tool"
    done
    
    # Special handling for fzf (may need build-from-source on arm64)
    install_fzf

    log_success "Tool dependency check complete."
}
```

### 3. Implement Language & Tool Installers

A specific function will be created for each installation task, respecting the required method (Homebrew, Pip, Npm, etc.) and dependencies.

#### Homebrew

```bash
install_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_warning "Homebrew is not installed."
        if confirm_install "Homebrew"; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            log_success "Homebrew installed."
        else
            log_error "Cannot proceed without Homebrew."
            return 1
        fi
    fi
}
```

#### Python Environment

```bash
install_pyenv_and_python() {
    if ! command -v pyenv >/dev/null 2>&1; then
        install_brew_tool "pyenv"
    fi
    if command -v pyenv >/dev/null 2>&1 && ! pyenv versions --bare | grep -q "^3.12"; then
        if confirm_install "Python 3.12"; then
            log_info "Installing Python 3.12 via pyenv..."
            pyenv install 3.12
            pyenv global 3.12
            log_success "Python 3.12 installed and set as global default."
        fi
    fi
}
```

#### Node.js Environment

```bash
install_nvm_and_node() {
    if ! command -v nvm >/dev/null 2>&1; then
        install_brew_tool "nvm"
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"
    
    if command -v nvm >/dev/null 2>&1 && ! nvm ls stable >/dev/null 2>&1; then
        if confirm_install "Node.js (stable)"; then
            log_info "Installing stable Node.js via nvm..."
            nvm install stable
            nvm alias default stable
            log_success "Node.js stable installed and set as default."
        fi
    fi
}
```

#### Rust Environment

```bash
install_rustup_and_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        install_brew_tool "rustup-init"
        log_info "Running rustup-init. Please follow the prompts."
        rustup-init -y --no-modify-path
        source "$HOME/.cargo/env"
    fi
    if command -v rustup >/dev/null 2>&1 && ! rustup toolchain list | grep -q "stable"; then
         if confirm_install "Rust (stable toolchain)"; then
            log_info "Installing stable Rust toolchain..."
            rustup default stable
            log_success "Rust stable toolchain installed."
        fi
    fi
}
```

#### Specific Tool Installers

```bash
install_hishtory() {
    if ! command -v hishtory >/dev/null 2>&1; then
        if confirm_install "hishtory"; then
            log_info "Installing hishtory..."
            echo -n "   Please enter your hishtory secret: "
            read -r secret </dev/tty
            if [[ -n "$secret" ]]; then
                export HISHTORY_INSTALL_SECRET="$secret"
                curl https://hishtory.dev/install.py | python3 -
                hishtory init
                log_success "hishtory installed."
            else
                log_error "Hishtory secret cannot be empty. Skipped installation."
            fi
        fi
    fi
}

install_claude_cli() {
    if ! npm list -g | grep -q "@anthropic-ai/claude-code"; then
        if confirm_install "Claude Code CLI"; then
            log_info "Installing @anthropic-ai/claude-code via npm..."
            npm install -g @anthropic-ai/claude-code
            log_success "Claude Code CLI installed."
        fi
    fi
}

install_pip_tools() {
    if ! pip list | grep -q "^llm\s"; then
        if confirm_install "llm CLI"; then
            log_info "Installing llm via pip..."
            pip install llm
            log_success "llm installed."
        fi
    fi
    if ! pip list | grep -q "^uv\s"; then
        if confirm_install "uv (Python package manager)"; then
            log_info "Installing uv via pip..."
            pip install uv
            log_success "uv installed."
        fi
    fi
}
```

#### Special Case: fzf Installation

```bash
install_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then
        if confirm_install "fzf"; then
            log_info "Installing fzf via Homebrew..."
            if brew install fzf 2>/dev/null; then
                log_success "fzf installed."
            else
                log_warning "Standard fzf installation failed (likely no bottle for arm64)."
                log_info "Attempting to build fzf from source (this may take a few minutes)..."
                if brew install --build-from-source fzf; then
                    log_success "fzf installed from source."
                else
                    log_error "Failed to install fzf even from source."
                    return 1
                fi
            fi
        fi
    fi
}
```

### 4. Generic Homebrew Tool Installer

This single function will handle the installation of any tool from the `brew_tools` array.

```bash
install_brew_tool() {
    local tool_name="$1"
    local command_name="${2:-$tool_name}"
    
    if [[ "$tool_name" == "fd" ]]; then
        tool_name="fd-find"
    fi

    if ! command -v "$command_name" >/dev/null 2>&1; then
        if confirm_install "$tool_name"; then
            log_info "Installing $tool_name via Homebrew..."
            brew install "$tool_name"
            log_success "$tool_name installed."
        fi
    fi
}
```

## Tool Installation Summary

### Phase 1: Core Package Manager
| Tool | Installation Method | Notes |
| :--- | :--- | :--- |
| **Homebrew** | Custom Script | Prerequisite for almost everything else. |

### Phase 2: Language Runtimes
| Tool | Installation Method | `rc.d` File Reference | Notes |
| :--- | :--- | :--- | :--- |
| **pyenv** | Homebrew | `10-lazy-tools.zsh` | Installs the Python version manager. |
| ↳ **Python 3.12** | `pyenv install 3.12` | `10-lazy-tools.zsh` | Installs Python and sets it as the global default. |
| **nvm** | Homebrew | `10-lazy-tools.zsh` | Installs the Node.js version manager. |
| ↳ **Node.js** | `nvm install stable` | `10-lazy-tools.zsh` | Installs the latest stable Node.js and sets it as the default. |
| **rustup** | `rustup-init` (via Brew) | `10-lazy-tools.zsh` | Installs the Rust toolchain manager. |
| ↳ **Rust** | `rustup default stable` | `10-lazy-tools.zsh` | Installs the stable Rust toolchain. |

### Phase 3: Language-Dependent Tools
| Tool | Installation Method | `rc.d` File Reference | Notes |
| :--- | :--- | :--- | :--- |
| **hishtory** | Custom Script (`curl...`) | `30-history.zsh` | Requires Python. |
| **claude-code** | `npm install -g` | `82-llms.zsh` | Requires Node.js/npm. |
| **llm** | `pip install` | `82-llms.zsh` | Requires Python/pip. |
| **uv** | `pip install` | `10-lazy-tools.zsh` | Requires Python/pip. |

### Phase 4: General Tools (via Homebrew)
| Tool | Installation Method | `rc.d` File Reference | Notes |
| :--- | :--- | :--- | :--- |
| **eza** | Homebrew | `42-eza.zsh` |
| **fzf** | Special handling | `81-fzf.zsh` | Tries normal brew install, falls back to `--build-from-source` on arm64 |
| **fd** | Homebrew (`fd-find`) | `81-fzf.zsh` |
| **ripgrep** | Homebrew | `81-fzf.zsh` |
| **trash-cli** | Homebrew | `80-misc-aliases.zsh` |
| **glow** | Homebrew | `82-llms.zsh` |
| **imagemagick** | Homebrew | `81-fzf.zsh` |
| **bat** | Homebrew | `60-better-reading.zsh` |
| **bat-extras** | Homebrew | `60-better-reading.zsh` |
| **direnv** | Homebrew | `98-shell-hooks.zsh` |
| **1password-cli**| Homebrew | `80-misc-aliases.zsh` |
| **kitty** | Homebrew | `80-misc-aliases.zsh` |
| **ov** | Homebrew | `60-better-reading.zsh` |
