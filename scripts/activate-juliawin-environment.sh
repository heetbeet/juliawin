DIR="$(dirname "$(readlink -f "$0")")"

# Set convenient variables
export juliawin_home="$(realpath $DIR/..)"
export juliawin_bin="$juliawin_home/bin"
export juliawin_vendor="$juliawin_home/vendor"
export juliawin_userdata="$juliawin_home/userdata"

# Set package specific environment variables
export JULIA_DEPOT_PATH="$juliawin_userdata/.julia"
export ATOM_HOME="$juliawin_userdata/.atom"
export CONDA_JL_HOME="$juliawin_vendor/conda"
export JULIA_PKG_SERVER=""
export PYTHON=""

# Add all the relavant paths
export PATH="$juliawin_vendor\julia\libexec:$juliawin_vendor\julia\bin:$juliawin_vendor\vscode:$juliawin_vendor\atom:$juliawin_vendor\atom\resources\cli:$PATH"