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

# ~/.local/bin last, so it outranks everything above it in THIS file. mise
# installs itself there, as do pipx and `cargo install --root ~/.local`.
_path_prepend "$HOME/.local/bin"

# Later fragments deliberately layer on top of this: conf.d/70-darwin.zsh puts
# brew's php@8.2 and then Laravel Herd in front (so Herd owns `php` on macOS),
# and local.zsh adds machine-specific paths last of all. Run `path` to see the
# final resolved order.
