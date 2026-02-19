#  Prompt # blue / orange - pink 
PROMPT='%B%(?.%F{039}√.%F{208}?%?)%f%b %B%F{199}%3~%f%b %# '


#General
alias python2="\python"
alias python="python3"
alias pip="pip3"

alias lctl="launchctl"
alias glogin="gcloud auth application-default login && gcloud auth application-default set-quota-project toocan-dev"
alias gl="glogin"

alias zshrc="micro ~/.zshrc"
alias zv="code ~/.zshrc"
alias rzshrc="source ~/.zshrc && echo '>> .zshrc updated'"
alias z=zshrc
alias rz=rzshrc
alias zr=rzshrc
cc() {
  if [ $# -eq 0 ]; then
    claude
  elif [[ "$1" == -* ]]; then
    claude "$@"
  else
    claude "$*"
  fi
}
alias ccr="~/.claude/scripts/ccr.sh"
alias gs="git status"
alias gc="git commit"
alias gca="git commit --amend --no-edit"
alias gp="git push"
alias gspp="git stash && git pull && git stash pop"

alias pnnn="pbpaste | tr '\n' ' ' | pbcopy"

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

alias tc="cd ~/qz/toocan-app"
alias tccc="cd ~/qz/toocan-app && cc"
alias qz="cd ~/qz && ls"
alias qzcc="cd ~/qz && cc"
alias k="kubectl"
alias kubectl="date && kubectl"
alias kctx="kubectx"
alias kc="kubectx"
alias kcs="kubectx staging"
alias kcp="kubectx prod"
alias l="date && echo"
alias kar="k argo rollouts get rollout toocan-call-server"
alias kpodloop="while true; do k get pods; sleep 15;"

# Wait for a NEW pod to replace the given one, then alert
# Usage: kwait toocan-server-7bfbdbcc65-d499z [timeout_secs]
kwait() {
  local old_rs="${1%-*}"
  local prefix="${old_rs%-*}"
  local timeout="${2:-3600}"
  echo "Watching for new ready pod matching: ${prefix}-* (excluding RS ${old_rs})"
  local end=$((SECONDS + timeout))
  while (( SECONDS < end )); do
    local pod=$(command kubectl get pods --no-headers 2>/dev/null | grep "^${prefix}" | grep -v 'Terminating' | grep -v "^${old_rs}" | awk '{split($2,a,"/"); if (a[1]==a[2] && $3=="Running") print $1}' | head -1)
    if [[ -n "$pod" ]]; then
      printf '\a' && say "${prefix%%-*} is ready"
      echo "$pod is ready!"
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for ${prefix}-*"
  return 1
}

# Usage: every 5 echo "hello"
every() { while true; do eval "${@:2}"; sleep "$1"; done }

alias colourise="python /Users/tlynch/prog/colourise/colourise.py"

# Lighten/darken VS Code workspace colors
# Usage: lighten [-r to revert]
lighten() {
  local settings=".vscode/settings.json"
  local stash=".vscode/.lighten-orig"
  if [ ! -f "$settings" ]; then
    echo "No .vscode/settings.json found in current directory"
    return 1
  fi
  if [[ "$1" == "-r" ]]; then
    if [ ! -f "$stash" ]; then
      echo "No saved color to revert to (run lighten first)"
      return 1
    fi
    local orig=$(cat "$stash")
    sed -i '' \
      -e 's/\("activityBar.background"[[:space:]]*:[[:space:]]*"\)#[0-9a-fA-F]\{6\}"/\1'"$orig"'"/' \
      -e 's/\("titleBar.activeBackground"[[:space:]]*:[[:space:]]*"\)#[0-9a-fA-F]\{6\}"/\1'"$orig"'"/' \
      -e 's/\("titleBar.inactiveBackground"[[:space:]]*:[[:space:]]*"\)#[0-9a-fA-F]\{6\}"/\1'"$orig"'"/' \
      "$settings"
    local cur=$(grep -o '"activityBar.background"[[:space:]]*:[[:space:]]*"#[0-9a-fA-F]\{6\}"' "$settings" 2>/dev/null | grep -o '#[0-9a-fA-F]\{6\}' | head -1)
    rm "$stash"
    echo "$cur → $orig (reverted)"
    return 0
  fi
  local hex=$(grep -o '"activityBar.background"[[:space:]]*:[[:space:]]*"#[0-9a-fA-F]\{6\}"' "$settings" 2>/dev/null | grep -o '#[0-9a-fA-F]\{6\}' | head -1)
  if [ -z "$hex" ]; then
    echo "No activityBar.background color found in $settings"
    return 1
  fi
  echo "$hex" > "$stash"
  local r=$((16#${hex:1:2})) g=$((16#${hex:3:2})) b=$((16#${hex:5:2}))
  r=$(( r + (255 - r) * 25 / 100 ))
  g=$(( g + (255 - g) * 25 / 100 ))
  b=$(( b + (255 - b) * 25 / 100 ))
  local new=$(printf "#%02x%02x%02x" $r $g $b)
  sed -i '' \
    -e 's/\("activityBar.background"[[:space:]]*:[[:space:]]*"\)#[0-9a-fA-F]\{6\}"/\1'"$new"'"/' \
    -e 's/\("titleBar.activeBackground"[[:space:]]*:[[:space:]]*"\)#[0-9a-fA-F]\{6\}"/\1'"$new"'"/' \
    -e 's/\("titleBar.inactiveBackground"[[:space:]]*:[[:space:]]*"\)#[0-9a-fA-F]\{6\}"/\1'"$new"'"/' \
    "$settings"
  echo "$hex → $new"
}
alias lighter=lighten
export EDITOR="nano"

export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/tlynch/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/tlynch/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/tlynch/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/tlynch/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

# Functions
wt() {
  if [ -z "$1" ]; then
    cd ~/worktrees-qz/toocan-app && ls
  else
    local matches=("${(@f)$(find ~/worktrees-qz/toocan-app -maxdepth 1 -type d -name "*$1*")}")
    if [ ${#matches[@]} -eq 0 ]; then
      echo "No worktree matching '$1'"
    elif [ ${#matches[@]} -eq 1 ]; then
      cd "${matches[1]}"
    else
      echo "Multiple matches:"
      local i=1
      for m in "${matches[@]}"; do echo "  $i) ${m##*/}"; ((i++)); done
      echo -n "Pick [1-${#matches[@]}]: "; read choice
      cd "${matches[$choice]}"
    fi
  fi
}
