# Aliases. Explicit and readable, rather than inherited from oh-my-zsh's alias
# packs. These are the ones actually worth keeping from the omz `git` plugin.

# ─── Navigation ───────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ─── ls / cat, with graceful fallback ─────────────────────────────────────────
# eza and bat may not be installed (e.g. a minimal server), so fall back rather
# than leaving a broken alias.
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l --group-directories-first --icons=auto --git'
  alias la='eza -la --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ls='ls -G'          # -G is colour on BSD/macOS; 75-linux.zsh overrides
  alias ll='ls -lh'
  alias la='ls -lah'
fi

if (( $+commands[bat] )); then
  alias cat='bat --paging=never'
  alias less='bat'
fi

# ─── git ──────────────────────────────────────────────────────────────────────
alias g='git'
alias gst='git status'
alias gss='git status --short'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit --verbose'
alias gcm='git commit --message'
alias gca='git commit --verbose --amend'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'   # never bare --force
alias glg='git log --oneline --graph --decorate -20'
alias glga='git log --oneline --graph --decorate --all -20'
alias gb='git branch'
alias gbd='git branch --delete'
alias grs='git restore'
alias grss='git restore --staged'
alias gsta='git stash push'
alias gstp='git stash pop'
alias gf='git fetch --all --prune'
alias lg='lazygit'

# ─── tmux ─────────────────────────────────────────────────────────────────────
# Plain aliases, deliberately NOT the omz tmux plugin. That plugin defined
# `alias tmux=_zsh_tmux_plugin_run`, which breaks in any non-interactive context
# ("command not found: _zsh_tmux_plugin_run").
alias ta='tmux attach -t'
alias tl='tmux list-sessions'
alias tn='tmux new-session -s'
alias tk='tmux kill-session -t'

# ─── docker ───────────────────────────────────────────────────────────────────
alias d='docker'
alias dc='docker compose'          # replaces the omz docker-compose plugin
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# ─── dotfiles ─────────────────────────────────────────────────────────────────
alias cz='chezmoi'
alias czcd='cd $(chezmoi source-path)'
alias czap='chezmoi apply --verbose'
alias czd='chezmoi diff'

# ─── misc ─────────────────────────────────────────────────────────────────────
alias v='nvim'
alias reload='exec zsh'
alias path='print -l $path'
