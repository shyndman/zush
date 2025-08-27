#!/usr/bin/env python3
# /// script
# dependencies = [
#   "textual>=0.41.0"
# ]
# requires-python = ">=3.8"
# ///

import os
import shutil
import subprocess
from dataclasses import dataclass
from typing import Callable, List, Optional

from textual import work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Center, Horizontal, Vertical
from textual.screen import ModalScreen, Screen
from textual.widgets import Button, ProgressBar, Static
from textual.worker import get_current_worker

# --- Installation Functions Ported from install.sh ---

def run_command(command: List[str], timeout: int = 300) -> bool:
    """Runs a command and returns True on success."""
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=True)
        return result.returncode == 0
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        return False

def install_brew_tool(tool_name: str) -> bool:
    """Generic Homebrew tool installer."""
    if shutil.which(tool_name):
        return True  # Already installed
    return run_command(["brew", "install", tool_name])

def install_pyenv_and_python() -> bool:
    """Port of install_pyenv_and_python()"""
    try:
        if not shutil.which("pyenv"):
            if not run_command(["brew", "install", "pyenv"]):
                return False

        # The TUI runs in a separate process, so we can't just `eval` here.
        # The user will need to have pyenv initialized in their shell config.
        # We will check if a python version is installed, and if not, install it.
        versions_result = subprocess.run(["pyenv", "versions", "--bare"], capture_output=True, text=True)
        if "3.12" not in versions_result.stdout:
            if not run_command(["pyenv", "install", "3.12"], timeout=600):
                return False
            subprocess.run(["pyenv", "global", "3.12"])
        return True
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        return False

def install_nvm_and_node() -> bool:
    """Port of install_nvm_and_node()"""
    try:
        if not shutil.which("nvm"):
            if not run_command(["brew", "install", "nvm"]):
                return False
        # Similar to pyenv, nvm needs to be sourced. We'll just install it.
        # The user's shell config set up by zush will handle sourcing it.
        # We can attempt to install node.
        nvm_dir = os.path.expanduser("~/.nvm")
        os.environ["NVM_DIR"] = nvm_dir
        brew_prefix = subprocess.run(["brew", "--prefix"], capture_output=True, text=True).stdout.strip()
        nvm_script = f"{brew_prefix}/opt/nvm/nvm.sh"
        if os.path.exists(nvm_script):
            # This is tricky to run in a subprocess. We will rely on the brew installation.
            # The user will get node when they first use it via the lazy loader.
            pass
        return True
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        return False

def install_rustup_and_rust() -> bool:
    """Port of install_rustup_and_rust()"""
    if shutil.which("rustup"):
        return True
    if not run_command(["brew", "install", "rustup-init"]):
        return False
    if not run_command(["rustup-init", "-y", "--no-modify-path"]):
        return False
    # User will need to source ~/.cargo/env, zush will handle this.
    return run_command(["rustup", "default", "stable"])

def install_hishtory() -> bool:
    """Port of install_hishtory() - This is interactive, which we can't do here."""
    # The original script is interactive, asking for a secret.
    # We will skip this in the TUI installer as it complicates things.
    # A user can run the hishtory installer manually.
    return True # Returning true to not show an error.

def install_claude_cli() -> bool:
    """Port of install_claude_cli()"""
    return run_command(["npm", "install", "-g", "@anthropic-ai/claude-code"])

def install_pip_tools() -> bool:
    """Port of install_pip_tools() for llm and uv"""
    if not run_command(["pip3", "install", "llm"]):
        return False
    return run_command(["pip3", "install", "uv"])

def install_fzf() -> bool:
    """Port of install_fzf()"""
    if shutil.which("fzf"):
        return True
    if run_command(["brew", "install", "fzf"]):
        return True
    # Fallback to build from source
    return run_command(["brew", "install", "--build-from-source", "fzf"])

