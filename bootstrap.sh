#!/bin/bash

LIB_DIR="/usr/local/lib"
BIN_DIR="/usr/local/bin"

die() {
  echo >&2 "Error : $@"
  exit 1;
}

validate() {
  [[ -w "$LIB_DIR" ]] || die "User does not have write permission for $LIB_DIR"
  [[ -w "$BIN_DIR" ]] || die "User does not have write permission for $BIN_DIR"
}

cloneRepo() {
  rm -rf "$LIB_DIR/tmux_setup" >/dev/null 2>&1 # Careful with this command
  git clone "git@github.com:sumanmukherjee03/tmux_setup.git" "$LIB_DIR/tmux_setup"
}

build() {
  pushd "$LIB_DIR/tmux_setup"
  make install
  popd
}

generateBin() {
  ln -sf "$LIB_DIR/tmux_setup/tmux_setup" "$BIN_DIR/tmux_setup"
}

main() {
  validate
  cloneRepo
  build
  generateBin
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
