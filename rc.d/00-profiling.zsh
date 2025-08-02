# Enable profiling at the very start if requested
# This script runs first to capture the entire startup process

if [[ "${ZUSH_PROFILE:-0}" == "1" ]] && (( ${+functions[zush_profile]} )); then
    zush_debug "Profiling enabled - startup timing will be shown at the end"
fi