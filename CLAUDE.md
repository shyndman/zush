# Zush - Mid-Performance ZSH Configuration

## Overview

Zush is a modular, performance-aware zsh configuration system designed to achieve sub-200ms startup times while maintaining full functionality. Built from the ground up with lazy loading, automatic compilation, smart caching strategies, and instant prompts.

## Current Implementation

### Architecture

**Core Structure:**
```
~/.config/zush/           # ZDOTDIR
├── .zshrc               # Main orchestrator
├── lib/                 # Utility libraries
│   ├── core.zsh         # foundational functions (zush_debug, zush_error, zush_source)
│   ├── profiler.zsh     # performance measurement tools
│   ├── compiler.zsh     # automatic zcompile functionality
│   ├── lazy-loader.zsh  # generic lazy loading with environment caching
│   ├── plugin.zsh       # plugin management system (zushp commands)
│   └── instant-prompt.zsh # instant prompt system
├── plugins/             # Third-party plugins (managed by zushp)
├── completions/         # Custom completions directory
│   ├── _zushp           # Plugin manager completions
│   └── _zushc           # Compiler completions
├── home/                # Files to copy to user's home
│   └── .zshenv          # Environment setup for ZDOTDIR
├── install.sh           # Remote installation script
└── rc.d/                # Numbered configuration scripts
    ├── 00-profiling.zsh      # profiling setup
    ├── 10-lazy-tools.zsh     # nvm, pyenv, cargo, homebrew lazy loading
    ├── 15-plugins.zsh        # personal plugin loading
    ├── 20-zsh-options.zsh    # core zsh behavioral options
    ├── 30-history.zsh        # comprehensive history management
    ├── 40-directory-nav.zsh  # directory navigation enhancements
    ├── 41-dev-directories.zsh # development directory shortcuts
    ├── 42-eza.zsh            # modern ls replacement with theme
    ├── 50-editor.zsh         # smart editor selection (local vs remote)
    ├── 60-better-reading.zsh # ov pager, bat, batman integration
    ├── 70-ffmpeg.zsh         # ffmpeg utilities with smart stereo downmix
    ├── 80-prompt.zsh         # starship prompt with custom config
    ├── 85-completions.zsh    # completion system setup
    ├── 98-shell-hooks.zsh    # shell environment integration (direnv)
    └── 99-profiling-end.zsh  # startup timing results
```

### Key Performance Features

**1. Lazy Loading with Environment Caching**
- Tools like nvm, pyenv, cargo, and homebrew are lazy-loaded on first use
- Environment changes (PATH, FPATH, env vars) are cached for instant application on startup
- Eliminates 500-800ms of startup overhead from tool initialization

**2. Automatic Compilation**
- All .zsh files are automatically compiled with zcompile for faster loading
- Smart cache invalidation based on file modification times
- Background compilation to avoid blocking startup

**3. Modular Configuration**
- Numbered rc.d scripts for predictable load order
- Easy to enable/disable components by renaming files
- Clean separation of concerns for maintainability

**4. Performance Monitoring**
- Built-in profiling with zprof integration
- Startup timing benchmarks with `ZUSH_PROFILE=1`
- Per-component load time tracking with millisecond precision
- Debug logging with timing when profiling is enabled

**5. Instant Prompt System**
- Shows basic starship prompt immediately on shell start
- Uses stripped-down starship config with slow modules disabled
- Seamless handoff to full prompt after Zush loads (~73ms)
- ANSI cursor positioning for multiline prompt support

**6. Plugin Management**
- Simple `zushp user/repo` command to install GitHub plugins
- Automatic git cloning, compilation, and sourcing
- Plugin update system with `zushp_update`
- Clean removal with `zushp_clean`

**7. Completion System**
- Custom completions directory with FPATH integration
- Late-loading completion system after tools are initialized
- Tab completion for Zush commands (`zushp`, `zushc`)
- 24-hour cached compinit for faster startup

### Current Performance

**Achieved startup time: 75.616ms**
- Modular architecture with automatic compilation
- Lazy loading for heavy tools
- Smart environment caching

## Technical Implementation Details

### Lazy Loading Strategy
```zsh
# Example: nvm lazy loading
zush_lazy_load nvm 'source ~/.nvm/nvm.sh' nvm node npm npx
```
- Creates placeholder functions for specified commands
- On first use: removes placeholders, initializes tool, caches environment, calls real command
- Subsequent uses go directly to real commands (zero overhead)

### Environment Caching
- Captures PATH/FPATH/env var changes in clean subshell
- Stores diffs in `~/.cache/zush/tool-env` files
- Applies cached changes immediately on startup
- Regenerates cache when tools are actually used

