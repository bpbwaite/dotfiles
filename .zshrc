# Created by newuser for 5.9
PROMPT="%n@%m%~$"

LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

alias diff='diff --color=auto'
alias grep='grep -n --color=auto'
alias ip='ip --color=auto'
alias ls='ls --color=auto'

alias please='sudo'
alias pls='sudo'
alias mkdir='mkdir -pv'
alias ..='cd ..'

alias shark='cd ~/shork && ./shork.sh'
alias :q='cowsay dumbass'
alias pulldots='cd ~/.dotfiles && git pull && stow ./ '
alias pushdots='cd ~/.dotfiles && git commit -a -m "automated commit" && git push'

plugins=(git zsh-autosuggestions sudo)

eval "$(oh-my-posh init zsh --config ~/.themes/catppuccin.omp.json)"

eval $(thefuck --alias)
# MUST BE LAST
eval "$(zoxide init zsh)"
