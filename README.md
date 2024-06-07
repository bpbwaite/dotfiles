# Dotfiles


## Purpose:

+ Store any non-system (yet persistent) text configs

+ Manage cross-system dotfiles for consistency.
    + Dell XPS 7590
    + Custom built computer

+ Store necessary theme files and scripts for the dotfiles

## Usage

(A reminder for me)
```
~$ > git clone git@github.com:bpbwaite/dotfiles.git
; (if first time use)
~$ > cd .dotfiles
~$ > git pull
~/.dotfiles$ > stow --adopt .
; existing non-symlink files will overwrite files in the repo, but then be replaced with symlinks
~/.dotfiles$ > git reset --hard
; impose repository dotfiles

```
