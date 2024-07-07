# Created by newuser for 5.9
PROMPT="%n@%m%~$"

LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

# In case a command is not found, try to find the package that has it
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]] ; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}


alias diff='diff --color=auto'
alias grep='grep -n --color=auto'
alias ip='ip --color=auto'
#alias ls='ls --color=auto' # superceded by eza

alias please='sudo'
alias pls='sudo'
alias mkdir='mkdir -pv'

# Handy change dir shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# ls aliases
alias  l='eza -lh  --icons=auto' # long list
alias ls='eza -1   --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree' # list folder as tree

alias shork='~/shork/shork.sh'
alias :q='cowsay dumbass'
alias gpu='sudo ~/.local/bin/gpu-enable'

alias dots='vscodium ~/.dotfiles/'
alias pulldots='cd ~/.dotfiles && git pull && stow ./ '
alias pushdots='cd ~/.dotfiles && git commit -a -m "automated commit" && git push'

alias cd='z'

plugins=(git zsh-autosuggestions sudo)

eval "$(oh-my-posh init zsh --config ~/.themes/catppuccin.omp.json)"
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#eval $(thefuck --alias)
# MUST BE LAST
eval "$(zoxide init zsh)"
