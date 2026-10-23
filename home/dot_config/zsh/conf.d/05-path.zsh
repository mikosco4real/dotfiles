# PATH assembly.
#
# `typeset -U path PATH` makes the array unique-valued, keeping the FIRST
# occurrence of any duplicate. This structurally eliminates the whole bug class
# the old .zshrc had — it exported ~/.antigravity/antigravity/bin twice
# (byte-identical lines) and compounded PATH on every re-source.
typeset -U path PATH

# Only add directories that actually exist, so a machine without a given tool
# doesn't carry a dead PATH entry.
_path_prepend() { [[ -d "$1" ]] && path=("$1" $path) }
_path_append()  { [[ -d "$1" ]] && path=($path "$1") }

# Lowest priority first — each prepend pushes the previous one down.
_path_prepend "$GOPATH/bin"
_path_prepend "$HOME/.composer/vendor/bin"
_path_prepend "$BUN_INSTALL/bin"

# Homebrew PHP. Ahead of $HOMEBREW_PREFIX/bin, so `php` is 8.2 rather than
# brew's unversioned php, but set here rather than in 70-darwin.zsh so that
# `mise activate` (conf.d/50-tools.zsh) still puts its tool paths in front of
# it. Mostly vestigial — Herd shadows it — but kept for brew-php-switcher.
# Guarded on HOMEBREW_PREFIX, so it is a no-op without Homebrew.
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  _path_prepend "$HOMEBREW_PREFIX/opt/php@8.2/sbin"
  _path_prepend "$HOMEBREW_PREFIX/opt/php@8.2/bin"
fi

# ~/.local/bin last, so it outranks everything above it in THIS file. mise
# installs itself there, as do pipx and `cargo install --root ~/.local`.
_path_prepend "$HOME/.local/bin"

# Later fragments deliberately layer on top of this: conf.d/70-darwin.zsh puts
# Laravel Herd in front (so Herd owns `php` on macOS),
# and local.zsh adds machine-specific paths last of all. Run `path` to see the
# final resolved order.