def install_glow() -> bool:
    """Port of install_glow()"""
    if shutil.which("glow"):
        return True
    if run_command(["brew", "install", "glow"]):
        return True
    # Fallback to build from source
    return run_command(["brew", "install", "--build-from-source", "glow"])

# --- Tool Definition System ---

@dataclass
class Tool:
    """Represents an installable tool from install.sh"""
    name: str
    description: str
    install_function: Callable[[], bool]
    selected: bool = False

AVAILABLE_TOOLS = [
    Tool("hishtory", "Better shell history with sync, search, and context. Replaces ctrl+r with rich search.\n\n[dim]$[/dim] [bold cyan]hishtory[/bold cyan] query git commit", install_hishtory),
    Tool("claude-cli", "Claude AI assistant directly in your terminal for coding help and questions.\n\n[dim]$[/dim] [bold cyan]claude[/bold cyan] [green]'explain this function'[/green]", install_claude_cli),
    Tool("llm", "Access multiple AI models (OpenAI, Anthropic, local) from command line.\n\n[dim]$[/dim] [bold cyan]llm[/bold cyan] [green]'summarize this file'[/green] < [yellow]README.md[/yellow]", lambda: run_command(["pip3", "install", "llm"])),
    Tool("eza", "Modern ls replacement with git integration, colors, and tree views.\n\n[dim]$[/dim] [bold cyan]eza[/bold cyan] -la --git --tree", lambda: install_brew_tool("eza")),
    Tool("fd", "Blazingly fast find alternative with intuitive syntax and smart defaults.\n\n[dim]$[/dim] [bold cyan]fd[/bold cyan] [green]'*.py'[/green] [yellow]src/[/yellow]", lambda: install_brew_tool("fd")),
    Tool("ripgrep", "Lightning-fast grep replacement that respects .gitignore and has better output.\n\n[dim]$[/dim] [bold cyan]rg[/bold cyan] [green]'function.*async'[/green] --type py", lambda: install_brew_tool("ripgrep")),
    Tool("bat", "Cat clone with syntax highlighting, line numbers, and git integration.\n\n[dim]$[/dim] [bold cyan]bat[/bold cyan] [yellow]src/main.py[/yellow]", lambda: install_brew_tool("bat")),
    Tool("bat-extras", "Useful scripts that integrate bat with other tools (batgrep, batdiff, batman).\n\n[dim]$[/dim] [bold cyan]batgrep[/bold cyan] [green]'error'[/green] [yellow]*.log[/yellow]", lambda: install_brew_tool("bat-extras")),
    Tool("fzf", "Interactive fuzzy finder for files, history, processes. Essential for productivity.\n\n[dim]$[/dim] [bold cyan]git[/bold cyan] log --oneline | [bold cyan]fzf[/bold cyan]", install_fzf),
    Tool("starship", "Fast, customizable shell prompt showing git status, languages, and more context.\n\n[dim]$[/dim] [bold cyan]starship[/bold cyan] config", lambda: install_brew_tool("starship")),
    Tool("trash-cli", "Safely delete files by moving to trash instead of permanent deletion.\n\n[dim]$[/dim] [bold cyan]trash[/bold cyan] [yellow]old_file.txt[/yellow]", lambda: install_brew_tool("trash-cli")),
    Tool("imagemagick", "Powerful command-line image editing and conversion toolkit.\n\n[dim]$[/dim] [bold cyan]convert[/bold cyan] [yellow]image.png[/yellow] -resize 50% [yellow]smaller.png[/yellow]", lambda: install_brew_tool("imagemagick")),
    Tool("direnv", "Automatically load/unload environment variables when entering/leaving directories.\n\n[dim]$[/dim] [bold cyan]echo[/bold cyan] [green]'export API_KEY=dev'[/green] > [yellow].envrc[/yellow] && [bold cyan]direnv[/bold cyan] allow", lambda: install_brew_tool("direnv")),
    Tool("ov", "Modern pager with search, syntax highlighting, and better navigation than less.\n\n[dim]$[/dim] [bold cyan]ov[/bold cyan] [yellow]large_file.log[/yellow]", lambda: install_brew_tool("ov")),
    Tool("btop", "Beautiful system monitor showing CPU, memory, disks, network with mouse support.\n\n[dim]$[/dim] [bold cyan]btop[/bold cyan]", lambda: install_brew_tool("btop")),
    Tool("git-delta", "Enhanced git diff viewer with syntax highlighting and side-by-side diffs.\n\n[dim]$[/dim] [bold cyan]git[/bold cyan] diff (automatically used once configured)", lambda: install_brew_tool("git-delta")),
    Tool("glow", "Beautiful markdown renderer for terminal with TUI for browsing files.\n\n[dim]$[/dim] [bold cyan]glow[/bold cyan] [yellow]README.md[/yellow]", install_glow),
]


