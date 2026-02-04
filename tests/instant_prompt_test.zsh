#!/usr/bin/env zsh

set -euo pipefail

repo_root=${0:A:h}/..
lib_dir="$repo_root/lib"

tmp_cache_dir=$(mktemp -d)
trap 'rm -rf "$tmp_cache_dir"' EXIT

no_error_script=$(cat <<'EOF'
set -euo pipefail
source "$LIB_DIR/instant-prompt.zsh"

_zush_handoff_to_real_prompt() {
    print -r -- "handoff called"
    unset _ZUSH_INSTANT_PROMPT_SHOWN
}

typeset -g _ZUSH_INSTANT_PROMPT_SHOWN=1

_zush_wait_before_handoff_if_needed
EOF
)

no_error_output=$(LIB_DIR="$lib_dir" ZUSH_CACHE_DIR="$tmp_cache_dir" zsh -c "$no_error_script")

if [[ "$no_error_output" != "handoff called" ]]; then
    print -u2 -- "Expected immediate handoff output, got: $no_error_output"
    exit 1
fi

error_script=$(cat <<'EOF'
set -euo pipefail
source "$LIB_DIR/core.zsh"
source "$LIB_DIR/instant-prompt.zsh"

_zush_handoff_to_real_prompt() {
    print -r -- "handoff called"
    unset _ZUSH_INSTANT_PROMPT_SHOWN
}

typeset -g _ZUSH_INSTANT_PROMPT_SHOWN=1

zush_error "boom"

_zush_wait_before_handoff_if_needed

if [[ -n "${_ZUSH_STARTUP_ERROR:-}" ]]; then
    print -u2 -- "_ZUSH_STARTUP_ERROR not cleared"
    exit 1
fi
EOF
)

error_output=$(LIB_DIR="$lib_dir" ZUSH_CACHE_DIR="$tmp_cache_dir" ZUSH_PROMPT_WAIT_TEST_INPUT="x" zsh -c "$error_script" 2>/dev/null)

wait_message="Startup errors detected. Press any key to continue..."

if [[ "$error_output" != *"$wait_message"* ]]; then
    print -u2 -- "Did not see wait message in output"
    exit 1
fi

case "$error_output" in
    *"$wait_message"*"handoff called"*) ;;
    *)
        print -u2 -- "Unexpected output order: $error_output"
        exit 1
        ;;
esac

print -r -- "instant prompt tests passed"
