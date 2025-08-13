#!/usr/bin/env zsh
# Zush Installation Script
# Mid-Performance ZSH Configuration
#
# Usage: curl -fsSL https://raw.githubusercontent.com/user/zush/main/install.sh | zsh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ZUSH_REPO="https://github.com/shyndman/zush.git"
ZUSH_DIR="$HOME/.config/zush"
ZSHENV_FILE="$HOME/.zshenv"
STARSHIP_DIR="$HOME/.config/starship"

# Utility functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }

# Shell detection with insults
check_shell() {
    if [[ -n "$BASH_VERSION" ]] || [[ "$0" =~ bash$ ]]; then
        log_error "You moron! This is a ZSH configuration installer."
        echo "   Run it properly: ${YELLOW}curl -fsSL <url> | zsh${NC}"
        exit 1
    fi

    if [[ -n "$SH_VERSION" ]] || [[ "$0" =~ /sh$ ]]; then
        log_error "You moron! This is a ZSH configuration installer."
        echo "   Run it properly: ${YELLOW}curl -fsSL <url> | zsh${NC}"
        exit 1
    fi

    # Check if we're actually running in zsh
    if [[ -z "$ZSH_VERSION" ]]; then
        log_error "This script must be run with zsh!"
        echo "   Try: ${YELLOW}curl -fsSL <url> | zsh${NC}"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v git >/dev/null 2>&1; then
        log_error "git is required but not installed."
        echo "   Install git first, then try again."
        exit 1
    fi

    if ! command -v zsh >/dev/null 2>&1; then
        log_error "zsh is required but not installed."
        echo "   Install zsh first, then try again."
        exit 1
    fi

    if ! command -v starship >/dev/null 2>&1; then
        log_warning "starship is not installed."
        echo "   Zush will work without it, but instant prompts require starship."
        echo "   Install from: https://starship.rs/"
        echo ""
    fi

    log_success "Dependencies checked"
}

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
    install_llm_plugins

    # Phase 4: Homebrew-based tools
    local brew_tools=(
        eza fzf fd ripgrep trash-cli glow imagemagick bat bat-extras
        direnv ov btop git-delta starship
    )
    for tool in "${brew_tools[@]}"; do
        install_brew_tool "$tool"
    done

    log_success "Tool dependency check complete."
}

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

install_pyenv_and_python() {
    if ! command -v pyenv >/dev/null 2>&1; then
        install_brew_tool "pyenv"
    fi
    
    # Initialize pyenv in the current shell if available
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
    fi
    
    if command -v pyenv >/dev/null 2>&1 && ! pyenv versions --bare | grep -q "^3.12"; then
        if confirm_install "Python 3.12"; then
            log_info "Installing Python 3.12 via pyenv..."
            pyenv install 3.12
            pyenv global 3.12
            pyenv shell 3.12
            log_success "Python 3.12 installed and set as global default."
        fi
    fi
}

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

install_rustup_and_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        install_brew_tool "rustup-init"
        if command -v rustup-init >/dev/null 2>&1; then
            log_info "Running rustup-init. Please follow the prompts."
            rustup-init -y --no-modify-path
            source "$HOME/.cargo/env"
        fi
    fi
    if command -v rustup >/dev/null 2>&1 && ! rustup toolchain list | grep -q "stable"; then
         if confirm_install "Rust (stable toolchain)"; then
            log_info "Installing stable Rust toolchain..."
            rustup default stable
            log_success "Rust stable toolchain installed."
        fi
    fi
}

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

install_llm_plugins() {
    if ! command -v llm >/dev/null 2>&1; then
        return
    fi

    log_info "Checking for llm plugins..."

    local llm_plugins=(
        "llm-anthropic"
        "llm-gemini"
        "git+https://github.com/shyndman/llm-complete-command.git"
    )

    for plugin in "${llm_plugins[@]}"; do
        local plugin_name
        plugin_name=$(basename "$plugin" .git)
        if ! llm plugins | grep -q "$plugin_name"; then
            if confirm_install "llm plugin: $plugin_name"; then
                log_info "Installing $plugin_name via llm..."
                llm install -U "$plugin"
                log_success "$plugin_name installed."
            fi
        fi
    done
}

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

# Handle existing installation
handle_existing_installation() {
    if [[ -d "$ZUSH_DIR" ]]; then
        log_warning "Zush is already installed at $ZUSH_DIR"
        echo -n "   Remove existing installation and reinstall? [y/N] "
        read -r response </dev/tty 2>/dev/null || response=""
        case "$response" in
            [yY][eE][sS]|[yY])
                log_info "Removing existing installation..."
                rm -rf "$ZUSH_DIR"
                ;;
            *)
                log_info "Installation cancelled."
                exit 0
                ;;
        esac
    fi
}

# Backup existing .zshenv
backup_zshenv() {
    if [[ -f "$ZSHENV_FILE" ]]; then
        local backup_file="${ZSHENV_FILE}.old"

        log_warning "Existing .zshenv file detected: $ZSHENV_FILE"
        echo "   Zush requires replacing your .zshenv to set ZDOTDIR=~/.config/zush"
        echo "   Your current .zshenv will be renamed to: ${YELLOW}.zshenv.old${NC}"
        echo ""
        echo -n "   Proceed with renaming your .zshenv? [y/N] "
        read -r response </dev/tty 2>/dev/null || response=""
        case "$response" in
            [yY][eE][sS]|[yY])
                log_info "Backing up existing .zshenv to .zshenv.old"
                ;;
            *)
                log_error "Cannot install Zush without replacing .zshenv"
                echo "   Installation cancelled."
                exit 1
                ;;
        esac

        if [[ -f "$backup_file" ]]; then
            log_warning "Backup file already exists: $backup_file"
            echo -n "   Overwrite existing .zshenv.old backup? [y/N] "
            read -r response </dev/tty 2>/dev/null || response=""
            case "$response" in
                [yY][eE][sS]|[yY]) ;;
                *)
                    log_error "Cannot proceed without backing up .zshenv"
                    exit 1
                    ;;
            esac
        fi

        cp "$ZSHENV_FILE" "$backup_file"
        log_success "Backed up .zshenv to .zshenv.old"
    fi
}

