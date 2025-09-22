# Zush 🦥 - Mid-Performance ZSH Configuration

My personal ZSH configuration framework.

A performance-aware ZSH configuration designed for sub-200ms startup times while maintaining full functionality.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/shyndman/zush/main/install.sh | zsh
```

## Features

- **Instant Prompts** - Basic prompt appears immediately, full prompt loads after ~129ms
- **Plugin Management** - Simple `zushp user/repo` command to install GitHub plugins  
- **Lazy Loading** - Tools like nvm, pyenv, cargo load only when needed
- **Auto-compilation** - All ZSH files compiled with zcompile for faster loading
- **Smart Caching** - Environment changes cached for instant startup

## Commands

```bash
zushp user/repo     # Install plugin
zushp_update        # Update all plugins
zush_clean          # Clean all caches and plugins
```

## Performance

Current startup time: ~129ms with instant prompts providing immediate visual feedback.

---

*Mid-performance by design. 🦥*