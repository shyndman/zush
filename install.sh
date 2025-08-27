#!/usr/bin/env zsh
# Zush TUI Installer Bootstrap
# Usage: curl -fsSL https://raw.githubusercontent.com/shyndman/zush/main/install.sh | zsh

set -e

# Colors for output  
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }

# Check what's missing and ask for confirmation
check_and_confirm_deps() {
    local missing=()
    
    if ! command -v git >/dev/null 2>&1; then
        log_error "git is required but not installed."
        exit 1
    fi
    
    if ! command -v brew >/dev/null 2>&1; then
        missing+=("Homebrew")
    fi
    
    if ! command -v uv >/dev/null 2>&1; then
        missing+=("uv package manager")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        printf "The installer requires "
        for i in "${!missing[@]}"; do
            if [[ $i -eq 0 ]]; then
                printf "%s" "${missing[$i]}"
            elif [[ $i -eq $((${#missing[@]} - 1)) ]] && [[ ${#missing[@]} -gt 1 ]]; then
                printf ", and %s" "${missing[$i]}"
            else
                printf ", %s" "${missing[$i]}"
            fi
        done
        printf ". Can we install those for you now? [y/N] "
        
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_error "Installation cancelled."
            exit 1
        fi
        echo ""
    fi
}

# Install Homebrew if not present
install_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        log_success "Homebrew installed"
    fi
}

# Install Python3 via Homebrew
install_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        log_info "Installing Python3..."
        brew install python3
        log_success "Python3 installed"
    fi
}

# Install uv package manager
install_uv() {
    if ! command -v uv >/dev/null 2>&1; then
        log_info "Installing uv..."
        brew install uv
        log_success "uv installed"
    fi
}

# Clone zush repository
clone_zush() {
    local zush_dir="$HOME/.config/zush"
    if [[ -d "$zush_dir" ]]; then
        log_info "Removing existing zush installation..."
        rm -rf "$zush_dir"
    fi
    
    log_info "Cloning zush repository..."
    git clone --depth=1 "https://github.com/shyndman/zush.git" "$zush_dir"
    log_success "Repository cloned to $zush_dir"
}

# Launch TUI installer
launch_tui() {
    log_info "Launching TUI installer..."
    cd "$HOME/.config/zush"
    uv run install_tui.py
}

main() {
    echo -e "${BLUE}Zush Bootstrap Installer${NC}"
    echo "Setting up environment..."
    echo ""
    
    check_and_confirm_deps
    install_homebrew  
    install_uv
    clone_zush
    launch_tui
}

main "$@"