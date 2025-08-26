# TUI Installer Redesign

## Overview

Redesign the `install.sh` script to work as a bootstrap that sets up basic tools (Homebrew, Python3, uv), clones zush to `~/.config`, then launches a Textual-based Python TUI for interactive installation.

The key design change is **front-loading all questions**, then showing an overview for approval, followed by unattended installation. This replaces the current approach of interspersed prompts throughout the installation process.

## Requirements

**Bootstrap Phase (Shell Script):**
- Install Homebrew → Python3 → uv package 
- Clone zush to ~/.config
- Launch Python TUI with `uv run`

**TUI Phase (Python with Textual):**
- Front-load all tool selection questions (y/n flow, one at a time)
- Show tool descriptions/benefits during selection
- Display summary of selected tools for approval/rejection
- Execute installation without further user interaction
- Render fancy progress bars during installation
- Handle installation failures by exiting (no retry)
- Skip .zushrc creation entirely

## Technical Feasibility Assessment

**Risk Factors:**
- **Low Risk:** Bootstrap dependencies (Homebrew, Python, uv) are stable
- **Medium Risk:** Textual TUI complexity for progress rendering during shell commands
- **Low Risk:** uv script format is well-documented and straightforward

**Complexity Reality Check:**
- **Moderate complexity** - This is achievable but requires careful async handling
- **Potential rabbit hole:** Getting real-time progress from shell commands into Textual widgets
- **Mitigation:** Simple progress indicators showing "X of Y tools installed"

## Verified Implementation Plan with Detailed APIs

### 1. Bootstrap Shell Script (`install.sh` replacement)

**Purpose:** Minimal bootstrap to set up Python environment and launch TUI

```bash
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

# Check dependencies
check_deps() {
    if ! command -v git >/dev/null 2>&1; then
        log_error "git is required but not installed."
        exit 1
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
        pip3 install uv
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
    echo "Setting up Python environment..."
    echo ""
    
    check_deps
    install_homebrew  
    install_python
    install_uv
    clone_zush
    launch_tui
}

main "$@"
```

### 2. TUI Installer (`install_tui.py`) - Complete Implementation

**PEP 723 Dependencies:**[^1]
```python
#!/usr/bin/env python3
# /// script
# dependencies = [
#   "textual>=0.41.0"
# ]
# requires-python = ">=3.8"
# ///
```

**Tool Definition System:**
```python
from dataclasses import dataclass
from typing import List, Callable
import subprocess

@dataclass
class Tool:
    """Represents an installable tool from install.sh"""
    name: str
    description: str
    install_function: Callable
    selected: bool = False
    
# Port all install.sh functions to Tool definitions
AVAILABLE_TOOLS = [
    Tool("pyenv", "Python version manager for multiple Python versions", install_pyenv_and_python),
    Tool("nvm", "Node.js version manager for multiple Node versions", install_nvm_and_node), 
    Tool("rustup", "Rust toolchain installer and version manager", install_rustup_and_rust),
    Tool("hishtory", "Better shell history across machines", install_hishtory),
    Tool("claude-cli", "Claude AI command-line interface", install_claude_cli),
    Tool("llm", "Large Language Model CLI tool", install_pip_tools),
    Tool("eza", "Modern replacement for 'ls' with colors", lambda: install_brew_tool("eza")),
    Tool("fd", "Simple, fast alternative to 'find'", lambda: install_brew_tool("fd")),
    Tool("ripgrep", "Ultra-fast text search tool", lambda: install_brew_tool("ripgrep")),
    Tool("bat", "Cat with syntax highlighting and Git integration", lambda: install_brew_tool("bat")),
    Tool("fzf", "Fuzzy finder for command line", install_fzf),
    Tool("starship", "Cross-shell prompt with customizable themes", lambda: install_brew_tool("starship")),
    # ... Continue with all 20+ tools from install.sh
]
```

