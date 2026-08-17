# Completion. Replaces what oh-my-zsh did implicitly.

# Homebrew's completion functions, if brew is present. HOMEBREW_PREFIX is set by
# `brew shellenv` in .zprofile.
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

# Own completions, if any.
[[ -d "$ZDOTDIR/completions" ]] && fpath=("$ZDOTDIR/completions" $fpath)

autoload -Uz compinit

# compinit's security audit (compaudit) is the slow part of zsh startup, and it
# has to stat every directory in fpath. Run it in full at most once a day; use
# -C (skip the check) when the dump file is fresh.
_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"

if [[ -n "$_zcompdump"(#qNmh-24) ]]; then
  compinit -C -d "$_zcompdump"      # fresh: trust it, skip the audit
else
  compinit -d "$_zcompdump"         # stale or missing: full rebuild
fi
unset _zcompdump

# Case-insensitive, then partial-word, then substring matching.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}%B%d%b%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# REQUIRED by fzf-tab: it replaces zsh's completion menu, so zsh's own must be
# disabled. See conf.d/30-plugins.zsh.
zstyle ':completion:*' menu no
