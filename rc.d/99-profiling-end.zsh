# Show profiling results
# Displays startup timing and zprof results if profiling was enabled

# Show profiling results if available
if [[ "${ZUSH_PROFILE:-0}" == "1" ]] && (( ${+functions[_zush_show_profile]} )); then
    _zush_show_profile
fi