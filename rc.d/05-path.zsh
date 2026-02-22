# Add some standard paths to path

zush_home="${ZUSH_HOME:-${ZDOTDIR:-$HOME/.config/zush}}"
path=("$zush_home/bin" "$HOME/.local/bin" "$HOME/bin" $path)
