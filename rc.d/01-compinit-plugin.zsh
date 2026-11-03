# Defers compinit until the end of .zshrc, while queueing compdef calls
# shellcheck shell=bash

zstyle -t ':plugin:ez-compinit' 'use-cache'
if (($? == 2)); then # 2 = style is unset (0 = true, 1 = false)
    zstyle ':plugin:ez-compinit' 'use-cache' 'yes'
fi

zushp mattmc3/ez-compinit
