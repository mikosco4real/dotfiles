#!/usr/bin/env bash
# Weather for the tmux status line: "<location> <icon> <temp>".
#
# Deliberately a small local script rather than the xamut/tmux-weather plugin.
# That plugin works by string-replacing a `#{weather}` placeholder inside
# status-right, which is fragile to compose with catppuccin's own module
# expansion — and it is one more third-party dependency to bootstrap. This does
# the same job with a cache we control.
#
# NOT `set -e`: this runs on every status refresh, and a flaky network must
# degrade to a stale or empty reading, never break the status line.
set -uo pipefail

# All three knobs live in tmux.conf so there is one place to configure this:
#   set -g @weather_location "Sydney"   any wttr.in-recognised place name
#   set -g @weather_units    "m"        m = metric (°C), u = USCS (°F)
#   set -g @weather_ttl      "900"      cache lifetime in seconds
opt() { # opt <name> <default>
  local v
  v="$(tmux show-option -gqv "$1" 2> /dev/null)"
  [[ -n "$v" ]] && printf '%s' "$v" || printf '%s' "$2"
}

LOCATION="$(opt @weather_location Sydney)"
UNITS="$(opt @weather_units m)"
TTL="$(opt @weather_ttl 900)" # wttr.in asks that you not poll aggressively

# A non-numeric TTL would break the arithmetic comparison below under `set -u`.
[[ "$TTL" =~ ^[0-9]+$ ]] || TTL=900

# Cache per location+units, so changing either knob doesn't serve a stale answer
# for the old one.
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/weather-${LOCATION// /_}-${UNITS}"

mkdir -p "${CACHE%/*}" 2> /dev/null

cache_age() {
  local mtime
  # BSD stat, then GNU stat.
  mtime=$(stat -f %m "$CACHE" 2> /dev/null || stat -c %Y "$CACHE" 2> /dev/null) || return 1
  echo $(($(date +%s) - mtime))
}

is_fresh() {
  local age
  [[ -s "$CACHE" ]] || return 1
  age=$(cache_age) || return 1
  ((age < TTL))
}

if ! is_fresh; then
  # %c = condition glyph, %t = temperature. The `+` are URL-encoded spaces.
  # --max-time keeps a hung DNS lookup from stalling the status line.
  if out=$(curl -fsS --max-time 3 "https://wttr.in/${LOCATION// /+}?format=%c+%t&${UNITS}" 2> /dev/null); then
    # wttr prefixes the temperature with a sign ("+18°C"); drop it, keep minus.
    out=$(printf '%s' "$out" | sed 's/ *+/ /g' | tr -s ' ' | sed 's/^ *//;s/ *$//')
    [[ -n "$out" ]] && printf '%s' "$out" > "$CACHE"
  fi
fi

# Print whatever we have. A stale reading beats a blank status line; if the cache
# has never been written, print just the location so the module isn't empty.
if [[ -s "$CACHE" ]]; then
  printf '%s %s' "$LOCATION" "$(cat "$CACHE")"
else
  printf '%s' "$LOCATION"
fi
