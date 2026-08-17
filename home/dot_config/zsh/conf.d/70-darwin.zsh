# macOS-only. Self-guarding: returns immediately on any other platform, so this
# file is safe to source unconditionally from .zshrc.
[[ "$OSTYPE" == darwin* ]] || return 0

# ─── Homebrew PHP ─────────────────────────────────────────────────────────────
# Prepended BEFORE Herd below, so Herd ends up ahead of it on PATH. Guarded on
# HOMEBREW_PREFIX rather than the old hardcoded /opt/homebrew, so this also
# works on Intel Macs. Mostly vestigial — Herd shadows it — but kept for
# brew-php-switcher.
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  _path_prepend "$HOMEBREW_PREFIX/opt/php@8.2/sbin"
  _path_prepend "$HOMEBREW_PREFIX/opt/php@8.2/bin"
fi

# ─── Laravel Herd ─────────────────────────────────────────────────────────────
# Herd is a macOS GUI app, so this whole block is macOS-only by nature.
#
# The old .zshrc had seven near-identical HERD_PHP_<ver>_INI_SCAN_DIR exports,
# each hardcoding /Users/mokolo — the single biggest source of non-portability
# in the repo. This discovers the installed versions from Herd's own config
# directory instead, so it needs no edit when a new PHP version is added.
#
# Herd is prepended LAST here, and this file loads after conf.d/50-tools.zsh, so
# Herd wins over both brew's php@8.2 and any mise shim. That is the intended
# precedence: Herd is the actual Laravel dev environment on this machine.
_herd="$HOME/Library/Application Support/Herd"
if [[ -d "$_herd" ]]; then
  for _herd_ver in "$_herd"/config/php/*(/N); do
    export "HERD_PHP_${_herd_ver:t}_INI_SCAN_DIR=${_herd_ver}/"
  done
  unset _herd_ver
  _path_prepend "$_herd/bin"
fi
unset _herd

# ─── macOS conveniences ───────────────────────────────────────────────────────
alias o='open'
alias flush-dns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