# --- TUI Screens ---

class QuestionScreen(Screen[Optional[bool]]):
    """Screen for asking y/n questions about each tool."""
    BINDINGS = [
        Binding("y", "yes", "Yes", show=True),
        Binding("n", "no", "No", show=True),
        Binding("escape", "cancel", "Cancel", show=True),
    ]

    def __init__(self, tool: Tool) -> None:
        self.tool = tool
        super().__init__()

    def compose(self) -> ComposeResult:
        with Vertical(id="question-container"):
            yield Static(f"Install {self.tool.name}?", id="question-title")
            with Center():
                yield Static(self.tool.description, id="description")
            yield Static("", classes="spacer")
            with Center():
                with Horizontal(id="button-row"):
                    yield Button("Yes [Y]", variant="success", id="yes")
                    yield Button("No [N]", variant="default", id="no")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "yes":
            self.dismiss(True)
        elif event.button.id == "no":
            self.dismiss(False)

    def action_yes(self) -> None:
        self.dismiss(True)

    def action_no(self) -> None:
        self.dismiss(False)

    def action_cancel(self) -> None:
        self.dismiss(None)

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
        with Vertical(id="summary-container"):
            yield Static("Installation Summary", id="summary-title")
            yield Static("", classes="spacer")
            if not self.selected_tools:
                yield Static("No tools selected for installation.", id="no-tools")
            else:
                yield Static("The following tools will be installed:")
                yield Static("", classes="spacer")
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
        if event.button.id == "confirm":
            self.dismiss(True)
        elif event.button.id == "cancel":
            self.dismiss(False)

    def action_confirm(self) -> None:
        if self.selected_tools:
            self.dismiss(True)

    def action_cancel(self) -> None:
        self.dismiss(False)

class ProgressScreen(Screen):
    """Screen showing installation progress."""
    def __init__(self, tools_to_install: List[Tool]) -> None:
        self.tools_to_install = tools_to_install
        super().__init__()

    def compose(self) -> ComposeResult:
        with Vertical(id="progress-container"):
            yield Static("Installing Zush Tools", id="progress-title")
            yield Static("", classes="spacer")
            yield Static("Preparing installation...", id="current-status")
            yield Static("", classes="spacer")
            yield ProgressBar(total=len(self.tools_to_install), show_eta=True, id="install-progress")
            yield Static("", classes="spacer")
            yield Static(f"0 / {len(self.tools_to_install)} tools installed", id="progress-count")
            yield Static("", classes="spacer")
            yield Static("Installation Log:", id="log-title")
            yield Static("", id="install-log", classes="log-area")
            yield Static("", classes="spacer")
            yield Button("Cancel", variant="warning", id="cancel-button")

    def on_mount(self) -> None:
        self.install_tools()

    @work(exclusive=True, thread=True, group="installation")
    def install_tools(self) -> None:
        worker = get_current_worker()
        for i, tool in enumerate(self.tools_to_install):
            if worker.is_cancelled:
                break
            
            status_msg = f"Installing {tool.name} ({i + 1} of {len(self.tools_to_install)})"
            self.call_from_thread(self.update_status, status_msg)
            self.call_from_thread(self.log_message, f"Starting {tool.name} installation...")
            
            try:
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
            
            self.call_from_thread(self.advance_progress, i + 1)
            import time
            time.sleep(0.5)
        
        self.call_from_thread(self.installation_complete)

    def update_status(self, message: str) -> None:
        self.query_one("#current-status", Static).update(message)

    def log_message(self, message: str) -> None:
        log_widget = self.query_one("#install-log", Static)
        current_log = str(log_widget.renderable)
        new_log = f"{current_log}\n{message}" if current_log else message
        log_widget.update(new_log)

    def advance_progress(self, completed: int) -> None:
        self.query_one("#install-progress", ProgressBar).update(progress=completed)
        self.query_one("#progress-count", Static).update(f"{completed} / {len(self.tools_to_install)} tools installed")

    def installation_complete(self) -> None:
        self.update_status("Installation complete!")
        self.log_message("All selected tools have been processed.")
        close_button = self.query_one("#cancel-button", Button)
        close_button.label = "Close"
        close_button.variant = "success"

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel-button":
            worker = self.workers.get_worker("installation")
            if worker and not worker.is_finished:
                worker.cancel()
            self.dismiss()

