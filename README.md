# Zush 🦥 - Mid-Performance ZSH Configuration

[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/shyndman/zush/main.svg)](https://results.pre-commit.ci/latest/github/shyndman/zush/main)

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

## Development

### Pre-commit checks

1. Install the tooling dependencies: `pre-commit`, `shellcheck`, and `shfmt` (Homebrew: `brew install pre-commit shellcheck shfmt`).
2. Enable hooks locally with `pre-commit install`.
3. Run everything once before sending a PR: `pre-commit run --all-files`.

Hooks currently enforce:
- `shellcheck` (with Zsh-friendly flags) on rc.d scripts, `home/.zshenv`, `install.sh`, and any shell helpers under `scripts/`.
- `shfmt --diff` on Bash-compatible scripts (`install.sh`, `scripts/*.sh`).
- `zsh -n` syntax validation across `.zsh/.sh` sources plus completions.
- A `zcompile` dry run on `lib/*.zsh`, `rc.d/*.zsh`, and `home/.zshenv` to ensure everything remains compilable.

## Performance

Current startup time: ~129ms with instant prompts providing immediate visual feedback.

---

*Mid-performance by design. 🦥*
