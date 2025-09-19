# Thanks to https://silverrainz.me/blog/2025-09-systemd-fzf-aliases.html

# Set of aliases/helpers for SYSTEMCTL(1).

# Simple aliases.
alias s='sudo systemctl'
alias sj='journalctl'
alias u='systemctl --user'
alias uj='journalctl --user'

# SystemD unit selector.
_sysls() {
    # $1: --system or --user
    # $2: filter to unit state, or omit to show all
    #     See `systemctl list-units --state=help` for more info
    SCOPE=$1
    [ -n "$2" ] && STATE="--state=$2"
    echo $HI
    cat \
        <(echo 'UNIT/FILE LOAD/STATE ACTIVE/PRESET SUB DESCRIPTION') \
        <(systemctl $SCOPE list-units --legend=false $STATE) \
        <(systemctl $SCOPE list-unit-files --legend=false $STATE) \
    | sed 's/●/ /' \
    | grep . \
    | column --table --table-columns-limit=5 \
    | fzf --header-lines=1 \
          --accept-nth=1 \
          --no-hscroll \
          --preview="SYSTEMD_COLORS=1 systemctl $SCOPE status {1}" \
          --preview-window=down
}

# Aliases for unit selector.
alias sls='_sysls --system'
alias uls='_sysls --user'
alias sjf='sj --unit $(sls) --all --follow'
alias ujf='uj --unit $(uls) --all --follow'

# Define aliases for starting, stopping, and restarting services
_SYS_ALIASES=(
    sstart sstop sre
    ustart ustop ure
)
_SYS_CMDS=(
    's start $(sls static,disabled,failed)'
    's stop $(sls running,failed)'
    's restart $(sls)'
    'u start $(uls static,disabled,failed)'
    'u stop $(uls running,failed)'
    'u restart $(uls)'
)

_sysexec() {
    for ((j=0; j < ${#_SYS_ALIASES[@]}; j++)); do
        if [ "$1" == "${_SYS_ALIASES[$j]}" ]; then
            base_cmd=$(eval echo "${_SYS_CMDS[$j]}") # expand service name
            scope=${base_cmd:0:1}
            status_cmd="${scope} status \$_"
            journal_cmd="${scope}j -xeu \$_"
            full_cmd="$base_cmd && $status_cmd || $journal_cmd"
            eval $full_cmd

            # Push to history.
            [ -n "$ZSH_VERSION" ] && print -s $full_cmd
            return
        fi
    done
}

# Generate bash function/zsh widgets.
for i in ${_SYS_ALIASES[@]}; do
    source /dev/stdin <<EOF
$i() {
    _sysexec $i
}
EOF
done