### Compilation System
```zsh
# Smart compilation with zushc
zushc file.zsh        # compile single file
zushc directory/      # compile all .zsh files in directory
zushc_all            # compile entire configuration
zushc_bg             # background compilation
```

## Usage

### Development/Testing
```bash
# Test with profiling
ZDOTDIR=$PWD ZUSH_PROFILE=1 zsh

# Compare timing
time env ZDOTDIR=$PWD zsh -c exit
```

### Installation
```bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/shyndman/zush/main/install.sh | zsh
```

### Production Setup
1. Zush automatically sets `ZDOTDIR=~/.config/zush` via `~/.zshenv`
2. Customize rc.d scripts as needed
3. Install plugins with `zushp user/repo`

### Machine-Specific Configuration

**`~/.zushrc` - Local Machine Customization**

For machine-specific configurations that shouldn't be in the main Zush repo, create a `~/.zushrc` file:

```bash
# ~/.zushrc - Machine-specific Zush configuration
# This file is loaded after all main rc.d scripts, so it can override anything

# Machine-specific aliases
alias work='cd ~/work-projects'
alias personal='cd ~/personal-projects'

# Local development paths
export ANDROID_HOME=/usr/local/android-sdk
export PATH="$PATH:$ANDROID_HOME/tools"

# Override prompt for this machine
export STARSHIP_CONFIG=~/.config/starship-work.toml

# Machine-specific functions
work_vpn() {
    sudo openvpn /etc/openvpn/work.conf
}
```

**Benefits:**
- Loads after main configurations (can override settings)
- Automatically compiled for performance (like all Zush files)
- Perfect for machine-specific paths, aliases, and environment variables
- Stays out of version control
- Follows standard `.*rc` naming convention

### Commands
```bash
# Plugin Management
zushp user/repo          # Install plugin from GitHub
zushp_update             # Update all plugins
zushp_update plugin-name # Update specific plugin
zushp_clean              # Remove all plugins

# Compilation
zushc file.zsh           # Compile single file
zushc directory/         # Compile directory
zushc_all               # Compile entire configuration
zushc_bg                # Background compilation
```

### Configuration Variables
- `ZUSH_PROFILE=1` - Enable startup profiling with timing
- `ZUSH_DEBUG=1` - Enable debug logging
- `ZDOTDIR` - Zush configuration directory

## Future Enhancements

### High-Impact Performance Optimizations

**1. Eval Command Caching**
- Cache output of expensive eval commands (`pyenv init -`, `brew shellenv`)
- Potential 50-200ms savings per cached command
- Auto-regenerate cache when tools are updated
- Implementation: `zush_cached_eval pyenv "pyenv init -"`

**2. Completion System Optimization**
- Implement daily compinit cache refresh
- Background completion dump compilation
- Smart completion loading based on available tools
- Target: 100-300ms savings

**3. Conditional Loading**
- Load configurations based on directory context (git repos, project types)
- Skip irrelevant configurations for faster startup
- Tool-specific profiles (development vs production)

### Quality of Life Improvements

**4. Plugin System** ✅ **IMPLEMENTED**
- Simple `zushp user/repo` command for GitHub plugins
- Automatic git cloning, compilation, and sourcing
- Plugin updates with `zushp_update`
- Tab completion for plugin management

**5. Configuration Management**
- `zush update` command for updating themes/configs
- `zush doctor` for configuration health checks
- `zush benchmark` for performance regression testing

**6. Cross-Shell Compatibility**
- Shell-agnostic core utilities
- Bash compatibility layer
- Fish shell integration

### Advanced Features

**7. Intelligent Caching**
- Cross-session state persistence
- Predictive tool loading based on usage patterns
- Network-aware configurations (home vs work)

**8. Modern Tool Integration**
- Enhanced integration with modern CLI tools (bat, exa, fd, rg)
- Automatic tool discovery and configuration
- Theme synchronization across tools

**9. Performance Analytics**
- Startup time regression tracking
- Component-level performance monitoring
- Automated performance optimization suggestions

## Performance Targets

- **Current**: 75ms startup time
- **Near-term goal**: <50ms with eval caching and completion optimization
- **Long-term goal**: <25ms with intelligent caching and conditional loading

## Development Notes

### Testing Strategy
- Profile before/after each optimization
- Maintain compatibility with existing workflows
- Graceful degradation when tools are unavailable

### Code Quality
- Consistent error handling with line numbers
- Comprehensive debug logging
- Clean separation between core utilities and configurations

### Maintenance
- Regular performance regression testing
- Documentation of performance characteristics
- Clear upgrade paths for configuration changes

---

This project demonstrates that shell startup performance and rich functionality are not mutually exclusive. Through careful architecture and smart caching strategies, Zush achieves excellent performance while maintaining the flexibility and power users expect from a modern shell configuration.