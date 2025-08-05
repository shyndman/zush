# Zush Performance Profiler
# Provides timing and profiling utilities for measuring startup performance

# zprof is loaded early in .zshrc if ZUSH_PROFILE=1

# Profile a command or function
zush_profile() {
    local name="$1"
    shift
    local start=$(date +%s%3N)
    "$@"
    local end=$(date +%s%3N)
    local duration=$(( end - start ))
    printf "PROFILE: %s took %dms\n" "$name" $duration >&2
}

# Show startup timing
zush_startup_time() {
    local end=$(date +%s%3N)
    local duration=$(( end - ZUSH_START_TIME ))
    printf "Zush startup: %.3fms\n" $(( duration * 1000 ))
}

# Benchmark a command multiple times
zush_bench() {
    local iterations="${1:-10}"
    local name="$2"
    shift 2

    local total=0
    local i

    echo "Benchmarking '$name' ($iterations iterations):"

    for (( i = 1; i <= iterations; i++ )); do
        local start="${EPOCHREALTIME:-$(date +%s.%N)}"
        "$@" >/dev/null 2>&1
        local end="${EPOCHREALTIME:-$(date +%s.%N)}"
        local duration=$(( end - start ))
        total=$(( total + duration ))
        printf "  Run %d: %.3fms\n" "$i" $(( duration * 1000 ))
    done

    local avg=$(( total / iterations ))
    printf "Average: %.3fms\n" $(( avg * 1000 ))
}

# Show zprof results if profiling was enabled
zush_show_profile() {
    if [[ "${ZUSH_PROFILE:-0}" == "1" ]] && (( ${+functions[zprof]} )); then
        echo "\n=== ZPROF Results ==="
        zprof
        echo "=====================\n"
    fi
    zush_startup_time
}
