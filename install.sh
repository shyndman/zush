#!/usr/bin/env zsh
# Zush Installation Script
# Mid-Performance ZSH Configuration
#
# Usage: curl -fsSL https://raw.githubusercontent.com/user/zush/main/install.sh | zsh

set -e # Exit on any error

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
typeset -gi ZUSH_INSTALL_ALL_TOOLS=0

# Rollback owns only changes made by this installer run.
typeset -gi ZUSH_CLONE_STARTED=0
typeset -gi ZUSH_ZSHENV_BACKED_UP=0

# Utility functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }

# Shell detection with insults
check_shell() {
    if [[ -n $BASH_VERSION ]] || [[ $0 =~ bash$ ]]; then
        log_error "You moron! This is a ZSH configuration installer."
        echo "   Run it properly: ${YELLOW}curl -fsSL <url> | zsh${NC}"
        exit 1
    fi

    if [[ -n $SH_VERSION ]] || [[ $0 =~ /sh$ ]]; then
        log_error "You moron! This is a ZSH configuration installer."
        echo "   Run it properly: ${YELLOW}curl -fsSL <url> | zsh${NC}"
        exit 1
    fi

    # Check if we're actually running in zsh
    if [[ -z $ZSH_VERSION ]]; then
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

    check_linux_build_packages

    log_success "Dependencies checked"
}

check_linux_build_packages() {
    if [[ $(uname -s) != "Linux" ]]; then
        return
    fi

    local package_manager=""
    local -a packages
    local -a missing=()

    if command -v apt-get >/dev/null 2>&1 && command -v dpkg >/dev/null 2>&1; then
        package_manager="apt"
        packages=(
            build-essential
            libssl-dev
            zlib1g-dev
            libbz2-dev
            libreadline-dev
            libsqlite3-dev
            libffi-dev
            liblzma-dev
        )
        for pkg in "${packages[@]}"; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                missing+=("$pkg")
            fi
        done
    elif command -v dnf >/dev/null 2>&1 && command -v rpm >/dev/null 2>&1; then
        package_manager="dnf"
        packages=(
            gcc
            gcc-c++
            make
            openssl-devel
            bzip2-devel
            libffi-devel
            zlib-devel
            readline-devel
            sqlite-devel
            xz-devel
        )
        for pkg in "${packages[@]}"; do
            if ! rpm -q "$pkg" >/dev/null 2>&1; then
                missing+=("$pkg")
            fi
        done
    else
        log_warning "Cannot verify Linux build prerequisites automatically. Ensure compiler toolchain and development headers are installed."
        return
    fi

    if ((${#missing[@]} > 0)); then
        log_error "Missing required build packages: ${missing[*]}"
        if [[ $package_manager == "apt" ]]; then
            echo "   Install them with: sudo apt-get update && sudo apt-get install -y ${missing[*]}"
        elif [[ $package_manager == "dnf" ]]; then
            echo "   Install them with: sudo dnf install -y ${missing[*]}"
        fi
        exit 1
    fi
}

# Utility function for interactive confirmation
confirm_install() {
    if ((ZUSH_INSTALL_ALL_TOOLS)); then
        log_info "Automatically accepting installation of $1 (-y)"
        return 0
    fi

    echo -n "   Install $1? [y/N] "
    read -r response </dev/tty 2>/dev/null || response=""
    case "$response" in
    [yY][eE][sS] | [yY]) return 0 ;;
    *) return 1 ;;
    esac
}

install_tools() {
    log_info "Checking for additional tool dependencies..."

    # Phase 1: Core package manager (Homebrew)
    install_brew

    # Phase 2: Homebrew-based tools
    local brew_tools=(
        bat
        bat-extras
        btop
        can1357/tap/omp
        eza
        fd
        git-delta
        go-task
        imagemagick
        moor
        procs
        python-yq
        ripgrep
        rustup
        starship
        trash-cli
        uv
    )
    for tool in "${brew_tools[@]}"; do
        install_brew_tool "$tool"
    done

    # Tools that may need build-from-source on arm64
    install_brew_tool_with_source "fzf"
    install_brew_tool_with_source "glow"
    install_brew_tool_with_source "direnv"
    install_brew_tool_with_source "neovim"

    log_success "Tool dependency check complete."
}

setup_brew_shellenv() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
    fi
}

install_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        log_success "Homebrew installed."
    fi

    setup_brew_shellenv

    if ! command -v brew >/dev/null 2>&1; then
        log_error "Homebrew installation failed."
        exit 1
    fi
}

brew_is_available() {
    command -v brew >/dev/null 2>&1
}

brew_package_installed() {
    local package_name="$1"
    brew_is_available && brew list --versions "$package_name" >/dev/null 2>&1
}

