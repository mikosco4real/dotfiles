# Vendored zsh plugins. chezmoi fetches these into $ZDOTDIR/plugins — see
# home/.chezmoiexternal.toml — so there is no plugin manager to bootstrap and
# nothing to install by hand on a new machine.
#
# LOAD ORDER IS LOAD-BEARING:
#   1. fzf-tab must come after compinit (20-completion.zsh) and before anything
#      that wraps completion widgets.
#   2. zsh-syntax-highlighting must be LAST of all — it wraps every widget that
#      exists at the time it loads, so anything sourced after it is unhighlighted.
#
# Each source is guarded, so a missing plugin degrades silently instead of
# breaking the shell.

_zsh_plugins="$ZDOTDIR/plugins"

# fzf-driven completion menu.
[[ -r "$_zsh_plugins/fzf-tab/fzf-tab.plugin.zsh" ]] &&
  source "$_zsh_plugins/fzf-tab/fzf-tab.plugin.zsh"

# Inline "ghost text" suggestion from history. Neither this nor highlighting
# existed before — zsh-autocomplete was brew-installed but never sourced.
if [[ -r "$_zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20      # don't suggest on huge buffers
  source "$_zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  bindkey '^ ' autosuggest-accept          # ctrl-space accepts the suggestion
fi

# Syntax highlighting — keep last.
[[ -r "$_zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
  source "$_zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset _zsh_plugins
