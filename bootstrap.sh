#!/bin/bash

LIB_DIR="$HOME/lib"
BIN_DIR="$HOME/bin"

prep() {
  [[ -d "$LIB_DIR" ]] || mkdir "$LIB_DIR"
  [[ -d "$BIN_DIR" ]] || mkdir "$BIN_DIR"
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
  prep
  cloneRepo
  build
  generateBin
  echo "
    You need to export the new $HOME/bin in your path.
    You can open your ~/.bashrc or ~/.profile file and add this line at the bottom.

    export PATH=$HOME/bin:$PATH

    If you already have this in your path don't worry.
  "
}

main