**Question Screen Implementation:**[^2]
```python
from textual.app import App, ComposeResult
from textual.screen import Screen
from textual.widgets import Button, Static
from textual.containers import Vertical, Horizontal, Center
from textual.binding import Binding

class QuestionScreen(Screen[bool]):
    """Screen for asking y/n questions about each tool."""
    
    # Key bindings for keyboard navigation
    BINDINGS = [
        Binding("y", "yes", "Yes", show=True),
        Binding("n", "no", "No", show=True), 
        Binding("escape", "cancel", "Cancel", show=True),
    ]
    
    def __init__(self, tool: Tool) -> None:
        self.tool = tool
        super().__init__()
    
    def compose(self) -> ComposeResult:
        """Create the question UI using Textual widgets."""
        with Vertical(id="question-container"):
            yield Static(f"Install {self.tool.name}?", id="question-title")
            yield Static(self.tool.description, id="description")
            yield Static("", classes="spacer")  # Empty spacer
            
            with Center():
                with Horizontal(id="button-row"):
                    yield Button("Yes [Y]", variant="success", id="yes")
                    yield Button("No [N]", variant="default", id="no")
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button press events."""
        if event.button.id == "yes":
            self.dismiss(True)
        elif event.button.id == "no": 
            self.dismiss(False)
    
    def action_yes(self) -> None:
        """Handle 'y' key binding."""
        self.dismiss(True)
    
    def action_no(self) -> None:
        """Handle 'n' key binding."""
        self.dismiss(False)
        
    def action_cancel(self) -> None:
        """Handle escape key - cancel installation."""
        self.dismiss(None)
```

**Summary Screen Implementation:**[^3]
```python
from textual.screen import ModalScreen

class SummaryScreen(ModalScreen[bool]):
    """Screen showing selected tools for final confirmation."""
    
    BINDINGS = [
        Binding("enter", "confirm", "Install", show=True),
        Binding("escape", "cancel", "Cancel", show=True),
    ]
    
    def __init__(self, selected_tools: List[Tool]) -> None:
        self.selected_tools = selected_tools
        super().__init__()
    
    def compose(self) -> ComposeResult:
        """Create the summary confirmation UI."""
        with Vertical(id="summary-container"):
            yield Static("Installation Summary", id="summary-title")
            yield Static("", classes="spacer")
            
            if not self.selected_tools:
                yield Static("No tools selected for installation.", id="no-tools")
            else:
                yield Static("The following tools will be installed:")
                yield Static("", classes="spacer")
                
                # List each selected tool
                for tool in self.selected_tools:
                    yield Static(f"• {tool.name} - {tool.description}", classes="tool-item")
                
                yield Static("", classes="spacer")
                yield Static(f"Total: {len(self.selected_tools)} tool(s)", id="total-count")
            
            yield Static("", classes="spacer")
            
            with Center():
                with Horizontal(id="summary-buttons"):
                    if self.selected_tools:
                        yield Button("Install [Enter]", variant="success", id="confirm")
                    yield Button("Cancel [Esc]", variant="error", id="cancel")
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle summary screen button events.""" 
        if event.button.id == "confirm":
            self.dismiss(True)
        elif event.button.id == "cancel":
            self.dismiss(False)
    
    def action_confirm(self) -> None:
        """Handle enter key - proceed with installation."""
        if self.selected_tools:
            self.dismiss(True)
    
    def action_cancel(self) -> None:
        """Handle escape key - cancel installation."""
        self.dismiss(False)
```

