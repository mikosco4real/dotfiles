# pnpm: its standalone install and global packages live in $PNPM_HOME/bin.
#
# pnpm derives the same directory from XDG_DATA_HOME (set in ~/.zshenv), so this
# matches what `pnpm setup` writes, without its hardcoded /Users/<name> path.
# Numbered after 50-tools (mise) and 70-darwin (Herd) so pnpm's own binary wins
# over mise's shim, as it did when `pnpm setup` appended this to .zshrc. If
# `pnpm setup` re-adds a "# pnpm" block to .zshrc, delete it: this replaces it.
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
_path_prepend "$PNPM_HOME/bin"
