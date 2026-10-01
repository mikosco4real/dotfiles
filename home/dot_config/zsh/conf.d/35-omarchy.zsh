# Omarchy bridge — pull Omarchy's bash-only shell integration into zsh.
#
# Omarchy ships no zsh support whatsoever: $OMARCHY_PATH/default/bash is the
# entire integration, and ~/.bashrc is its only entry point. Switching the login
# shell to zsh therefore silently drops every Omarchy alias and function. This
# fragment imports the parts that survive translation.
#
# Numbered 35 on purpose. .zshrc sources conf.d/*.zsh in ASCII order, so this
# lands AFTER 30-plugins (compinit from 20-completion has already run) and
# BEFORE 40-aliases — which means everything imported here is a DEFAULT that
# 40-aliases.zsh, 75-linux.zsh and 99-local.zsh all override. Renumbering this
# above 40 would invert that and let Omarchy win, which is not what we want.
#
# Deliberately NOT sourced from $OMARCHY_PATH/default/bash:
#   rc           aggregator only; it pulls in `init` and `shell` below
#   shell        `shopt -s histappend`, `[[ -v ]]`, `set +h`, bash-completion.
#                All bash-only, and 10-history.zsh already owns history.
#   init         `mise activate bash`, `starship init bash`, `zoxide init bash`,
#                /usr/share/fzf/*.bash. Evaluating bash-flavoured init output in
#                zsh is a hard error, and 50-tools.zsh and 60-prompt.zsh already
#                run the zsh forms of all four.
#   completions  readline-only: complete / COMPREPLY / COMP_WORDS, plus
#                `shopt -s nullglob`, which bashcompinit does NOT provide, so it
#                cannot be salvaged as-is.
#   inputrc      readline keymap; 00-options.zsh owns ZLE bindings.

[[ "$OSTYPE" == linux* ]] || return 0

: "${OMARCHY_PATH:=/usr/share/omarchy}"
[[ -d "$OMARCHY_PATH/default/bash" ]] || return 0
export OMARCHY_PATH

# ── Environment ───────────────────────────────────────────────────────────────
# POSIX-clean, and every export uses ${VAR:-default}, so EDITOR and VISUAL set
# in $ZDOTDIR/.zshenv still win over Omarchy's omarchy-launch-editor. What this
# adds is BROWSER=omarchy-launch-browser and a bat-based MANPAGER.
#
# It also re-runs env-bootstrap, which is the only thing that puts OMARCHY_PATH
# and ~/.local/share/mise/shims on PATH in a NON-login zsh: /etc/zsh/zprofile ->
# /etc/profile -> /etc/profile.d/omarchy.sh covers login shells only. The PATH
# appends are idempotent here because 05-path.zsh has already declared
# `typeset -U path PATH`.
[[ -r "$OMARCHY_PATH/default/bash/envs" ]] && source "$OMARCHY_PATH/default/bash/envs"

# ── Aliases and functions ─────────────────────────────────────────────────────
# `emulate ksh -c '...'` rather than a plain `source`, because zsh arrays are
# 1-indexed and bash's are 0-indexed. fns/tmux's tsl() does ${panes[0]} and
# ${panes[-1]}; sourced plainly, ${panes[0]} expands to the EMPTY STRING and the
# function runs `tmux select-pane -t ""` — wrong, and silent, with no error to
# notice.
#
# The fix works because zsh's emulate -c is STICKY: it records the emulation
# mode on every function DEFINED inside the -c argument and re-applies it each
# time that function is later CALLED. So tsl() runs under KSH_ARRAYS (0-indexed),
# SH_WORD_SPLIT and POSIX_BUILTINS forever, while the interactive shell around
# it keeps normal zsh semantics. Nothing leaks.
emulate ksh -c 'source "$OMARCHY_PATH/default/bash/aliases"'

# (N) is NULL_GLOB for this pattern only: an empty or missing fns/ is a no-op
# rather than an error.
for _om_fn in "$OMARCHY_PATH"/default/bash/fns/*(N); do
  emulate ksh -c 'source "$_om_fn"'
done
unset _om_fn

# Omarchy's aliases file does `alias cd=zd`, wrapping cd in zoxide. 50-tools.zsh
# already runs `zoxide init zsh`, which provides z and zi without hijacking cd.
# Delete this line if you prefer Omarchy's behaviour.
unalias cd 2>/dev/null
