# --- Historique ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history          
setopt hist_ignore_all_dups  

# --- Complétion ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # insensible à la casse

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# /!\ le syntax-highlighting DOIT être sourcé en DERNIER
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ll='ls -lah --color=auto'
alias ..='cd ..'
alias home='cd ~'