**Progress Screen Implementation:**[^4]
```python
from textual.widgets import ProgressBar
from textual import work
from textual.worker import get_current_worker

class ProgressScreen(Screen):
    """Screen showing installation progress with fancy UI."""
    
    def __init__(self, tools_to_install: List[Tool]) -> None:
        self.tools_to_install = tools_to_install
        self.current_tool_index = 0
        super().__init__()
    
    def compose(self) -> ComposeResult:
        """Create the progress installation UI."""
        with Vertical(id="progress-container"):
            yield Static("Installing Zush Tools", id="progress-title") 
            yield Static("", classes="spacer")
            
            # Current tool being installed
            yield Static("Preparing installation...", id="current-status")
            yield Static("", classes="spacer")
            
            # Progress bar with ETA
            yield ProgressBar(
                total=len(self.tools_to_install),
                show_bar=True,
                show_percentage=True, 
                show_eta=True,
                id="install-progress"
            )
            
            yield Static("", classes="spacer")
            yield Static("0 / 0 tools installed", id="progress-count")
            yield Static("", classes="spacer")
            
            # Installation log
            yield Static("Installation Log:", id="log-title")
            yield Static("", id="install-log", classes="log-area")
            
            yield Static("", classes="spacer")
            yield Button("Cancel", variant="warning", id="cancel", disabled=True)
    
    def on_mount(self) -> None:
        """Start installation when screen loads."""
        self.install_tools()
    
    @work(exclusive=True, thread=True, group="installation")
    def install_tools(self) -> None:
        """Background worker to install tools sequentially.""" 
        for i, tool in enumerate(self.tools_to_install):
            # Update current status
            status_msg = f"Installing {tool.name} ({i + 1} of {len(self.tools_to_install)})"
            self.call_from_thread(self.update_status, status_msg)
            self.call_from_thread(self.log_message, f"Starting {tool.name} installation...")
            
            try:
                # Execute the tool's installation function  
                success = tool.install_function()
                
                if success:
                    log_msg = f"✓ {tool.name} installed successfully"
                    self.call_from_thread(self.log_message, log_msg)
                else:
                    log_msg = f"✗ {tool.name} installation failed"  
                    self.call_from_thread(self.log_message, log_msg)
                    
            except Exception as e:
                error_msg = f"✗ {tool.name} error: {str(e)}"
                self.call_from_thread(self.log_message, error_msg)
            
            # Update progress
            self.call_from_thread(self.advance_progress, i + 1)
            
            # Brief pause for visual feedback
            import time
            time.sleep(0.5)
        
        # Installation complete
        self.call_from_thread(self.installation_complete)
    
    def update_status(self, message: str) -> None:
        """Update current status message (thread-safe)."""
        self.query_one("#current-status", Static).update(message)
    
    def log_message(self, message: str) -> None:
        """Add message to installation log (thread-safe)."""
        log_widget = self.query_one("#install-log", Static)
        current_log = str(log_widget.renderable)
        new_log = f"{current_log}\n{message}" if current_log else message
        log_widget.update(new_log)
    
    def advance_progress(self, completed: int) -> None:
        """Update progress bar and counter (thread-safe)."""
        progress_bar = self.query_one("#install-progress", ProgressBar)
        progress_bar.update(progress=completed)
        
        count_widget = self.query_one("#progress-count", Static) 
        count_widget.update(f"{completed} / {len(self.tools_to_install)} tools installed")
    
    def installation_complete(self) -> None:
        """Handle installation completion (thread-safe)."""
        self.update_status("Installation complete!")
        self.log_message("All tools have been processed.")
        
        # Enable close button
        close_button = self.query_one("#cancel", Button)
        close_button.label = "Close"
        close_button.variant = "success"
        close_button.disabled = False
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle cancel/close button."""
        if event.button.id == "cancel":
            # Cancel installation or close when complete
            worker = get_current_worker()
            if worker and not worker.is_finished:
                worker.cancel()
            self.dismiss()
```

**Main App Implementation:**[^5]
```python
class ZushInstallerApp(App):
    """Main TUI installer application."""
    
    CSS_PATH = "installer.tcss"  # External CSS file
    TITLE = "Zush Installer" 
    
    BINDINGS = [
        Binding("ctrl+c", "quit", "Quit", show=False),
        Binding("q", "quit", "Quit", show=True),
    ]
    
    def __init__(self) -> None:
        super().__init__()
        self.selected_tools: List[Tool] = []
    
    def compose(self) -> ComposeResult:
        """Create the welcome screen."""
        with Vertical(id="welcome-container"):
            yield Static("🦥 Zush Installer", id="app-title")
            yield Static("Mid-Performance ZSH Configuration", id="app-subtitle") 
            yield Static("", classes="spacer")
            yield Static("This installer will guide you through selecting and installing tools for Zush.", id="welcome-text")
            yield Static("", classes="spacer")
            
            with Center():
                yield Button("Start Installation", variant="primary", id="start")
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle welcome screen button."""
        if event.button.id == "start":
            self.start_installation_flow()
    
    async def start_installation_flow(self) -> None:
        """Begin the installation flow with question sequence."""
        # Phase 1: Ask questions for each tool
        for tool in AVAILABLE_TOOLS:
            question_screen = QuestionScreen(tool)
            result = await self.push_screen_wait(question_screen)
            
            if result is None:  # User cancelled
                self.exit(message="Installation cancelled by user")
                return
            
            tool.selected = result
        
        # Collect selected tools
        self.selected_tools = [tool for tool in AVAILABLE_TOOLS if tool.selected]
        
        # Phase 2: Show summary for confirmation
        summary_screen = SummaryScreen(self.selected_tools)
        confirmed = await self.push_screen_wait(summary_screen)
        
        if not confirmed:
            self.exit(message="Installation cancelled")
            return
        
        # Phase 3: Execute installation
        if self.selected_tools:
            progress_screen = ProgressScreen(self.selected_tools)
            await self.push_screen_wait(progress_screen)
        
        # Phase 4: Complete installation tasks
        await self.finalize_installation()
        
        self.exit(message="Zush installation completed successfully!")
    
    async def finalize_installation(self) -> None:
        """Complete installation by setting up zush configuration."""
        # Install .zshenv (from install.sh:479-492)
        zushenv_source = os.path.expanduser("~/.config/zush/home/.zshenv")
        zushenv_target = os.path.expanduser("~/.zshenv")
        
        if os.path.exists(zushenv_source):
            # Backup existing .zshenv if present
            if os.path.exists(zushenv_target):
                shutil.copy(zushenv_target, f"{zushenv_target}.old")
            
            shutil.copy(zushenv_source, zushenv_target)
            os.chmod(zushenv_target, 0o644)

if __name__ == "__main__":
    app = ZushInstallerApp()
    app.run()
```

