#!/usr/bin/env zsh
# Zush Plugin System - Minimal and Fast
# Provides simple plugin cloning, compilation, and loading

# Plugin directories
typeset -g ZUSH_PLUGINS_DIR="${ZUSH_HOME:-${ZDOTDIR:-$HOME/.config/zush}}/plugins"
typeset -g ZUSH_PLUGINS_MANIFEST="${ZUSH_CACHE_DIR:-$HOME/.cache/zush}/plugins-manifest"

# Create plugin directory if needed
[[ ! -d "${ZUSH_PLUGINS_DIR}" ]] && mkdir -p "${ZUSH_PLUGINS_DIR}" 2>/dev/null

# Find the main plugin file in a repository
_zushp_find_plugin_file() {
    local plugin_dir="$1"
    local repo_name="${plugin_dir:t}"
    
    # Check for common plugin file patterns in order of preference
    local patterns=(
        "${plugin_dir}/${repo_name}.plugin.zsh"
        "${plugin_dir}/plugin.zsh"
        "${plugin_dir}/${repo_name}.zsh"
        "${plugin_dir}/init.zsh"
        "${plugin_dir}"/*.plugin.zsh(N[1])
        "${plugin_dir}"/*.zsh(N[1])
    )
    
    for pattern in "${patterns[@]}"; do
        [[ -f "$pattern" ]] && { echo "$pattern"; return 0; }
    done
    
    return 1
}

# Clone a plugin repository
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

# Add plugin to manifest for tracking
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

# Main plugin function
zushp() {
    local user_repo="$1"
    
    [[ -z "$user_repo" ]] && { echo "Usage: zushp <user/repo>"; return 1; }
    
    local plugin_name="${user_repo##*/}"
    local plugin_dir="${ZUSH_PLUGINS_DIR}/${plugin_name}"
    
    # Clone plugin if not present
    if [[ ! -d "$plugin_dir" ]]; then
        _zushp_clone_plugin "$user_repo" || return 1
    fi
    
    # Find plugin file
    local plugin_file
    if ! plugin_file=$(_zushp_find_plugin_file "$plugin_dir"); then
        zush_error "No plugin file found in $plugin_dir"
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

# Update plugins
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

# Clean all plugins
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

