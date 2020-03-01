#! /usr/bin/env bash

set_tmux_pane_props() {
  local file
  local bgcolor
  local fgcolor
  local pane_id="$1"
  mkdir -p $HOME/tmp/tmux_setup
  file=$HOME/tmp/tmux_setup/vars_of_pane_$pane_id
  if [[ -s $file ]]; then
    bgcolor="$(cat $file | head -n 1 | cut -d '=' -f2)"
    fgcolor="$(cat $file | head -n 2 | tail -n 1 | cut -d '=' -f2)"
  fi
  [[ ! -z "$bgcolor" ]] || { bgcolor="default"; fgcolor="green"; }
  tmux set-option pane-active-border-style bg=$bgcolor,fg=$fgcolor
}

set_tmux_pane_props "$@"