### 3. Installation Function Ports

**Convert shell functions to Python subprocess calls:**

```python
import subprocess
import os
import shutil
from pathlib import Path

def install_pyenv_and_python() -> bool:
    """Port of install_pyenv_and_python() from install.sh:142-161"""
    try:
        # Install pyenv via homebrew
        if not shutil.which("pyenv"):
            result = subprocess.run(["brew", "install", "pyenv"], 
                                  capture_output=True, text=True, timeout=300)
            if result.returncode != 0:
                return False
        
        # Initialize pyenv in current process
        pyenv_init = subprocess.run(["pyenv", "init", "-"], 
                                   capture_output=True, text=True)
        if pyenv_init.returncode == 0:
            # Apply pyenv environment changes
            for line in pyenv_init.stdout.split('\n'):
                if line.startswith('export'):
                    key, value = line[7:].split('=', 1)
                    os.environ[key] = value.strip('"\'')
        
        # Check if Python 3.12 is installed
        versions_result = subprocess.run(["pyenv", "versions", "--bare"], 
                                        capture_output=True, text=True)
        if "3.12" not in versions_result.stdout:
            # Install Python 3.12
            install_result = subprocess.run(["pyenv", "install", "3.12"], 
                                          capture_output=True, text=True, timeout=600)
            if install_result.returncode == 0:
                subprocess.run(["pyenv", "global", "3.12"])
                subprocess.run(["pyenv", "shell", "3.12"])
        
        return True
        
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        return False

def install_nvm_and_node() -> bool:
    """Port of install_nvm_and_node() from install.sh:163-178"""
    try:
        # Install nvm via homebrew
        if not shutil.which("nvm"):
            result = subprocess.run(["brew", "install", "nvm"], 
                                  capture_output=True, text=True, timeout=300)
            if result.returncode != 0:
                return False
        
        # Set up NVM environment
        nvm_dir = os.path.expanduser("~/.nvm")
        os.environ["NVM_DIR"] = nvm_dir
        
        # Source nvm.sh if available
        brew_prefix = subprocess.run(["brew", "--prefix"], 
                                    capture_output=True, text=True).stdout.strip()
        nvm_script = f"{brew_prefix}/opt/nvm/nvm.sh"
        
        if os.path.exists(nvm_script):
            # Check if stable node is installed  
            nvm_ls = subprocess.run(["nvm", "ls", "stable"], 
                                   capture_output=True, text=True)
            if nvm_ls.returncode != 0:
                # Install stable node
                subprocess.run(["nvm", "install", "stable"], timeout=600)
                subprocess.run(["nvm", "alias", "default", "stable"])
        
        return True
        
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        return False

def install_brew_tool(tool_name: str) -> bool:
    """Generic Homebrew tool installer - port of install_brew_tool() from install.sh:393-404"""
    try:
        if not shutil.which(tool_name):
            result = subprocess.run(["brew", "install", tool_name], 
                                  capture_output=True, text=True, timeout=300)
            return result.returncode == 0
        return True  # Already installed
        
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        return False

# Continue porting all 26 install functions from install.sh...
```

### 4. CSS Styling (`installer.tcss`)

**Complete CSS for professional TUI appearance:**[^6]

