export PATH="$HOME/bin:$PATH"

#  Prompt # blue / orange - pink
PROMPT='%B%(?.%F{039}√.%F{208}?%?)%f%b %B%F{199}%3~%f%b %# '

# Dotfiles auto-sync: fetch remote changes in background
if [[ -d "$HOME/dotfiles/.git" && -o interactive ]]; then
  (git -C "$HOME/dotfiles" fetch --quiet 2>/dev/null &)
fi

alias c="claude"

#General
alias python2="\python"
alias python="python3"
alias pip="pip3"

alias lctl="launchctl"
_SESSION_CMD_COUNT=0
_session_cmd_counter() { (( _SESSION_CMD_COUNT++ )) }
preexec_functions+=(_session_cmd_counter)

glogin() {
  gcloud auth application-default login && gcloud auth application-default set-quota-project toocan-dev
  if [[ $_SESSION_CMD_COUNT -le 1 ]]; then
    exit
  fi
}
alias gl="glogin"

alias zshrc="micro ~/.zshrc"
alias zv="code ~/.zshrc"
alias rzshrc="dotfiles_sync"
z() { if [ $# -eq 0 ]; then zshrc; else open -a /Applications/Zed.app "$@"; fi }
alias rz=rzshrc
alias zr=rzshrc
claude() {
  trap 'printf "\033]1337;SetColors=bg=1a1a1a\007" > /dev/tty 2>/dev/null' EXIT
  printf '\033]1337;SetColors=bg=2d2d3d\007' > /dev/tty 2>/dev/null
  command claude "$@"
}
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
alias gco="git checkout"
alias gc="git commit"
alias gca="git commit --amend --no-edit"
function gp() {
  echo "git (pu)ll or git (pu)sh? [l/s]: \c"
  read choice
  case "$choice" in
    l) git pull "$@" ;;
    s) git push "$@" ;;
    *) echo "Cancelled." ;;
  esac
}
alias gpll="git pull"
alias gpl="git pull"
alias gpsh="git push"
alias gps="git push"
alias gspp="git stash && git pull && git stash pop"

alias pnnn="pbpaste | tr '\n' ' ' | pbcopy"

alias ..="cd .."

# alias s="open -a /Applications/Sublime\ Text.app ."
alias f='open -a Finder ./'  
alias v="code"
alias zed="open -a /Applications/Zed.app ./"
alias s="open -a /Applications/Sourcetree.app ./"
alias t='open -a iTerm ./'
unalias dcu 2>/dev/null
_ensure_docker() {
  if ! docker info &>/dev/null; then
    echo "Starting Docker Desktop..."
    open -gja Docker
    while ! docker info &>/dev/null; do sleep 1; done
    echo "Docker is ready."
  fi
}

# Verify gcloud application-default credentials are valid (and refreshable),
# re-authing in-place if not. Unlike glogin, this never exits the window.
_ensure_gcloud() {
  if ! gcloud auth application-default print-access-token &>/dev/null; then
    echo "gcloud ADC expired or missing — re-authenticating..."
    gcloud auth application-default login && \
      gcloud auth application-default set-quota-project toocan-dev
  fi
}

# `down` ignores services behind a profile, which used to leave client-proxy up holding 443 (and
# the network) after a "successful" teardown. Enable every declared profile so down means down.
_dc_down() {
  local p flags=()
  for p in ${(f)"$(docker compose config --profiles 2>/dev/null)"}; do flags+=(--profile $p); done
  docker compose $flags down --remove-orphans "$@"
}

