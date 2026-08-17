# Tool initialisation. EVERY init is guarded on the binary existing.
#
# The old .zshrc called `eval "$(pyenv init --path)"` and
# `eval "$(starship init zsh)"` unguarded, so both hard-errored on any machine
# without those binaries. `(( $+commands[x] ))` is zsh's zero-fork test for
# "is x on PATH".

# ─── mise: runtime version manager ────────────────────────────────────────────
# Replaces nvm (node) and pyenv (python), both of which were slow and, in
# pyenv's case, unguarded. One cross-platform binary, one config file at
# ~/.config/mise/config.toml.
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# ─── zoxide: frecency-ranked `cd` ─────────────────────────────────────────────
# Was installed via brew but never initialised, so `z` did nothing at all.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# ─── fzf: ctrl-r history, ctrl-t files, alt-c cd ──────────────────────────────
# `fzf --zsh` (fzf >= 0.48) emits keybindings + completion in one go, and
# replaces the oh-my-zsh fzf plugin.
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  # Respect .gitignore and show hidden files, when fd is available.
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
fi

# ─── direnv: per-directory environments ───────────────────────────────────────
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# ─── bun completions ──────────────────────────────────────────────────────────
# Was hardcoded as /Users/mokolo/.bun/_bun; now $BUN_INSTALL-relative.
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