update_user_zshrc_paths() {
    log_info "Ensuring ~/.zshrc configures Homebrew paths..."

    local user_zshrc="$HOME/.zshrc"
    local marker_start="# >>> zush installer path setup >>>"
    local marker_end="# <<< zush installer path setup <<<"

    touch "$user_zshrc"
    chmod 644 "$user_zshrc"

    if grep -q "$marker_start" "$user_zshrc"; then
        if grep -q "$marker_end" "$user_zshrc"; then
            local tmp_file
            tmp_file=$(mktemp) || {
                log_error "Failed to create temp file while updating ~/.zshrc"
                exit 1
            }
            awk -v start="$marker_start" -v end="$marker_end" '
                $0 == start {in_block=1; next}
                in_block && $0 == end {in_block=0; next}
                !in_block {print}
            ' "$user_zshrc" >"$tmp_file"
            mv "$tmp_file" "$user_zshrc"
        fi
    fi

    if [[ -s "$user_zshrc" ]]; then
        printf '\n' >>"$user_zshrc"
    fi

    cat >>"$user_zshrc" <<'EOF'
# >>> zush installer path setup >>>
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
fi

# <<< zush installer path setup <<<
EOF

    log_success "Updated ~/.zshrc with path additions."
}

install_brew_tool() {
    local tool_name="$1"
    local command_name="${2:-$tool_name}"

    if command -v "$command_name" >/dev/null 2>&1 || brew_package_installed "$tool_name"; then
        return
    fi

    if ! brew_is_available; then
        log_error "Homebrew is not available in PATH. Cannot install $tool_name."
        return 1
    fi

    if confirm_install "$tool_name"; then
        log_info "Installing $tool_name via Homebrew..."
        brew install "$tool_name"
        log_success "$tool_name installed."
    fi
}

install_brew_tool_with_source() {
    local tool_name="$1"
    local command_name="${2:-$tool_name}"

    if command -v "$command_name" >/dev/null 2>&1 || brew_package_installed "$tool_name"; then
        return
    fi

    if ! brew_is_available; then
        log_error "Homebrew is not available in PATH. Cannot install $tool_name."
        return 1
    fi

    if ! confirm_install "$tool_name"; then
        return
    fi

    log_info "Installing $tool_name via Homebrew..."
    if brew install "$tool_name"; then
        log_success "$tool_name installed."
        return
    fi

    log_warning "$tool_name failed to install from binaries; retrying from source..."
    if brew install --build-from-source "$tool_name"; then
        log_success "$tool_name installed from source."
    else
        log_error "Failed to install $tool_name even from source."
        return 1
    fi
}

# Handle existing installation
handle_existing_installation() {
    if [[ -d $ZUSH_DIR ]]; then
        log_warning "Zush is already installed at $ZUSH_DIR"
        if ((ZUSH_INSTALL_ALL_TOOLS)); then
            log_info "Declining reinstall automatically (-y); existing installation preserved."
            exit 0
        fi

        echo -n "   Remove existing installation and reinstall? [y/N] "
        read -r response </dev/tty 2>/dev/null || response=""
        case "$response" in
        [yY][eE][sS] | [yY])
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
    if [[ -f $ZSHENV_FILE ]]; then
        local backup_file="${ZSHENV_FILE}.old"

        log_warning "Existing .zshenv file detected: $ZSHENV_FILE"
        echo "   Zush requires replacing your .zshenv to set ZDOTDIR=~/.config/zush"
        echo "   Your current .zshenv will be renamed to: ${YELLOW}.zshenv.old${NC}"
        echo ""
        echo -n "   Proceed with renaming your .zshenv? [y/N] "
        read -r response </dev/tty 2>/dev/null || response=""
        case "$response" in
        [yY][eE][sS] | [yY])
            log_info "Backing up existing .zshenv to .zshenv.old"
            ;;
        *)
            log_error "Cannot install Zush without replacing .zshenv"
            echo "   Installation cancelled."
            exit 1
            ;;
        esac

        if [[ -f $backup_file ]]; then
            log_warning "Backup file already exists: $backup_file"
            echo -n "   Overwrite existing .zshenv.old backup? [y/N] "
            read -r response </dev/tty 2>/dev/null || response=""
            case "$response" in
            [yY][eE][sS] | [yY]) ;;
            *)
                log_error "Cannot proceed without backing up .zshenv"
                exit 1
                ;;
            esac
        fi

        cp "$ZSHENV_FILE" "$backup_file"
        ZUSH_ZSHENV_BACKED_UP=1
        log_success "Backed up .zshenv to .zshenv.old"
    fi
}

# Clone repository
clone_repository() {
    log_info "Cloning Zush repository..."

    ZUSH_CLONE_STARTED=1
    if ! git clone --depth=1 "$ZUSH_REPO" "$ZUSH_DIR" 2>/dev/null; then
        log_error "Failed to clone repository"
        echo "   Check your internet connection and try again."
        rollback
    fi

    log_success "Repository cloned to $ZUSH_DIR"
}

