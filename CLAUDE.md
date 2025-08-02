# Zush - High-Performance ZSH Configuration

## Overview

Zush is a modular, performance-focused zsh configuration system designed to achieve sub-100ms startup times while maintaining full functionality. Built from the ground up with lazy loading, automatic compilation, and smart caching strategies.

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
│   └── lazy-loader.zsh  # generic lazy loading with environment caching
└── rc.d/                # Numbered configuration scripts
    ├── 00-profiling.zsh      # profiling setup
    ├── 10-lazy-tools.zsh     # nvm, pyenv, cargo, homebrew lazy loading
    ├── 20-zsh-options.zsh    # core zsh behavioral options
    ├── 30-history.zsh        # comprehensive history management
    ├── 40-directory-nav.zsh  # directory navigation enhancements
    ├── 41-dev-directories.zsh # development directory shortcuts
    ├── 42-eza.zsh            # modern ls replacement with theme
    ├── 50-editor.zsh         # smart editor selection (local vs remote)
    ├── 60-better-reading.zsh # ov pager, bat, batman integration
    ├── 80-prompt.zsh         # starship prompt with custom config
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
- Per-component load time tracking

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

### Production Setup
1. Set `ZDOTDIR=~/.config/zush`
2. Copy configuration to `~/.config/zush/`
3. Customize rc.d scripts as needed

### Configuration Variables
- `ZUSH_PROFILE=1` - Enable startup profiling
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

**4. Plugin System**
- Standardized third-party plugin integration
- Automatic dependency management
- Plugin performance budgets

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