#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

PROJECTS_FILE="$HOME/.projects.json"

err() {
  echo "Error : $@" >/dev/stderr
  exit 1
}

hasSession() {
  tmux has-session -t "$1" >/dev/null 2>&1
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
  local group="$1"
  local name="$2"
  tmux send-keys -t "$name:1.1" C-z "set_env_vars_for_group "$group" && vim" Enter
  tmux send-keys -t "$name:2.1" C-z "set_env_vars_for_group "$group"" Enter
  tmux send-keys -t "$name:2.2" C-z "set_env_vars_for_group "$group" && git status" Enter
  tmux send-keys -t "$name:2.3" C-z "set_env_vars_for_group "$group"" Enter
}

setCursorPosition() {
  local name="$1"
  tmux select-window -t "$name:1"
}

startSession() {
  local group="$1"
  local name="$2"
  local dir="$3"

  [[ $( hasSession "$name" ) =~ true ]] && return

  createWindowsAndPanes "$name" "$dir"
  execCommands "$group" "$name"
  setCursorPosition "$name"
}

killSession() {
  tmux kill-session -t "$2"
}

sourceConfig() {
  tmux source-file "$ROOT_DIR/config/settings.conf" >/dev/null
  tmux source-file "$ROOT_DIR/config/bindings.conf" >/dev/null
}

getRepo() {
  [[ -d "$2" ]] || git clone "$1" "$2"
}

loopOverSessions() {
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
    eval "$(declare -F "$fn")" "$group" "$name" "$dir"
  done
}

displayInfo() {
  tmux list-sessions
}

startSessions() {
  local group="$1"
  sourceConfig
  loopOverSessions startSession "$group"
}

wrapAroundServerStart() {
  local fn="$1"
  local group="$2"
  tmux new-session -d -s dummy
  eval "$(declare -F "$fn")" "$group"
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
  -k      Accepts a group name as argument. Kills all tmux sessions for that group.
  "
}

main() {
  validate

  local option
  while getopts 's:k:h' option; do
    case $option in
      s)
        local group=${OPTARG}
        wrapAroundServerStart startSessions "$group"
        displayInfo
        ;;
      k)
        local group=${OPTARG}
        loopOverSessions killSession "$group"
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
