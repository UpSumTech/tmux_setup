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

startSession() {
  local name="$1"
  local dir="$2"

  [[ $( hasSession "$name" ) =~ true ]] && return

  tmux new-session -d -s "$name" -n ide -c "$dir"
  tmux new-window -k -n "cli" -t "$name":2 -c "$dir"
  tmux select-window -t "$name:2"
  tmux select-pane -t 1
  tmux split-window -h -p 50 -c "$dir"
  tmux select-pane -t 2
  tmux split-window -v -p 33 -c "$dir"
  tmux select-pane -t 2
  tmux split-window -v -p 50 -c "$dir"
  tmux select-pane -t 1
}

killSession() {
  tmux kill-session -t "$1"
}

sourceSettings() {
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

  len=$(cat "$PROJECTS_FILE" | jq '.work[0] | length' | bc)
  for (( index=0; index<$len ; index++ )); do
    arr=( $(cat "$PROJECTS_FILE" | jq ".$group[$index] | [.name, .repo, .dir]" | sed -e "s#,##g;s#\[##g;s#\]##g;s#\"##g;s#\'##g") )
    name="${arr[0]}"
    repo="${arr[1]}"
    dir="${arr[2]}"
    getRepo "$repo" "$dir"
    eval "$(declare -F "$fn")" "$name" "$dir"
  done
}

validate() {
  [[ $- != *i* ]] && return # Dont start tmux sessions if not in interactive mode

  [[ -z "$TMUX" ]] || err "Dont start nested tmux sessions"

  [[ -f "$PROJECTS_FILE" ]] \
    || err "Missing $HOME/.projects.json file"
}

usage() {
  echo "
  usage: $0 [OPTIONS]

  This script sets up your tmux sessions if not already running

  OPTIONS:
  -h      Help menu
  -s      Accepts an argument. Start tmux sessions for that group
  -k      Kill all tmux sessions
  "
}

main() {
  validate
  sourceSettings

  local option
  while getopts 's:kh' option; do
    case $option in
      s)
        local group=${OPTARG}
        loopOverSessions startSession "$group"
        ;;
      k)
        loopOverSessions killSession "$group"
        ;;
      h)
        help
        ;;
      *)
        err "This is not a valid option. Try the help menu with -h"
    esac
  done

  tmux list-sessions
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
