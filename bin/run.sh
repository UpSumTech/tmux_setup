#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

PROJECTS_FILE="$HOME/.projects.conf"

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
  local line
  while read -r line; do
    local name="$( echo "$line" | cut -d ' ' -f1 )"
    local repo="$( echo "$line" | cut -d ' ' -f2 )"
    local dir="$( echo "$line" | cut -d ' ' -f3 )"
    getRepo "$repo" "$dir"
    eval "$(declare -F "$fn")" "$name" "$dir"
  done < "$PROJECTS_FILE"
}

validate() {
  [[ $- != *i* ]] && return # Dont start tmux sessions if not in interactive mode

  [[ -z "$TMUX" ]] || err "Dont start nested tmux sessions"

  [[ -f "$PROJECTS_FILE" ]] \
    || err "Missing $HOME/.projects.conf file"
}

usage() {
  echo "
  usage: $0 [OPTIONS]

  This script sets up your tmux sessions if not already running

  OPTIONS:
  -h      Help menu
  -s      Start all tmux sessions
  -k      Kill all tmux sessions
  "
}

main() {
  validate
  sourceSettings

  local option
  while getopts 'skh' option; do
    case $option in
      s)
        loopOverSessions startSession
        ;;
      k)
        loopOverSessions killSession
        ;;
      h)
        help
        ;;
      *)
        err "This is not a valid option. Try the help menu with -h"
    esac
  done
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
