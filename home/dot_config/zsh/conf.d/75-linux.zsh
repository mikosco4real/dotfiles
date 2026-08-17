# Linux-only. Self-guarding, same pattern as 70-darwin.zsh.
[[ "$OSTYPE" == linux* ]] || return 0

# GNU ls understands --color; BSD/macOS ls uses -G (set in 40-aliases.zsh).
# Only override when eza isn't providing ls.
(( $+commands[eza] )) || alias ls='ls --color=auto'
alias grep='grep --color=auto'

alias o='xdg-open'

# Clipboard, whichever display server is in play. Note tmux itself uses OSC 52
# (set-clipboard on), so this is only for piping outside tmux.
if (( $+commands[wl-copy] )); then
  alias pbcopy='wl-copy'
  alias pbpaste='wl-paste'
elif (( $+commands[xclip] )); then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

# Debian/Ubuntu package shorthands.
if (( $+commands[apt] )); then
  alias apti='sudo apt install'
  alias aptu='sudo apt update && sudo apt upgrade'
  alias apts='apt search'
fi
