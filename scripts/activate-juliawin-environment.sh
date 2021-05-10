#********************************************************
# Note that bash can't get the filename of a sourced file
# You will have to source like this:
# cd "$DIR"/../scripts; . activate-juliawin-environment.sh; cd "$DIR"
#********************************************************

#!/bin/bash
if [ "$juliawin_activated" != "1" ]; then
  export juliawin_home="$(realpath "$(pwd)"/..)"
  export juliawin_bin="$juliawin_home/bin"
  export juliawin_vendor="$juliawin_home/vendor"
  export juliawin_splash="$juliawin_home/internals/splashscreen/Juliawin-splash.hta"
  export juliawin_userdata="$juliawin_home/userdata"
  export juliawin_last_seen_path="$juliawin_userdata/last-seen-path.txt"
  export juliawin_julia="$juliawin_vendor/julia/bin/julia"

  export juliawin_iswindows=0
  juliawin_osname="$(uname -s)"
  [[ "$juliawin_osname" == MINGW* || "$juliawin_osname" == CYGWIN* ]] && export juliawin_iswindows=1
  [ "$juliawin_iswindows" == "1" ] && export juliawin_julia="$juliawin_julia.exe"


  # Set package specific environment variables
  export JULIA_DEPOT_PATH="$juliawin_userdata/.julia"
  export ATOM_HOME="$juliawin_userdata/.atom"
  export CONDA_JL_HOME="$juliawin_vendor/conda"
  export JULIA_PKG_SERVER=""
  export PYTHON=""


  # Prepend all the paths to PATH
  normpath="$juliawin_vendor"
  [ "$juliawin_iswindows" == "1" ] && normpath="$(cygpath "$normpath")"
  addtopath="$normpath/julia/libexec:$normpath/julia/bin:$normpath/vscode:$normpath/atom:$normpath/atom/resources/cli"
  if [ ! "$PATH" == *"$addtopath"* ]; then
    export PATH="$addtopath:$PATH";
  fi


  # Only ensure portability once (since it's expensive)
  last_seen_path="$juliawin_bin"
  [ -f "$juliawin_last_seen_path" ] && last_seen_path="$(cat "$juliawin_last_seen_path")"

  if [ "$(realpath $juliawin_home)" != "$(realpath $last_seen_path)" ]; then
    
    # Find and replace conda path in qt.conf
    qtconf="$juliawin_vendor/conda/qt.conf"
    if [ -f "$qtconf" ]; then
      oldpath="$(cat "$qtconf" | LC_ALL=en_US.utf8 grep -oP -m 1 "=.*/conda/")";
      oldpath="${oldpath#=}";
      oldpath="${oldpath# }";

      sed -i "s|$oldpath|$juliawin_vendor/conda/|g" "$qtconf"
    fi

    # Force relative paths in conda scripts
    if [ -f "$juliawin_vendor/conda/Scripts/activate" ]; then
      "$juliawin_vendor/conda/python" "$juliawin_home/scripts/force-conda-paths-in-sh-scripts.py"
    fi

    # Delete compiled packages
    rm -rf "$juliawin_userdata\.julia\compiled"
    rm -rf "$juliawin_userdata\.julia\conda"
    rm -rf "$juliawin_userdata\.julia\prefs\IJulia"

    if [ -d "$juliawin_userdata\.julia\packages\IJulia" ]; then
      # IJulia builds both Conda and IJulia
      [ "$juliawin_iswindows" == "1" ] &&  start "" "$juliawin_splash"
      "$juliawin_julia" -e 'using Pkg; Pkg.build("PyCall"); Pkg.build("IJulia");'
      [ "$?" == "0" ] && echo "$juliawin_home" > "$juliawin_last_seen_path"

    elif [ -d "$juliawin_userdata\.julia\packages\Conda" ]; then
      # This only builds Conda
      [ "$juliawin_iswindows" == "1" ] &&  start "" "$juliawin_splash"
      "$juliawin_julia" -e 'using Pkg; Pkg.build("PyCall"); Pkg.build("Conda");'
      [ "$?" == "0" ] && echo "$juliawin_home" > "$juliawin_last_seen_path"
    else
      echo "$juliawin_home" > "$juliawin_last_seen_path"
    fi

  fi

  export juliawin_activated=1

fi