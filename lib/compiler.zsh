# Zush Auto-Compiler
# Provides automatic zcompile functionality for faster loading

# Function: _zushc
# Smart compile function - handles files, directories, or patterns
# Parameters:
#   $1: target - file or directory to compile
#   $2: pattern - file pattern for directories (default: *.zsh)
# Returns: 0 on success, 1 on error
_zushc() {
    local target="$1"
    local pattern="${2:-*.zsh}"
    
    if [[ -z "$target" ]]; then
        zush_error "_zushc: no target specified"
        return 1
    fi
    
    if [[ -f "$target" ]]; then
        # Compile single file
        _zushc_file "$target"
    elif [[ -d "$target" ]]; then
        # Compile directory
        _zushc_dir "$target" "$pattern"
    else
        zush_error "_zushc: $target does not exist"
        return 1
    fi
}

# Function: _zushc_file
# Internal: compile a single file
# Parameters:
#   $1: file - path to file to compile
# Returns: 0 on success, 1 on compilation failure
_zushc_file() {
    local file="$1"
    local compiled="${file}.zwc"
    
    # Check if compilation is needed
    if [[ ! -f "$compiled" || "$file" -nt "$compiled" ]]; then
        zush_debug "Compiling: $file"
        zcompile "$file" 2>/dev/null && {
            zush_debug "Compiled: $file -> $compiled"
            return 0
        } || {
            zush_error "Failed to compile: $file"
            return 1
        }
    else
        zush_debug "Already compiled: $file"
        return 0
    fi
}

# Function: _zushc_dir
# Internal: compile all files in a directory
# Parameters:
#   $1: dir - directory containing files to compile
#   $2: pattern - file pattern to match (default: *.zsh)
# Returns: 0 on success
_zushc_dir() {
    local dir="$1"
    local pattern="${2:-*.zsh}"
    
    local compiled_count=0
    for file in "$dir"/$pattern(N); do
        if _zushc_file "$file"; then
            (( compiled_count++ ))
        fi
    done
    
    zush_debug "Compiled $compiled_count files in $dir"
    return 0
}

# Function: _zushc_all
# Compile all Zush configuration files
# Parameters: none
# Returns: 0 on success
_zushc_all() {
    zush_debug "Starting full compilation"
    
    # Compile main .zshrc
    _zushc "${ZUSH_HOME}/.zshrc"
    
    # Compile all library files
    _zushc "${ZUSH_LIB_DIR}"
    
    # Compile all rc.d files
    _zushc "${ZUSH_RC_DIR}"
    
    # Compile machine-specific config if it exists
    [[ -f "${HOME}/.zushrc" ]] && _zushc "${HOME}/.zushrc"
    
    # Compile completion dump if it exists
    local zcompdump="${ZUSH_HOME}/.zcompdump"
    [[ -f "$zcompdump" ]] && _zushc "$zcompdump"
    
    zush_debug "Full compilation complete"
}

# Function: _zushc_clean
# Clean all compiled files
# Parameters: none
# Returns: 0 on success
_zushc_clean() {
    zush_debug "Cleaning compiled files"
    
    # Clean main .zshrc
    [[ -f "${ZUSH_HOME}/.zshrc.zwc" ]] && rm -f "${ZUSH_HOME}/.zshrc.zwc"
    
    # Clean library files
    setopt null_glob
    for compiled in "${ZUSH_LIB_DIR}"/*.zwc; do
        zush_debug "Removing: $compiled"
        rm -f "$compiled"
    done
    
    # Clean rc.d files
    for compiled in "${ZUSH_RC_DIR}"/*.zwc; do
        zush_debug "Removing: $compiled"
        rm -f "$compiled"
    done
    unsetopt null_glob
    
    # Clean machine-specific config
    [[ -f "${HOME}/.zushrc.zwc" ]] && rm -f "${HOME}/.zushrc.zwc"
    
    # Clean completion dump
    [[ -f "${ZUSH_HOME}/.zcompdump.zwc" ]] && rm -f "${ZUSH_HOME}/.zcompdump.zwc"
    
    zush_debug "Cleanup complete"
}

# Function: _zushc_bg
# Background compilation job that runs after startup
# Parameters: none
# Returns: 0 on success
_zushc_bg() {
    {
        zush_debug "Background compilation started"
        _zushc_all
        zush_debug "Background compilation finished"
    } &!
}