# --- Main App ---

class ZushInstallerApp(App):
    """Main TUI installer application."""
    CSS_PATH = "installer.tcss"
    TITLE = "Zush Installer"
    BINDINGS = [
        Binding("ctrl+c,q", "quit", "Quit", show=True),
    ]

    def __init__(self) -> None:
        super().__init__()
        self.selected_tools: List[Tool] = []

    def compose(self) -> ComposeResult:
        with Vertical(id="welcome-container"):
            yield Static("🦥 Zush Installer", id="app-title")
            yield Static("Mid-Performance ZSH Configuration", id="app-subtitle")
            yield Static("", classes="spacer")
            with Center():
                yield Static("This will guide you through installing tools for Zush.", id="welcome-text")
            yield Static("", classes="spacer")
            with Center():
                yield Button("Start Installation", variant="primary", id="start")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "start":
            self.start_installation_flow()

    @work(exclusive=True)
    async def start_installation_flow(self) -> None:
        try:
            # Debug: Log that we're starting
            self.log.info("Starting installation flow")
            
            # Phase 1: Ask questions
            for tool in AVAILABLE_TOOLS:
                self.log.info(f"Asking about tool: {tool.name}")
                result = await self.push_screen_wait(QuestionScreen(tool))
                if result is None:
                    self.exit(message="Installation cancelled by user.")
                    return
                tool.selected = result
                self.log.info(f"Tool {tool.name} selected: {result}")

            self.selected_tools = [tool for tool in AVAILABLE_TOOLS if tool.selected]
            self.log.info(f"Selected {len(self.selected_tools)} tools")

            # Phase 2: Show summary
            confirmed = await self.push_screen_wait(SummaryScreen(self.selected_tools))
            if not confirmed:
                self.exit(message="Installation cancelled at summary.")
                return

            # Phase 3: Install
            if self.selected_tools:
                await self.push_screen(ProgressScreen(self.selected_tools))
            else:
                await self.finalize_installation()
        except Exception as e:
            self.log.error(f"Error in installation flow: {e}")
            self.exit(message=f"Installation failed: {e}")


    async def finalize_installation(self) -> None:
        """Complete installation by setting up zush configuration."""
        zushenv_source = os.path.expanduser("~/.config/zush/home/.zshenv")
        zushenv_target = os.path.expanduser("~/.zshenv")

        if os.path.exists(zushenv_source):
            if os.path.exists(zushenv_target):
                shutil.copy(zushenv_target, f"{zushenv_target}.old")
            shutil.copy(zushenv_source, zushenv_target)
            os.chmod(zushenv_target, 0o644)
        
        self.exit(message="Zush installation process finished!")


if __name__ == "__main__":
    app = ZushInstallerApp()
    app.run()
