@echo off

:: Don't repeatedly run this if everything is already set
if "%juliawin_activated%" equ "1" (
    goto :eof
)

set functions="%~dp0..\internals\scripts\functions.bat"

:: Set convenient variables
call %functions% FULL-PATH juliawin_home "%~dp0.."
set "juliawin_bin=%juliawin_home%\bin"
set "juliawin_packages=%juliawin_home%\packages"
set "juliawin_userdata=%juliawin_home%\userdata"
set "juliawin_splash=%juliawin_home%\internals\splashscreen\Juliawin-splash.hta"
call "%~dp0\activate-juliawin-sh-path.bat"


:: Set package specific environment variables
set "JULIA_DEPOT_PATH=%juliawin_userdata%\.julia"
set "ATOM_HOME=%juliawin_userdata%\.atom"
set "CONDA_JL_HOME=%juliawin_packages%\conda"


:: Make sure packages recompile after relocating
call "%~dp0\activate-juliawin-portability.bat"


:: These should also be set in Julia
:: Moved to juliawinconfig.jl; cannot set empty variables in bat
:: set "JULIA_PKG_SERVER="
:: set "PYTHON="

set "PATH=%juliawin_packages%\julia\libexec;%juliawin_packages%\julia\bin;%juliawin_packages%\curl\bin;%juliawin_packages%\vscode;%juliawin_packages%\atom;%juliawin_packages%\atom\resources\cli;%PATH%"

:: Set flag to indicate everything is already activated
set "juliawin_activated=1"
