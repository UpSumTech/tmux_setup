#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

PROJECTS_FILE="$HOME/.projects.json"

err() {
  echo "Error : $@" >/dev/stderr
  exit 1
}

hasSession() {
  local name="$1"
  # tmux has-session is buggy. It does partial match on session names and not exact match.
  tmux list-sessions | cut -f1 -d ':' | tr -d " " | grep "^${name}$" >/dev/null 2>&1
  [[ "$?" -eq 0 ]] && echo "true"
}

createWindowsAndPanes() {
  local name="$1"
  local dir="$2"

  tmux new-session -d -s "$name" -n ide -c "$dir"
  tmux new-window -k -n "cli" -t "$name":2 -c "$dir"
  tmux select-window -t "$name:2"
  tmux select-pane -t 1
  tmux split-window -h -p 50 -c "$dir"
  tmux select-pane -t 2
  tmux split-window -v -p 50 -c "$dir"
}

execCommands() {
  local name="$1"
  local dir="$2"

  (tmux send-keys -t "$name:1.1" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-1-1" C-m\; wait-for shell-ready-1-1)&
  (tmux send-keys -t "$name:2.1" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-2-1" C-m\; wait-for shell-ready-2-1)&
  (tmux send-keys -t "$name:2.2" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-2-2" C-m\; wait-for shell-ready-2-2)&
  (tmux send-keys -t "$name:2.3" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-2-3" C-m\; wait-for shell-ready-2-3)&
  wait

  tmux send-keys -t "$name:1.1" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir; vim" Enter
  tmux send-keys -t "$name:2.1" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir" Enter
  tmux send-keys -t "$name:2.2" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir; test -d .git && git status" Enter
  tmux send-keys -t "$name:2.3" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir" Enter
}

execGroupCommands() {
  local name="$1"
  local group="$2"
  local dir="$3"

  (tmux send-keys -t "$name:1.1" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-1-1" C-m\; wait-for shell-ready-1-1)&
  (tmux send-keys -t "$name:2.1" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-2-1" C-m\; wait-for shell-ready-2-1)&
  (tmux send-keys -t "$name:2.2" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-2-2" C-m\; wait-for shell-ready-2-2)&
  (tmux send-keys -t "$name:2.3" "sleep 3; cd $HOME && cd $dir; sleep 3; tmux wait-for -S shell-ready-2-3" C-m\; wait-for shell-ready-2-3)&
  wait

  tmux send-keys -t "$name:1.1" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir; vim" Enter
  tmux send-keys -t "$name:2.1" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir" Enter
  tmux send-keys -t "$name:2.2" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir; git status" Enter
  tmux send-keys -t "$name:2.3" C-z "export PROJECT_NAME=$name; export PROJECT_ROOT_DIR=$dir" Enter
}

setCursorPosition() {
  local name="$1"
  tmux select-window -t "$name:1"
}

startSession() {
  local name="$1"
  local dir="$2"
  local group="$3"

  [[ $( hasSession "$name" ) =~ true ]] && return

  createWindowsAndPanes "$name" "$dir"
  if [[ -z "$group" ]]; then
    execCommands "$name" "$dir"
  else
    execGroupCommands "$name" "$group" "$dir"
  fi
  setCursorPosition "$name"
}

killSession() {
  local name="$1"
  tmux kill-session -t "$name"
}

sourceConfig() {
  tmux source-file "$ROOT_DIR/config/settings.conf" >/dev/null 2>&1
  tmux source-file "$ROOT_DIR/config/bindings.conf" >/dev/null 2>&1
  tmux source-file "$ROOT_DIR/config/plugins.conf" >/dev/null 2>&1
  if [[ "$(uname)" = "Darwin" ]]; then
    tmux source-file "$ROOT_DIR/config/extras-osx.conf" >/dev/null 2>&1
  else
    tmux source-file "$ROOT_DIR/config/extras-linux.conf" >/dev/null 2>&1
  fi
  tmux source-file "$ROOT_DIR/config/patches.conf" >/dev/null 2>&1
}

getRepo() {
  [[ -d "$2" ]] || git clone "$1" "$2"
}

loopOverTempSessions() {
  local fn="$1"
  local sessionsInfo="${@:2}"
  local sessionInfo
  local name
  local dir

  for sessionInfo in ${sessionsInfo[@]}; do
    name="$(echo "$sessionInfo" | cut -d ':' -f1)"
    dir="$(echo "$sessionInfo" | cut -d ':' -f2)"
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
    eval "$(declare -F "$fn")" "$name" "$dir"
  done
}

loopOverGroupSessions() {
  local fn="$1"
  local group="$2"
  local name
  local repo
  local dir
  local len
  declare -a arr

  len=$(cat "$PROJECTS_FILE" | jq ".$group | length" | bc)
  for (( index=0; index<$len ; index++ )); do
    arr=( $(cat "$PROJECTS_FILE" | jq ".$group[$index] | [.name, .repo, .dir]" | sed -e "s#,##g;s#\[##g;s#\]##g;s#\"##g;s#\'##g") )
    name="${arr[0]}"
    repo="${arr[1]}"
    dir="${arr[2]}"
    getRepo "$repo" "$dir"
    eval "$(declare -F "$fn")" "$name" "$dir" "$group"
  done
}

loopOverSessions() {
  local fn="$1"
  local sessions="${@:2}"
  local session
  local name
  local repo
  local dir
  declare -a arr

  for session in ${sessions[@]}; do
    arr=( $(cat "$PROJECTS_FILE" | jq "flatten(1) | .[] | select(.name == \"$session\") | [.name, .repo, .dir]" | sed -e "s#,##g;s#\[##g;s#\]##g;s#\"##g;s#\'##g") )
    name="${arr[0]}"
    repo="${arr[1]}"
    dir="${arr[2]}"
    getRepo "$repo" "$dir"
    eval "$(declare -F "$fn")" "$name" "$dir"
  done
}

displayInfo() {
  tmux list-sessions
}

startGroupSessions() {
  local group="$1"

  sourceConfig
  loopOverGroupSessions startSession "$group"
}

startTempSessions() {
  local sessionsInfo="$@"

  sourceConfig
  loopOverTempSessions startSession "${sessionsInfo[@]}"
}

startSessions() {
  local sessions="$@"

  sourceConfig
  loopOverSessions startSession "${sessions[@]}"
}

startStandAloneSession() {
  local session="$1"
  shift 1
  local cmds="$@"
  sourceConfig
  [[ $( hasSession "$session" ) =~ true ]] && return
  tmux new-session -d -s "$session" -n cli
  tmux send-keys -t "$session:1.1" C-z "$cmds" Enter
}

wrapAroundServerStartForGroup() {
  local fn="$1"
  local group="$2"

  tmux new-session -d -s dummy
  eval "$(declare -F "$fn")" "$group"
  tmux kill-session -t dummy
}

wrapAroundServerStart() {
  local fn="$1"
  local sessions="${@:2}"

  tmux new-session -d -s dummy
  eval "$(declare -F "$fn")" "${sessions[@]}"
  tmux kill-session -t dummy
}

validate() {
  [[ $- != *i* ]] && return # Dont start tmux sessions if not in interactive mode

  [[ -z "$TMUX" ]] || err "Dont start nested tmux sessions"

  [[ -f "$PROJECTS_FILE" ]] \
    || err "Missing $HOME/.projects.json file"
}

usage() {
  echo "
  usage: $0 [OPTIONS] [group]

  This script sets up your tmux sessions if not already running

  OPTIONS:
  -h      Help menu.
  -s      Accepts a group name as argument. Start tmux sessions for that group.
  -S      Accepts a set of names as argument. Starts tmux sessions for those.
  -k      Accepts a group name as argument. Kills all tmux sessions for that group.
  -K      Accepts a set of names as argument. Kills tmux sessions for those.
  -t      Accepts a set of names and dirs as arguments in the format <name:dir>. Starts tmux sessions for those.
  "
}

main() {
  validate

  local option
  while getopts 's:k:S:K:t:T:h' option; do
    case $option in
      s)
        local group=${OPTARG}
        wrapAroundServerStartForGroup startGroupSessions "$group"
        displayInfo
        ;;
      S)
        local sessions=(${@:$((OPTIND-1))})
        wrapAroundServerStart startSessions "${sessions[@]}"
        displayInfo
        ;;
      k)
        local group=${OPTARG}
        loopOverGroupSessions killSession "$group"
        ;;
      K)
        local sessions=(${@:$((OPTIND-1))})
        loopOverSessions killSession "${sessions[@]}"
        displayInfo
        ;;
      t)
        local sessionsInfo=(${@:$((OPTIND-1))})
        wrapAroundServerStart startTempSessions "${sessionsInfo[@]}"
        displayInfo
        ;;
      T)
        local standAloneSession=${@:$((OPTIND-1)):1}
        local cmds=${@:$((OPTIND))}
        wrapAroundServerStart startStandAloneSession "$standAloneSession" "$cmds"
        ;;
      h)
        usage
        ;;
      *)
        err "This is not a valid option. Try the help menu with -h"
    esac
  done
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
