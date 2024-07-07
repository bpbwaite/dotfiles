#
# ~/.bashrc
#


# Check if the shell is not running on a tty
if [[ "$TERM" != "linux" ]]; then
    # If not running on a tty, switch to zsh
    exec zsh;
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '
. "$HOME/.cargo/env"