# Install .zshenv
install_zshenv() {
    log_info "Installing .zshenv..."

    local source_zshenv="$ZUSH_DIR/home/.zshenv"
    if [[ ! -f $source_zshenv ]]; then
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

    if [[ ! -d $STARSHIP_DIR ]]; then
        log_warning "Starship config directory not found: $STARSHIP_DIR"
        echo "   Instant prompts will not work without starship configuration."
        echo "   Set up starship first: https://starship.rs/config/"
        return
    fi

    local starship_config="$STARSHIP_DIR/starship.toml"
    if [[ ! -f $starship_config ]]; then
        log_warning "Starship config not found: $starship_config"
        echo "   Instant prompts will not work without starship configuration."
        return
    fi

    # Create instant-starship.toml if it doesn't exist
    local instant_config="$STARSHIP_DIR/instant-starship.toml"
    if [[ ! -f $instant_config ]]; then
        log_info "Creating instant starship configuration..."
        echo -n "   Create instant-starship.toml for faster prompts? [Y/n] "
        read -r response </dev/tty 2>/dev/null || response=""
        case "$response" in
        [nN][oO] | [nN])
            log_info "Skipping instant starship config"
            return
            ;;
        *)
            # Copy existing config and replace slow module tables.
            cat "$starship_config" >"$instant_config"
            STARSHIP_DISABLED_FEATURES=$(echo "# Disable slow modules for instant prompts
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
disabled = true" | tomlq)
            tomlq --toml-roundtrip --in-place ". += $STARSHIP_DISABLED_FEATURES" "$instant_config"
            log_success "Created instant starship configuration"
            ;;
        esac
    else
        log_info "Instant starship config already exists"
    fi
}

# Offer to create machine-specific config
create_zushrc() {
    log_info "Setting up machine-specific configuration..."

    local zushrc_file="$HOME/.zushrc"

    echo ""
    echo "${BLUE}About ~/.zushrc:${NC}"
    echo "  • Machine-specific configuration file for Zush"
    echo "  • Perfect for aliases, paths, and settings unique to this machine"
    echo "  • Loads after all main configs, so it can override anything"
    echo "  • Automatically compiled for performance"
    echo "  • Stays out of version control"
    echo ""

    if [[ -f $zushrc_file ]]; then
        log_info "~/.zushrc already exists, skipping creation"
        return
    fi

    echo -n "   Create ~/.zushrc with example configurations? [Y/n] "
    read -r response </dev/tty 2>/dev/null || response=""
    case "$response" in
    [nN][oO] | [nN])
        log_info "Skipping ~/.zushrc creation"
        echo "   You can create it later with machine-specific configurations"
        ;;
    *)
        log_info "Creating ~/.zushrc with examples..."
        cat >"$zushrc_file" <<'EOF'
# ~/.zushrc - Machine-specific Zush configuration
# This file is loaded after all main rc.d scripts, so it can override anything

# Example: Machine-specific aliases
# alias work='cd ~/work-projects'
# alias personal='cd ~/personal-projects'

# Example: Local development paths
# export ANDROID_HOME=/usr/local/android-sdk
# export PATH="$PATH:$ANDROID_HOME/tools"

# Example: Override prompt for this machine
# export STARSHIP_CONFIG=~/.config/starship-work.toml

# Example: Machine-specific functions
# work_vpn() {
#     sudo wg-quick up work
# }

# Add your machine-specific configurations here...
EOF
        chmod 644 "$zushrc_file"
        log_success "Created ~/.zushrc with example configurations"
        echo "   Edit ~/.zushrc to add your machine-specific settings"
        ;;
    esac
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
    echo "  ${BLUE}~/.zushrc${NC}             - Machine-specific settings"
    echo ""
    if [[ -f "${ZSHENV_FILE}.old" ]]; then
        echo "Your old .zshenv was backed up to: ${YELLOW}${ZSHENV_FILE}.old${NC}"
        echo ""
    fi
}

# Rollback on error
rollback() {
    log_error "Installation failed, rolling back..."

    if ((ZUSH_CLONE_STARTED)) && [[ -d $ZUSH_DIR ]]; then
        log_info "Removing checkout created by this installation"
        rm -rf "$ZUSH_DIR"
    fi

    if ((ZUSH_ZSHENV_BACKED_UP)); then
        mv "${ZSHENV_FILE}.old" "$ZSHENV_FILE"
        log_info "Restored original .zshenv"
    fi

    exit 1
}

# Main installation
main() {
    local option
    local OPTIND=1
    while getopts ":y" option; do
        case "$option" in
        y) ZUSH_INSTALL_ALL_TOOLS=1 ;;
        *)
            log_error "Unknown option: -$OPTARG"
            echo "Usage: zsh install.sh [-y]"
            return 1
            ;;
        esac
    done

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
    update_user_zshrc_paths
    handle_existing_installation
    backup_zshenv
    clone_repository
    install_zshenv
    check_starship_config
    create_zushrc
    show_success
}

# Run main function
main "$@"
