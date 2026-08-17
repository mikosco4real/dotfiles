# Machine-local escape hatch, sourced last so it can override anything above.
#
# ~/.config/zsh/local.zsh is created ONCE by chezmoi (from
# home/dot_config/zsh/create_private_local.zsh.tmpl) and then never touched
# again. It is not a symlink and lives outside the repo entirely, so it needs no
# .gitignore entry and can safely hold secrets and per-machine paths.
[[ -r "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# Tidy up the helpers defined in conf.d/05-path.zsh.
unfunction _path_prepend _path_append 2>/dev/null
