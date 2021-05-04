@goto :batch-boilerplate-footer > /dev/null 2>&1 # > nul
# ****************************************************************************
# On Windows this script is run through bootstrapped-sh.cmd
# This script ensures that Julia is downloaded from Julialang.org
# ****************************************************************************

DIR="$(dirname "$0")"
. "$DIR/activate-juliawin-environment.sh"

juliapath="$juliawin_vendor/julia"
juliatmp="$juliawin_vendor/juliainstall.zip"

mkdir -p "$juliawin_vendor"
mkdir -p "$JULIA_DEPOT_PATH"

rm -f "$juliatmp"
rm -f "$juliatmp-tmp"

if [ -f "$juliapath/bin/julia.exe" ]; then
    "$juliapath/bin/julia.exe" "$@"
    exit $?
fi

echo "() Julia not installed, bootstrapping from Julialang.org"


hompageurl='https://julialang.org/downloads'
urlregex='https.*bin/winnt/x64/.*win64.zip'


htmlfile="$TEMP/juliahtmlfile$RANDOM$RANDOM.html"
for i in `seq 1 10`; do 
    if [ ! -f "$htmlfile" ]; then 
        curl -g -L -f -o "$htmlfile" "$hompageurl"; 
    fi 
done
downloadurl="$(cat "$htmlfile" | tr '"' '\n' | LC_ALL=en_US.utf8 grep -oP "$urlregex")"
rm -f "$htmlfile"

echo "() Download link: $downloadurl"

# Try downloading julia ten times
for i in `seq 1 10`; do 
    if [ ! -f "$juliatmp-tmp" ]; then
        curl -g -L -f -o "$juliatmp-tmp" "$downloadurl"
    fi
    if [ ! -f "$juliatmp-tmp" ]; then
        sleep .5;
    fi
done

mv -f "$juliatmp-tmp" "$juliatmp"
unzip -q -d "$juliapath" "$juliatmp"

mv "$juliapath"/julia-*/* "$juliapath"
rm -r "$juliapath"/julia-*


"$juliapath/bin/julia.exe" "$@"
exit $?


# ****************************************************************************
exit $?
:batch-boilerplate-footer
@echo off
call "%~dp0\bootstrapped-sh.cmd" "%~dp0%~n0.cmd" %*
exit /b %errorlevel%