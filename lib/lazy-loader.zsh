# Zush Lazy Loader
# Provides lazy loading with environment caching for performance tools
#
# Examples:
#   # Set up lazy loading for nvm (loads when you run nvm, node, npm, or npx)
#   zush_lazy_load nvm 'source ~/.nvm/nvm.sh' nvm node npm npx
#
#   # Set up lazy loading for pyenv  
#   zush_lazy_load pyenv 'eval "$(pyenv init -)"' pyenv python pip
#
#   # Set up lazy loading for Homebrew
#   zush_lazy_load brew 'eval "$(/opt/homebrew/bin/brew shellenv)"' brew
#
#   # Check status of lazy-loaded tools
#   zush_lazy_status
#
#   # Clear cache for a specific tool
#   zush_lazy_clear nvm
#
#   # Clear all caches
#   zush_lazy_clear

# Cache environment changes from a tool's initialization
zush_cache_env() {
    local tool="$1"
    local init_command="$2"
    local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
    
    zush_debug "Caching environment for $tool"
    
    # Capture environment in a clean subshell
    {
        # Get baseline environment
        local baseline_path=(${path[@]})
        local baseline_fpath=(${fpath[@]})
        local baseline_env=$(printenv | sort)
        
        # Source the tool and capture changes
        eval "$init_command" >/dev/null 2>&1
        
        local new_path=(${path[@]})
        local new_fpath=(${fpath[@]})
        local new_env=$(printenv | sort)
        
        # Calculate path differences
        local added_path=()
        for p in $new_path; do
            [[ ${baseline_path[(ie)$p]} -gt ${#baseline_path} ]] && added_path+=$p
        done
        
        # Calculate fpath differences  
        local added_fpath=()
        for f in $new_fpath; do
            [[ ${baseline_fpath[(ie)$f]} -gt ${#baseline_fpath} ]] && added_fpath+=$f
        done
        
        # Calculate environment variable differences
        local env_diff=$(diff <(echo "$baseline_env") <(echo "$new_env") | grep '^>' | cut -c3-)
        
        # Write cache file
        {
            echo "# Zush environment cache for $tool"
            echo "# Generated: $(date)"
            echo
            [[ ${#added_path} -gt 0 ]] && printf 'path=(%s $path[@])\n' "${(q)added_path[@]}"
            [[ ${#added_fpath} -gt 0 ]] && printf 'fpath=(%s $fpath[@])\n' "${(q)added_fpath[@]}"
            echo
            echo "# Environment variables:"
            echo "$env_diff" | while IFS='=' read -r var value; do
                [[ -n "$var" && -n "$value" ]] && printf 'export %s=%s\n' "$var" "${(q)value}"
            done
        } > "$cache_file"
        
        zush_debug "Environment cached to $cache_file"
    } 2>/dev/null
}

# Apply cached environment for a tool
zush_apply_cached_env() {
    local tool="$1"
    local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
    
    if [[ -f "$cache_file" ]]; then
        zush_debug "Applying cached environment for $tool"
        source "$cache_file"
        return 0
    else
        zush_debug "No cached environment for $tool"
        return 1
    fi
}

# Set up lazy loading for a tool
zush_lazy_load() {
    local tool="$1"
    local init_command="$2"
    shift 2
    local commands=("$@")
    
    zush_debug "Setting up lazy loading for $tool (commands: ${commands[*]})"
    
    # Apply cached environment immediately if available
    zush_apply_cached_env "$tool"
    
    # Create placeholder functions for each command
    for cmd in $commands; do
        eval "
        $cmd() {
            zush_debug 'Lazy loading $tool for command: $cmd'
            
            # Remove all placeholder functions
            $(printf 'unfunction %s 2>/dev/null; ' $commands)
            
            # Initialize the tool
            eval '$init_command'
            
            # Cache the new environment for next time
            zush_cache_env '$tool' '$init_command' &!
            
            # Execute the original command
            $cmd \"\$@\"
        }
        "
    done
}

# Show status of lazy-loaded tools
zush_lazy_status() {
    echo "Lazy-loaded tools:"
    for cache_file in "${ZUSH_CACHE_DIR}"/*-env(N); do
        local tool="${cache_file:t:r}"
        tool="${tool%-env}"
        if [[ -f "$cache_file" ]]; then
            local cache_date=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$cache_file" 2>/dev/null || stat -c '%y' "$cache_file" 2>/dev/null | cut -d' ' -f1-2)
            echo "  $tool: cached ($cache_date)"
        else
            echo "  $tool: not cached"
        fi
    done
}

# Clear cache for a tool (or all tools)
zush_lazy_clear() {
    local tool="$1"
    if [[ -n "$tool" ]]; then
        local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
        [[ -f "$cache_file" ]] && rm -f "$cache_file" && echo "Cleared cache for $tool"
    else
        rm -f "${ZUSH_CACHE_DIR}"/*-env(N) && echo "Cleared all lazy-load caches"
    fi
}