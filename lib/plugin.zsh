#!/usr/bin/env zsh
# Zush Plugin System - Minimal and Fast
# Provides simple plugin cloning, compilation, and loading

# Plugin directories
typeset -g ZUSH_PLUGINS_DIR="${ZUSH_HOME:-${ZDOTDIR:-$HOME/.config/zush}}/plugins"
typeset -g ZUSH_PLUGINS_MANIFEST="${ZUSH_CACHE_DIR:-$HOME/.cache/zush}/plugins-manifest"

# Create plugin directory if needed
[[ ! -d "${ZUSH_PLUGINS_DIR}" ]] && mkdir -p "${ZUSH_PLUGINS_DIR}" 2>/dev/null

# Function: _zushp_find_plugin_file
# Find the main plugin file in a repository (or nested directory)
# Parameters:
#   $1: plugin_dir - directory containing the plugin repository
#   $2: target_path - optional path relative to plugin repo root (leading '/' keeps repo-root scope)
# Returns: 0 on success (prints plugin file path), 1 if no plugin file found
_zushp_find_plugin_file() {
    local plugin_dir="$1"
    local target_path="$2"
    local search_dir="$plugin_dir"
    local candidate
    local plugin_dir_abs="${plugin_dir:A}"

    if [[ -n "$target_path" ]]; then
        if [[ "$target_path" == /* ]]; then
            candidate="${plugin_dir}/${target_path#/}"
        else
            candidate="${plugin_dir}/${target_path}"
        fi
        candidate="${candidate:A}"

        case "$candidate" in
            "$plugin_dir_abs"|"$plugin_dir_abs"/*) ;;
            *)
                zush_error "Plugin path '${target_path}' escapes $plugin_dir"
                return 1
                ;;
        esac

        if [[ -f "$candidate" ]]; then
            echo "${candidate:A}"
            return 0
        elif [[ -d "$candidate" ]]; then
            search_dir="$candidate"
        else
            return 1
        fi
    fi

    local repo_name="${search_dir:t}"
    
    # Check for common plugin file patterns in order of preference
    local patterns=(
        "${search_dir}/${repo_name}.plugin.zsh"
        "${search_dir}/plugin.zsh"
        "${search_dir}/${repo_name}.zsh"
        "${search_dir}/init.zsh"
        "${search_dir}"/*.plugin.zsh(N[1])
        "${search_dir}"/*.zsh(N[1])
    )
    
    for pattern in "${patterns[@]}"; do
        [[ -f "$pattern" ]] && { echo "${pattern:A}"; return 0; }
    done
    
    return 1
}

# Function: _zushp_clone_plugin
# Clone a plugin repository from GitHub
# Parameters:
#   $1: user_repo - GitHub repository in 'user/repo' format
# Returns: 0 on success, 1 on clone failure
_zushp_clone_plugin() {
    local user_repo="$1"
    local plugin_name="${user_repo##*/}"
    local plugin_dir="${ZUSH_PLUGINS_DIR}/${plugin_name}"
    local git_url="https://github.com/${user_repo}.git"
    
    if [[ -d "$plugin_dir" ]]; then
        zush_debug "Plugin $plugin_name already exists"
        return 0
    fi
    
    zush_debug "Cloning $user_repo to $plugin_dir"
    
    if git clone --depth=1 --quiet "$git_url" "$plugin_dir" 2>/dev/null; then
        echo "zushp: cloned $user_repo"
        return 0
    else
        zush_error "Failed to clone $user_repo"
        return 1
    fi
}

# Function: _zushp_add_to_manifest
# Add plugin to manifest file for tracking
# Parameters:
#   $1: user_repo - GitHub repository in 'user/repo' format
#   $2: plugin_file - path to the main plugin file
# Returns: 0 on success
_zushp_add_to_manifest() {
    local user_repo="$1"
    local plugin_name="${user_repo##*/}"
    local plugin_file="$2"
    
    # Create manifest if it doesn't exist
    [[ ! -f "$ZUSH_PLUGINS_MANIFEST" ]] && touch "$ZUSH_PLUGINS_MANIFEST"
    
    # Remove existing entry if present
    if grep -q "^${plugin_name}:" "$ZUSH_PLUGINS_MANIFEST" 2>/dev/null; then
        grep -v "^${plugin_name}:" "$ZUSH_PLUGINS_MANIFEST" > "${ZUSH_PLUGINS_MANIFEST}.tmp" 2>/dev/null || true
        [[ -f "${ZUSH_PLUGINS_MANIFEST}.tmp" ]] && mv "${ZUSH_PLUGINS_MANIFEST}.tmp" "$ZUSH_PLUGINS_MANIFEST"
    fi
    
    # Add new entry: plugin_name:user_repo:plugin_file
    echo "${plugin_name}:${user_repo}:${plugin_file}" >> "$ZUSH_PLUGINS_MANIFEST"
}

# Function: zushp
# Main plugin installation function
# Parameters:
#   $1: user_repo - GitHub repository in 'user/repo' format (required)
#       - user: alphanumeric, underscores, hyphens [a-zA-Z0-9_-]+
#       - repo: alphanumeric, underscores, hyphens, dots [a-zA-Z0-9_.-]+
#   $2: plugin_path - optional path relative to the plugin repo root (leading '/' starts at repo root)
# Returns: 0 on success, 1 on validation or installation failure
zushp() {
    local user_repo="$1"
    local plugin_path="$2"

    # Validate user/repo format
    if [[ -z "$user_repo" ]]; then
        zush_error "Usage: zushp <user/repo> [plugin-path] (got: '$user_repo')"
        return 1
    fi

    if [[ ! "$user_repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
        zush_error "Invalid format. Use: zushp <user/repo> (got: '$user_repo')"
        return 1
    fi
    
    local plugin_name="${user_repo##*/}"
    local plugin_dir="${ZUSH_PLUGINS_DIR}/${plugin_name}"
    
    # Clone plugin if not present
    if [[ ! -d "$plugin_dir" ]]; then
        _zushp_clone_plugin "$user_repo" || return 1
    fi
    
    # Find plugin file
    local plugin_file
    if ! plugin_file=$(_zushp_find_plugin_file "$plugin_dir" "$plugin_path"); then
        if [[ -n "$plugin_path" ]]; then
            zush_error "No plugin file found at '$plugin_path' inside $plugin_dir"
        else
            zush_error "No plugin file found in $plugin_dir"
        fi
        return 1
    fi
    
    zush_debug "Found plugin file: $plugin_file"
    
    # Compile plugin file
    if (( ${+functions[_zushc]} )); then
        _zushc "$plugin_file" 2>/dev/null || zush_debug "Compilation failed for $plugin_file"
    fi
    
    # Add to manifest
    _zushp_add_to_manifest "$user_repo" "$plugin_file"
    
    # Source plugin immediately
    zush_debug "Sourcing $plugin_name immediately"
    _zush_source "$plugin_file"
}

# Function: zushp_update
# Update installed plugins
# Parameters:
#   $1: target_plugin - optional plugin name to update (updates all if omitted)
# Returns: 0 on success, 1 if no plugins installed
zushp_update() {
    local target_plugin="$1"
    
    [[ ! -f "$ZUSH_PLUGINS_MANIFEST" ]] && { echo "No plugins installed"; return 1; }
    
    while IFS=: read -r plugin_name user_repo plugin_file; do
        [[ -n "$target_plugin" && "$plugin_name" != "$target_plugin" ]] && continue
        
        local plugin_dir="${ZUSH_PLUGINS_DIR}/${plugin_name}"
        
        if [[ -d "$plugin_dir/.git" ]]; then
            echo "Updating $plugin_name..."
            if (cd "$plugin_dir" && git pull --quiet 2>/dev/null); then
                echo "  ✓ Updated $plugin_name"
                # Recompile after update
                (( ${+functions[_zushc]} )) && _zushc "$plugin_file" 2>/dev/null
            else
                echo "  ✗ Failed to update $plugin_name"
            fi
        else
            echo "  - $plugin_name (not a git repository)"
        fi
    done < "$ZUSH_PLUGINS_MANIFEST"
}

# Function: _zushp_clean
# Clean all plugins and manifest with user confirmation
# Parameters: none
# Returns: 0 on success
_zushp_clean() {
    local confirm
    echo -n "Remove all plugins and cache? [y/N] "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        [[ -d "$ZUSH_PLUGINS_DIR" ]] && rm -rf "$ZUSH_PLUGINS_DIR"
        [[ -f "$ZUSH_PLUGINS_MANIFEST" ]] && rm -f "$ZUSH_PLUGINS_MANIFEST"
        echo "All plugins and cache removed"
        mkdir -p "$ZUSH_PLUGINS_DIR"
    else
        echo "Cancelled"
    fi
}
