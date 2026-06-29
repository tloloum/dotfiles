
# power10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

 zstyle ':omz:update' frequency 1

ENABLE_CORRECTION="true"

# ZSH_CUSTOM=/path/to/new-custom-folder

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

alias ls='eza --long --icons=auto --hyperlink --color=auto --color-scale --color-scale-mode=gradient --no-quotes -all --sort type --no-user --time-style '+%Y-%m-%d''
alias tree='eza --long --icons=auto --hyperlink --color=always --color-scale --color-scale-mode=gradient --no-quotes -all --sort type --no-user --time-style '+%Y-%m-%d' --tree'

alias home='cd ~'


