#!/bin/bash


add_to_path () {
  [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:${PATH}"
}


recompile_when_relocate () {
  echo TODO: make sure Julia recompiles after relocating
}


# Set localised paths
DIR="$(dirname "$(readlink -f "$0")")"
JULIA_HOME="$(realpath "$DIR/..")"
JULIA_PACKAGES="$JULIA_HOME/packages"
JULIAWIN_BIN="$JULIA_HOME/bin"
JULIAWIN_USERDATA="$JULIA_HOME/userdata"


# Redirect user data to local directories
JULIA_DEPOT_PATH="JULIAWIN_USERDATA\.julia"
ATOM_HOME="JULIAWIN_USERDATA\.atom"
CONDA_JL_HOME="JULIAWIN_PACKAGES\conda"
JULIA_PKG_SERVER=""
PYTHON=""


# Add to PATH
add_to_path "$JULIAWIN_PACKAGES\julia\libexec"
add_to_path "$JULIAWIN_PACKAGES\julia\bin"
add_to_path "$JULIAWIN_PACKAGES\vscode"
add_to_path "$JULIAWIN_PACKAGES\atom"
add_to_path "$JULIAWIN_PACKAGES\atom\resources\cli"
