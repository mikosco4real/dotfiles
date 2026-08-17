# History. Previously inherited from oh-my-zsh's defaults; now explicit.
# Lives under XDG_STATE_HOME rather than ~/.zsh_history.

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000        # lines kept in memory
SAVEHIST=50000        # lines written to $HISTFILE

[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

setopt SHARE_HISTORY          # new commands are visible in other live shells
setopt EXTENDED_HISTORY       # record timestamp and duration
setopt INC_APPEND_HISTORY     # write as you go, not just on exit
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicates of a repeated command
setopt HIST_IGNORE_SPACE      # a leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # expand !! for review instead of running it blind
setopt HIST_FIND_NO_DUPS
