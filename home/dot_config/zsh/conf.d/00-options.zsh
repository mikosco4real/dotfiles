# Shell options and keybindings.
# EXTENDED_GLOB must be set here, before 20-completion.zsh uses (#q...) syntax.

setopt AUTO_CD                # `foo` cds into ./foo
setopt AUTO_PUSHD             # cd pushes onto the directory stack
setopt PUSHD_IGNORE_DUPS
setopt EXTENDED_GLOB          # required for (#q...) glob qualifiers
setopt GLOB_DOTS              # let globs match dotfiles
setopt NO_BEEP
setopt INTERACTIVE_COMMENTS   # allow # comments when typing interactively
setopt NO_FLOW_CONTROL        # free up ctrl-s / ctrl-q
setopt LONG_LIST_JOBS

# Emacs keybindings on the command line. Note this is independent of nvim's and
# tmux's vi modes — muscle memory here is readline-shaped (ctrl-a, ctrl-e, ctrl-w).
bindkey -e

# Make ctrl-left / ctrl-right jump by word.
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Prefix-based history search on the arrow keys: with text already on the line,
# up/down walk only the history entries starting with it. On an empty line they
# behave like plain up/down-line-or-history.
#
# Inherited implicitly from oh-my-zsh's lib/key-bindings.zsh and lost when omz was
# dropped — 10-history.zsh and 20-completion.zsh carried over omz's implicit
# history and completion behaviour, but its keybindings were the omission.
#
# Both escape sequences are bound on purpose: terminals send ^[[A in normal cursor
# mode and ^[OA in application mode, which zle switches on via smkx — so ^[OA is
# what actually arrives here (terminfo kcuu1 resolves to it). Binding the literal
# pairs avoids needing zsh/terminfo at startup.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