# toocan-app pins `name: qz` in docker-compose.yaml, so EVERY worktree is the same compose project
# and `ps -aq` here also sees a stack created elsewhere. Coming up on top of another worktree's
# containers reuses its bind mounts — which looks like "certs/ is missing" and 502s from
# client-proxy. Ctrl-C only stops containers, so stopped leftovers are the normal case: clear them
# and rebuild from here. Anything still alive belongs to another window, so bail instead.
_ensure_not_hijacking() {
  local cid=$(docker compose ps -aq 2>/dev/null | head -1)
  [[ -z $cid ]] && return 0
  local wd=$(docker inspect -f \
    '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "$cid" 2>/dev/null)
  [[ -z $wd || $wd == $PWD ]] && return 0

  local live
  live=$(docker compose ps -q --status running --status restarting --status paused 2>/dev/null)
  if [[ -n $live ]]; then
    echo "This compose project is already running from: ${wd/#$HOME/~}"
    echo "Run 'dcd' there (or here — same project) before starting it from ${PWD/#$HOME/~}."
    return 1
  fi

  echo "Clearing the stopped stack from ${wd/#$HOME/~} (named volumes kept) ..."
  local out
  out=$(_dc_down 2>&1) || { echo $out; return 1; }
}

# The https profile mounts ./certs, which is gitignored and therefore per-worktree. The mkcert CA
# is already installed and trusted, so re-issuing a leaf takes a second and needs no sudo.
_ensure_certs() {
  [[ -f certs/dev-cert.pem && -f certs/dev-key.pem ]] && return 0
  if ! command -v mkcert &>/dev/null; then
    echo "mkcert not installed — 'brew install mkcert && mkcert -install' for https."
    return 1
  fi
  echo "Issuing dev certs for *.qz.test in ${PWD/#$HOME/~}/certs ..."
  mkdir -p certs && mkcert -cert-file certs/dev-cert.pem -key-file certs/dev-key.pem \
    client.qz.test client-alt.qz.test api.qz.test
}

# Only ask for profiles this compose file actually declares, so dcu stays usable in other repos
# and on branches predating them. One-offs: QZ_DC_PROFILES="https sdk-test" dcu
_dc_profiles() {
  local want=(${=QZ_DC_PROFILES:-https sdk-example}) have p out=()
  have=(${(f)"$(docker compose config --profiles 2>/dev/null)"})
  for p in $want; do (( ${have[(Ie)$p]} )) && out+=(--profile $p); done
  print -r -- $out
}

# The host ports are fixed in the compose file, so a stack started under an explicit -p (qz2499
# et al) still owns them while being a different project — invisible to the check above, even
# when launched from this very directory. Anything holding them that isn't ours is a clash.
_port_clashes() {
  local mine
  mine=$(docker compose ps -aq 2>/dev/null) || return 0
  docker ps --format '{{.ID}}|{{.Names}}|{{.Ports}}|{{.Label "com.docker.compose.project"}}' \
    2>/dev/null | while IFS='|' read -r id name ports proj; do
      [[ $ports == *:443-\>* || $ports == *:5173-\>* || $ports == *:8765-\>* ]] || continue
      [[ -n $mine && $mine == *$id* ]] && continue
      echo "  $name — project '${proj:-none}'"
    done
}

dcu() {
  _ensure_docker
  _ensure_gcloud
  _ensure_not_hijacking || return 1

  local clashes=$(_port_clashes)
  if [[ -n $clashes ]]; then
    echo "443/5173/8765 are held by containers from elsewhere:"
    echo "${clashes//$HOME/~}"
    echo "Stop them first (docker compose -p <project> down)."
    return 1
  fi

  local profiles=(${=$(_dc_profiles)})
  if (( ${profiles[(Ie)https]} )); then
    _ensure_certs || return 1
    grep -q client-alt.qz.test /etc/hosts || echo "/etc/hosts is missing the .test names — \
sudo sh -c 'echo \"127.0.0.1 client.qz.test client-alt.qz.test api.qz.test\" >> /etc/hosts'"
  fi
  # sdk-example serves client-alt.qz.test from dist/, not src/ — a stale dist is a silent wrong test.
  if (( ${profiles[(Ie)sdk-example]} )) && [[ ! -d packages/sdk/dist ]]; then
    echo "packages/sdk/dist missing — 'pnpm --dir packages/sdk build' or client-alt.qz.test breaks."
  fi

  printf '\033]11;rgb:00/3f/8a\a'  # Docker blue background
  docker compose $profiles up "$@"
  printf '\033]111;\a'              # Restore default background
}

dcd() {
  local cid=$(docker compose ps -aq 2>/dev/null | head -1)
  if [[ -n $cid ]]; then
    local wd=$(docker inspect -f \
      '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "$cid" 2>/dev/null)
    [[ -n $wd && $wd != $PWD ]] && echo "Tearing down the stack from ${wd/#$HOME/~}"
  fi
  _dc_down "$@"
}
# Restart: args go to `up`, since that's the side you tend to flag (--build, a service name).
dcr() {
  dcd || return 1
  dcu "$@"
}

alias up="docker compose run --rm client pnpm install && docker compose up"

alias tc="cd ~/qz/toocan-app"
alias tccc="cd ~/qz/toocan-app && cc"
alias k8s="cd ~/qz/k8s-apps"
alias k8="cd ~/qz/k8s-apps"
alias qz="cd ~/qz && ls"
alias qzcc="cd ~/qz && cc"
alias k="kubectl"
alias kctx="kubectx"
alias kc="kubectx"
alias kcs="kubectx staging"
alias kcp="kubectx prod"

# k8s-apps qz cli — subshell so your cwd is unchanged when they exit
qzms() { (cd ~/qz/k8s-apps && uv run qz monitor staging "$@") }
qzmp() { (cd ~/qz/k8s-apps && uv run qz monitor prod "$@") }
qzd() { (cd ~/qz/k8s-apps && uv run qz deploy "$@") }

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
every() { while true; do setopt localoptions noglob; eval "${@:2}"; date >&2; sleep "$1"; done }

alias e1="every 1"
alias e2="every 2"
alias e5="every 5"
alias e10="every 10"
alias e15="every 15"

alias colourise="python ~/prog/colourise/colourise.py"

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

# Source secrets (API tokens etc.) — not tracked in dotfiles
[[ -f ~/.secrets ]] && source ~/.secrets

export EDITOR="nano"

export PATH="/usr/local/opt/libpq/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
# Eagerly add default node to PATH so node/npx work in non-interactive shells (git hooks, worktrees)
for _d in "$NVM_DIR"/versions/node/v"$(cat "$NVM_DIR/alias/default" 2>/dev/null)"*/bin; do
  [ -d "$_d" ] && export PATH="$_d:$PATH" && break
done
unset _d
lazy_load_nvm() {
  unset -f node npm npx pnpm nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
for cmd in node npm npx pnpm nvm; do
  eval "${cmd}() { lazy_load_nvm; ${cmd} \"\$@\" }"
done

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/tlynch/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/tlynch/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/tlynch/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/tlynch/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

# Functions
# Fuzzy-match one worktree directory. Echoes its path; message on stderr if it can't.
# Shared by `wt`, `wt rm` and `wtt` so the three cannot drift apart.
_wt_match() {
  local root=~/worktrees-qz/toocan-app
  local matches=("${(@f)$(find $root -mindepth 1 -maxdepth 1 -type d -name "*$1*")}")
  if [ ${#matches[@]} -eq 0 ] || [ -z "${matches[1]}" ]; then
    print -u2 "No worktree matching '$1'"; return 1
  elif [ ${#matches[@]} -eq 1 ]; then
    print -r -- "${matches[1]}"; return 0
  fi
  # An exact directory name wins outright, or `wt foo` can never reach foo when foo-bar exists.
  local m
  for m in "${matches[@]}"; do
    [ "${m##*/}" = "$1" ] && { print -r -- "$m"; return 0 }
  done
  print -u2 "Multiple matches:"
  local i=1
  for m in "${matches[@]}"; do print -u2 "  $i) ${m##*/}"; ((i++)); done
  print -n -u2 "Pick [1-${#matches[@]}]: "; local choice; read choice
  [ -n "${matches[$choice]}" ] || return 1
  print -r -- "${matches[$choice]}"
}

# wt                    list worktrees, newest first
# wt <string>           cd to the matching worktree
# wt add <pr|branch>    create one — a PR number, someone's branch, or a new branch
# wt pr <number>        same as `wt add <number>`, reads better
# wt rm <string>        remove a worktree and release its ports
# wt st                 status of all worktrees
# Mutations need a verb on purpose: a bare argument must never be able to create anything,
# or a typo while navigating would install dependencies and open a terminal.
wt() {
  local S=~/.claude/skills/worktree-manager/scripts
  case "$1" in
    "")
      cd ~/worktrees-qz/toocan-app && ls -t | head -15
      ;;
    add|pr)
      shift
      # Stream progress live (dependency installs are slow) while still capturing the final path,
      # so this can cd you into the new worktree.
      local log=$(mktemp)
      "$S/wtadd.sh" "$@" 2>&1 | tee "$log"
      local rc=$pipestatus[1]
      local target=$(sed -n 's/^  Path:  *//p' "$log" | tail -1)
      rm -f "$log"
      [ $rc -eq 0 ] || return $rc
      [[ -n "$target" && -d "$target" ]] && cd "$target"
      ;;
    rm)
      shift
      local target; target=$(_wt_match "$1") || return 1
      local branch=$(git -C "$target" branch --show-current 2>/dev/null)
      [ -n "$branch" ] || { print -u2 "wt rm: could not read a branch in $target"; return 1; }
      shift
      "$S/cleanup.sh" "${${target:h}:t}" "$branch" "$@"
      ;;
    st|status)
      shift; "$S/status.sh" "$@"
      ;;
    *)
      local target; target=$(_wt_match "$1") && cd "$target"
      ;;
  esac
}

# Launch a Claude agent in an existing worktree.
wtt() {
  if [ -z "$1" ]; then
    print "Usage: wtt <worktree-name>"; print "Worktrees:"; ls ~/worktrees-qz/toocan-app; return 1
  fi
  local target; target=$(_wt_match "$1") || return 1
  ~/.claude/skills/worktree-manager/scripts/launch-agent.sh "$target"
}

# Dotfiles auto-sync: commit, rebase, push after sourcing
dotfiles_sync() {
  # Source first — instant feedback
  source ~/.zshrc && echo ">> .zshrc updated"

  # Git sync in background subshell
  (
    local repo="$HOME/dotfiles"

    # Commit local changes if any
    if ! git -C "$repo" diff --quiet 2>/dev/null || \
       ! git -C "$repo" diff --cached --quiet 2>/dev/null; then
      git -C "$repo" add -A
      git -C "$repo" commit -m "update dotfiles from $(hostname -s)" --quiet
      # Fetch before pushing (background fetch may not have run yet)
      git -C "$repo" fetch --quiet 2>/dev/null
    fi

    # Rebase onto remote if they differ (uses already-fetched data)
    local local_head=$(git -C "$repo" rev-parse HEAD 2>/dev/null)
    local remote_head=$(git -C "$repo" rev-parse origin/main 2>/dev/null)
    if [[ -n "$remote_head" && "$local_head" != "$remote_head" ]]; then
      if ! git -C "$repo" rebase origin/main --quiet 2>/dev/null; then
        git -C "$repo" rebase --abort 2>/dev/null
        echo ">> dotfiles: CONFLICT — cd ~/dotfiles && git rebase origin/main"
        return 1
      fi
      git -C "$repo" push --quiet 2>/dev/null
    fi
  ) &!
}

# Keep Mac awake for N minutes: `caf 60` = 1 hour, `caf 20` = 20 minutes
caf() {
  local mins=${1:?usage: caf <minutes>}
  echo "caffeinating for ${mins}m..."
  caffeinate -dimsu -t $((mins * 60))
}

# Open a prod-Firestore-write window for N minutes (caffeinates + auto-reverts the deny tripwire).
#   qz-prod-write 30            # 30 min prod write + caffeinated, then auto re-arm
#   qz-prod-write --rearm-now   # panic button if a crash left access open
qz-prod-write() { ~/qz/scripts/qz-prod-write.sh "$@" }

# Added by Antigravity
export PATH="/Users/tomlynchdj/.antigravity/antigravity/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/tlynch/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/tlynch/.lmstudio/bin"
# End of LM Studio CLI section


# Set window + tab title; resumes a suspended job (e.g. Claude) afterward.
# Usage: Ctrl+Z, then `title cat and dog`  (no quotes needed)
title() { printf '\e]0;%s\a' "$*"; fg 2>/dev/null }

# opencode
export PATH=/Users/tlynch/.opencode/bin:$PATH