# Clone repository
clone_repository() {
    log_info "Cloning Zush repository..."

    if ! git clone --depth=1 "$ZUSH_REPO" "$ZUSH_DIR" 2>/dev/null; then
        log_error "Failed to clone repository"
        echo "   Check your internet connection and try again."
        exit 1
    fi

    log_success "Repository cloned to $ZUSH_DIR"
}

# Install .zshenv
install_zshenv() {
    log_info "Installing .zshenv..."

    local source_zshenv="$ZUSH_DIR/home/.zshenv"
    if [[ ! -f "$source_zshenv" ]]; then
        log_error "Source .zshenv not found: $source_zshenv"
        exit 1
    fi

    cp "$source_zshenv" "$ZSHENV_FILE"
    chmod 644 "$ZSHENV_FILE"

    log_success "Installed .zshenv"
}

# Check starship configuration
check_starship_config() {
    log_info "Checking starship configuration..."

    if [[ ! -d "$STARSHIP_DIR" ]]; then
        log_warning "Starship config directory not found: $STARSHIP_DIR"
        echo "   Instant prompts will not work without starship configuration."
        echo "   Set up starship first: https://starship.rs/config/"
        return
    fi

    local starship_config="$STARSHIP_DIR/starship.toml"
    if [[ ! -f "$starship_config" ]]; then
        log_warning "Starship config not found: $starship_config"
        echo "   Instant prompts will not work without starship configuration."
        return
    fi

    # Create instant-starship.toml if it doesn't exist
    local instant_config="$STARSHIP_DIR/instant-starship.toml"
    if [[ ! -f "$instant_config" ]]; then
        log_info "Creating instant starship configuration..."
        echo -n "   Create instant-starship.toml for faster prompts? [Y/n] "
        read -r response </dev/tty 2>/dev/null || response=""
        case "$response" in
            [nN][oO]|[nN])
                log_info "Skipping instant starship config"
                return
                ;;
            *)
                # Copy existing config and append disable rules
                cat "$starship_config" > "$instant_config"
                cat >> "$instant_config" << 'EOF'

# Disable slow modules for instant prompts
[git_branch]
disabled = true

[git_status]
disabled = true

[git_state]
disabled = true

[git_metrics]
disabled = true

[git_commit]
disabled = true

[cmd_duration]
disabled = true

[package]
disabled = true

[docker_context]
disabled = true

[kubernetes]
disabled = true

[terraform]
disabled = true

[aws]
disabled = true

[gcloud]
disabled = true

[env_var]
disabled = true
EOF
                log_success "Created instant starship configuration"
                ;;
        esac
    else
        log_info "Instant starship config already exists"
    fi
}

# Show success message
show_success() {
    echo ""
    log_success "Zush installed successfully! 🦥"
    echo ""
    echo "Next steps:"
    echo "  1. ${YELLOW}Restart your shell${NC} or run: source ~/.zshenv"
    echo "  2. ${YELLOW}Test startup time${NC}: ZUSH_PROFILE=1 zsh -c exit"
    echo "  3. ${YELLOW}Install plugins${NC}: zushp user/repo"
    echo ""
    echo "Commands:"
    echo "  ${BLUE}zushp <user/repo>${NC}     - Install plugin"
    echo "  ${BLUE}zushp_update${NC}          - Update all plugins"
    echo "  ${BLUE}zushc file.zsh${NC}        - Compile zsh file"
    echo ""
    echo "Configuration:"
    echo "  ${BLUE}~/.config/zush/${NC}       - Main configuration"
    echo "  ${BLUE}~/.config/zush/rc.d/${NC}  - Modular configs"
    echo ""
    if [[ -f "${ZSHENV_FILE}.old" ]]; then
        echo "Your old .zshenv was backed up to: ${YELLOW}${ZSHENV_FILE}.old${NC}"
        echo ""
    fi
}

# Rollback on error
rollback() {
    log_error "Installation failed, rolling back..."

    # Remove Zush directory
    [[ -d "$ZUSH_DIR" ]] && rm -rf "$ZUSH_DIR"

    # Restore .zshenv backup
    if [[ -f "${ZSHENV_FILE}.old" ]]; then
        mv "${ZSHENV_FILE}.old" "$ZSHENV_FILE"
        log_info "Restored original .zshenv"
    fi

    exit 1
}

# Main installation
main() {
    # Set up error handling
    trap rollback ERR

    echo "${BLUE}"
    echo "╔═════════════════════════════════════════╗"
    echo "║            Zush Installer               ║"
    echo "║     Mid-Performance 🦥 ZSH Config       ║"
    echo "╚═════════════════════════════════════════╝"
    echo "${NC}"

    sleep 1

    check_shell
    check_dependencies
    install_tools
    handle_existing_installation
    backup_zshenv
    clone_repository
    install_zshenv
    check_starship_config
    show_success
}

# Run main function
main "$@"
