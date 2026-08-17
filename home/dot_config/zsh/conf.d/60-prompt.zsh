# Prompt.
#
# starship replaces oh-my-zsh's robbyrussell theme. The old config set
# ZSH_THEME="robbyrussell" *and* ran starship init afterwards, so the omz theme
# was already dead weight — starship always won.
#
# Config lives at ~/.config/starship.toml.
(( $+commands[starship] )) && eval "$(starship init zsh)"
