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

# Arch package shorthands, named to match the apt trio above. Note `pacs` and
# not `ps` — `ps` is procps and aliasing it would break `ps aux`.
#
# paru is a drop-in for pacman that also covers the AUR, so prefer it when
# present. It is deliberately NOT run under sudo: it escalates per-operation and
# refuses to run as root.
if (( $+commands[pacman] )); then
  if (( $+commands[paru] )); then
    alias paci='paru -S'
    alias pacu='paru -Syu'
    alias pacs='paru -Ss'
  else
    alias paci='sudo pacman -S'
    alias pacu='sudo pacman -Syu'
    alias pacs='pacman -Ss'
  fi
  # Orphaned dependencies. `|| true` keeps it quiet when there are none, since
  # `pacman -Qtdq` exits 1 on an empty list.
  alias pacorphans='pacman -Qtdq || true'
fi
