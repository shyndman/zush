#!/usr/bin/env zsh
# Zush Lazy Loader - High-performance lazy loading with environment caching
#
# This module provides lazy loading for heavy tools (nvm, pyenv, brew, etc.)
# with intelligent environment caching to eliminate startup overhead.
#
# Usage:
#   zush_lazy_load <tool> <init_command> <command1> [command2...]
#
# Examples:
#   zush_lazy_load nvm 'source ~/.nvm/nvm.sh' nvm node npm npx
#   zush_lazy_load pyenv 'eval "$(pyenv init -)"' pyenv python pip
#   zush_lazy_load brew 'eval "$(/opt/homebrew/bin/brew shellenv)"' brew
#   zush_lazy_load --ignore-stable-env custom 'source ~/.custom/init' custom

# Apply cached environment for a tool
# Returns 0 if cache exists and was applied, 1 otherwise
zush_apply_cached_env() {
    local tool=$1
    local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"

    [[ -f $cache_file ]] || { zush_debug "No cached environment for $tool"; return 1; }
    
    zush_debug "Applying cached environment for $tool"
    source "$cache_file"
}

# Core tool initialization logic - captures environment changes and caches them
# Used by both immediate initialization and lazy loading functions
zush_do_tool_initialization() {
    local tool=$1
    local init_command=$2
    local warn_on_no_changes=${3:-1}  # Default to warning unless explicitly disabled
    
    zush_debug "Initializing $tool"
    
    # Capture baseline environment
    local _baseline_path=$PATH
    local _baseline_fpath=$FPATH
    local _baseline_env_file=$(mktemp)
    printenv | sort > "$_baseline_env_file"
    
    # Initialize the tool
    eval "$init_command"
    
    # Check if environment actually changed
    local _new_env_file=$(mktemp)
    printenv | sort > "$_new_env_file"
    
    local has_changes=0
    
    # Check for PATH changes
    if [[ $PATH != $_baseline_path ]]; then
        has_changes=1
    fi
    
    # Check for FPATH changes
    if [[ $FPATH != $_baseline_fpath ]]; then
        has_changes=1
    fi
    
    # Check for new environment variables
    if [[ $(comm -13 "$_baseline_env_file" "$_new_env_file" | wc -l) -gt 0 ]]; then
        has_changes=1
    fi
    
    if [[ $has_changes -eq 0 && $warn_on_no_changes -eq 1 ]]; then
        zush_error "WARNING: Tool '$tool' initialization produced no environment changes!"
        zush_error "  Command: $init_command"
        zush_error "  This suggests the tool is not properly installed or the init command is incorrect."
        zush_error "  Lazy loading for this tool may not work as expected."
        zush_error "  Use --ignore-stable-env flag if this is expected."
    fi
    
    # Cache environment changes in background
    (
        local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
        
        {
            echo "# Zush environment cache for $tool"
            echo "# Generated: $(date)"
            echo
            
            # Process PATH additions
            if [[ $PATH != $_baseline_path ]]; then
                echo '# PATH additions:'
                local IFS=:
                local -a old_paths=(${=_baseline_path})
                local -a new_paths=(${=PATH})
                
                for p in "${new_paths[@]}"; do
                    local found=0
                    for op in "${old_paths[@]}"; do
                        [[ $p == $op ]] && { found=1; break; }
                    done
                    if [[ $found -eq 0 ]]; then
                        printf 'path=(%q $path)\n' "$p"
                    fi
                done
                echo
            fi
            
            # Process FPATH additions
            if [[ $FPATH != $_baseline_fpath ]]; then
                echo '# FPATH additions:'
                local IFS=:
                local -a old_fpaths=(${=_baseline_fpath})
                local -a new_fpaths=(${=FPATH})
                
                for f in "${new_fpaths[@]}"; do
                    local found=0
                    for of in "${old_fpaths[@]}"; do
                        [[ $f == $of ]] && { found=1; break; }
                    done
                    if [[ $found -eq 0 ]]; then
                        printf 'fpath=(%q $fpath)\n' "$f"
                    fi
                done
                echo
            fi
            
            # Process new environment variables
            echo '# Environment variables:'
            comm -13 "$_baseline_env_file" "$_new_env_file" | while IFS= read -r line; do
                [[ $line =~ ^([^=]+)=(.*)$ ]] || continue
                local var=${match[1]}
                local value=${match[2]}
                
                # Skip PATH/FPATH (handled above) and empty vars
                [[ $var == PATH || $var == FPATH || -z $var ]] && continue
                
                printf 'export %s=%q\n' "$var" "$value"
            done
        } > "$cache_file"
        
        zush_debug "Environment cached to $cache_file"
        rm -f "$_baseline_env_file" "$_new_env_file"
    ) &!
}

