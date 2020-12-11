#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"
JULIA_HOME="$(realpath "$DIR/..")"
JULIA_PACKAGES="$JULIA_HOME/packages"


if test -f "$JULIA_PACKAGES/julia/bin/julia"; then
    choice=""
    echo "packages/julia/bin/julia exists!"
    while [[ "${choice,,}" != "y" && "${choice,,}" != "n" ]];
    do
      read -p "Overwrite [y/n]? " choice
      case "$choice" in
        n|N ) echo "Exit installation"; exit;;
      esac
    done
fi

#curl -g -L -f -o "/tmp/juliahomepage.html" "https://julialang.org/downloads/"
#julialink=$(cat "/tmp/juliahomepage.html" | tr '"' '\n' |  grep -o -P 'https.*bin/linux/x64/.*linux-x86_64.tar.gz' | head -n 1)
#
#echo "Got Julia link as $julialink"
#curl -g -L -f -o "/tmp/julia-linux-x86_64.tar.gz" "$julialink"
#
#rm -r -f "$JULIA_PACKAGES/julia"
#mkdir -p "$JULIA_PACKAGES/julia"
#tar -xzf "/tmp/julia-linux-x86_64.tar.gz" -C "$JULIA_PACKAGES/julia" --strip 1

source "$JULIA_HOME/bin-linux/activate-juliawin-environment.sh"

julia "$JULIA_HOME/internals/juliawin_cli.jl"