```tcss
/* installer.tcss - Zush Installer Styling */

/* App-wide styles */
App {
    background: $background;
}

/* Welcome screen */
#welcome-container {
    align: center middle;
    width: 80%;
    height: 80%;
}

#app-title {
    text-align: center;
    text-style: bold;
    color: $primary;
    text-size: 2;
}

#app-subtitle {
    text-align: center;
    color: $text-muted;
    text-style: italic;
}

#welcome-text {
    text-align: center;
    color: $text;
    width: 60;
}

/* Question screen styles */
#question-container {
    align: center middle;
    width: 70%;
    height: 70%;
}

#question-title {
    text-align: center;
    text-style: bold;
    color: $success;
    text-size: 1.5;
    margin-bottom: 1;
}

#description {
    text-align: center;
    color: $text-muted;
    margin-bottom: 2;
    width: 50;
}

#button-row {
    align: center middle;
    height: auto;
}

/* Summary screen styles */
#summary-container {
    align: center middle;
    width: 80%;
    height: 80%;
}

#summary-title {
    text-align: center;
    text-style: bold;
    color: $primary;
    text-size: 1.5;
    margin-bottom: 1;
}

.tool-item {
    color: $success;
    margin-left: 2;
    margin-bottom: 0.5;
}

#total-count {
    text-align: center;
    color: $text;
    text-style: bold;
}

#no-tools {
    text-align: center;
    color: $warning;
    text-style: italic;
}

/* Progress screen styles */
#progress-container {
    align: center middle;
    width: 90%;
    height: 90%;
}

#progress-title {
    text-align: center;
    text-style: bold;
    color: $primary;
    text-size: 1.5;
}

#current-status {
    text-align: center;
    color: $text;
    text-style: bold;
}

#install-progress {
    width: 80%;
    margin: 1 0;
}

#progress-count {
    text-align: center;
    color: $text-muted;
}

#log-title {
    color: $text;
    text-style: bold;
    margin-bottom: 0.5;
}

.log-area {
    height: 10;
    width: 80%;
    background: $panel;
    border: round $background;
    scrollbar-size-vertical: 1;
    padding: 1;
    color: $text-muted;
}

/* Button styles */
Button {
    margin: 0 1;
    min-width: 12;
    height: 3;
}

Button.primary {
    background: $primary;
    color: $text;
}

Button.success {
    background: $success;
    color: $text;
}

Button.warning {
    background: $warning;
    color: $text;
}

Button.error {
    background: $error;
    color: $text;
}

Button:hover {
    text-style: bold;
}

/* Utility classes */
.spacer {
    height: 1;
}

.center {
    align: center middle;
}
```

## Implementation Steps

1. **Create bootstrap `install.sh`** - minimal dependency setup
2. **Build TUI skeleton** - screen navigation and basic UI  
3. **Implement tool selection flow** - question screens with descriptions
4. **Add summary confirmation screen** - approval/rejection UI
5. **Create progress installation screen** - background workers + progress bars
6. **Port tool installation logic** - convert shell functions to Python
7. **Add error handling** - subprocess failures, logging, graceful exits
8. **Test full installation flow** - end-to-end validation
9. **Polish UI and messaging** - styling, descriptions, success messages

## File Structure

```
install.sh              # New bootstrap script (50 lines)
install_tui.py         # TUI installer with inline dependencies  
installer.tcss         # CSS styling for TUI
home/.zshenv           # Existing - no changes needed
lib/                   # Existing - no changes needed
rc.d/                  # Existing - no changes needed
```

## API Reference Summary

**Key Textual APIs with URLs:**

1. **Screen Management**[^2] - https://textual.textualize.io/guide/screens/
   - `Screen.compose()`, `App.push_screen_wait()`, `Screen.dismiss()`

2. **Widgets**[^7] - https://textual.textualize.io/widgets/
   - `Button(variant, id)`, `Static(content, id)`, `ProgressBar(total, show_eta)`

3. **Workers**[^4] - https://textual.textualize.io/guide/workers/  
   - `@work(thread=True, exclusive=True)`, `call_from_thread()`

4. **Events**[^8] - https://textual.textualize.io/guide/events/
   - `on_button_pressed()`, `Button.Pressed`, `Binding` key handlers

5. **CSS Styling**[^6] - https://textual.textualize.io/guide/CSS/
   - Color variables, layout properties, widget styling

---

[^1]: PEP 723 inline script metadata - https://docs.astral.sh/uv/guides/scripts/
[^2]: Textual Screen API - https://textual.textualize.io/guide/screens/
[^3]: Textual ModalScreen - https://textual.textualize.io/api/screen/#textual.screen.ModalScreen
[^4]: Textual Workers API - https://textual.textualize.io/guide/workers/
[^5]: Textual App class - https://textual.textualize.io/api/app/
[^6]: Textual CSS Guide - https://textual.textualize.io/guide/CSS/
[^7]: Textual Widgets - https://textual.textualize.io/widgets/
[^8]: Textual Events - https://textual.textualize.io/guide/events/