# Set up lazy loading for a tool with environment caching
zush_lazy_load() {
    local ignore_stable_env=0
    if [[ $1 == "--ignore-stable-env" ]]; then
        ignore_stable_env=1
        shift
    fi
    
    local tool=$1
    local init_command=$2
    shift 2
    local -a commands=("$@")

    zush_debug "Setting up lazy loading for $tool (commands: ${commands[*]})"

    # Apply cached environment if available, otherwise initialize immediately (unless ignoring stable env)
    if ! zush_apply_cached_env "$tool"; then
        if [[ $ignore_stable_env -eq 0 ]]; then
            zush_do_tool_initialization "$tool" "$init_command" 1  # warn on no changes
            return  # Tool is now initialized, no need for lazy placeholders
        else
            zush_debug "Skipping immediate initialization for $tool (--ignore-stable-env)"
        fi
    fi

    # Create placeholder functions for each command
    local cmd
    for cmd in "${commands[@]}"; do
        # Create the lazy loading function
        eval "
        function $cmd() {
            zush_debug 'Lazy loading $tool via command: $cmd'
            
            # Remove all placeholder functions to prevent recursion
            local _cmd
            for _cmd in ${commands[*]}; do
                unfunction \"\$_cmd\" 2>/dev/null
            done
            
            # Initialize the tool in current session only (don't modify persistent cache)
            eval '$init_command'
            
            # Execute the original command with all arguments
            \"\$0\" \"\$@\"
        }
        "
    done
}

# Show status of lazy-loaded tools
zush_lazy_status() {
    local cache_file tool cache_date
    local -a cache_files=("${ZUSH_CACHE_DIR}"/*-env(N))
    
    [[ ${#cache_files} -eq 0 ]] && { echo "No lazy-loaded tools cached"; return; }
    
    echo "Lazy-loaded tools:"
    for cache_file in "${cache_files[@]}"; do
        tool=${cache_file:t:r}
        tool=${tool%-env}
        
        if [[ -f $cache_file ]]; then
            # Try GNU stat first, fall back to BSD stat
            cache_date=$(stat -c '%y' "$cache_file" 2>/dev/null | cut -d' ' -f1-2 ||
                        stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$cache_file" 2>/dev/null)
            echo "  $tool: cached (${cache_date:-unknown date})"
        fi
    done
}

# Clear cache for a specific tool or all tools
zush_lazy_clear() {
    local tool=$1
    
    if [[ -n $tool ]]; then
        local cache_file="${ZUSH_CACHE_DIR}/${tool}-env"
        if [[ -f $cache_file ]]; then
            rm -f "$cache_file" && echo "Cleared cache for $tool"
        else
            echo "No cache found for $tool"
        fi
    else
        local -a cache_files=("${ZUSH_CACHE_DIR}"/*-env(N))
        if [[ ${#cache_files} -gt 0 ]]; then
            rm -f "${cache_files[@]}" && echo "Cleared all lazy-load caches"
        else
            echo "No caches to clear"
        fi
    fi
}

# Refresh cache for a tool (clear and reinitialize on next use)
zush_lazy_refresh() {
    local tool=$1
    [[ -n $tool ]] || { echo "Usage: zush_lazy_refresh <tool>"; return 1; }
    
    zush_lazy_clear "$tool"
    echo "Cache cleared for $tool. It will be regenerated on next use."
}