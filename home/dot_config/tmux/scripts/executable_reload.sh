#!/usr/bin/env bash
# Full tmux reload, including the catppuccin theme. Bound to `prefix + r`.
#
# Why this exists instead of a plain `source-file`:
#
# catppuccin composes its status modules into @catppuccin_status_<module> using
# `set -ogq` — assign ONLY if the option is currently unset. That is what makes
# user overrides work, but it also means a re-source never rebuilds an
# already-composed module. So editing a colour, a module's text, or the flavour
# and hitting `prefix + r` appears to do nothing at all, and you are left
# believing the config is wrong when it is simply stale.
#
# Observed concretely: after switching the weather module to peach and the
# battery module to green, `@catppuccin_weather_color` held the new value while
# the composed `@catppuccin_status_weather` still carried the old yellow. A fresh
# tmux server rendered correctly; the running one did not.
#
# Clearing the theme's own options first makes the reload real, without killing
# the server or dropping any session.
#
# NOT `set -e`: a failure here must not leave the config half-applied.
set -uo pipefail

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"

# @thm_*  theme palette
# @catppuccin_*  module options and composed module strings
# @_ctp*  catppuccin internals
tmux show-options -g 2> /dev/null |
  grep -oE '^@(catppuccin|thm|_ctp)[a-zA-Z0-9_]*' |
  while read -r opt; do
    tmux set-option -gu "$opt" 2> /dev/null
  done

if tmux source-file "$CONF" 2> /dev/null; then
  tmux display-message "tmux.conf + theme reloaded"
else
  tmux display-message "reload FAILED — run: tmux source-file $CONF"
fi
