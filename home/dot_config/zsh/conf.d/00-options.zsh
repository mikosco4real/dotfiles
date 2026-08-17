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
