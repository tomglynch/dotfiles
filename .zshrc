#  Prompt # blue / orange - pink 
PROMPT='%B%(?.%F{039}√.%F{208}?%?)%f%b %B%F{199}%3~%f%b %# '


#General
alias python2="\python"
alias python="python3"
alias pip="pip3"

alias lctl="launchctl"
alias glogin="gcloud auth application-default login && gcloud auth application-default set-quota-project toocan-dev"

alias zshrc="code ~/.zshrc"
alias rzshrc="source ~/.zshrc && echo '>> .zshrc updated'"
alias z=zshrc
alias rz=rzshrc
alias zr=rzshrc
alias cc=claude
alias ccr=claude --resume
alias gspp="git stash && git pull && git stash pop"

alias ..="cd .."

# alias s="open -a /Applications/Sublime\ Text.app ."
alias f='open -a Finder ./'  
alias v="code"
alias zed="open -a /Applications/Zed.app ./"
alias s="open -a /Applications/Sourcetree.app ./"
alias t='open -a Terminal ./'  
alias dcu="docker compose up"
alias dcd="docker compose down"
alias up="docker compose run --rm client pnpm install && docker compose up"

alias wt="cd ~/tmp/worktrees/toocan-app && ls"
alias tc="cd ~/qz/toocan-app"
alias qz="cd ~/qz && ls"
alias k="kubectl"

alias colourise="python /Users/tlynch/prog/colourise/colourise.py"
export EDITOR="nano"

export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/tlynch/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/tlynch/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/tlynch/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/tlynch/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
