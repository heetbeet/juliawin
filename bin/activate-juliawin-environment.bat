@echo off
set functions="%~dp0..\internals\scripts\functions.bat"


:: Set convenient variables
call %functions% FULL-PATH juliawin_home "%~dp0.."
set "juliawin_bin=%juliawin_home%\bin"
set "juliawin_packages=%juliawin_home%\packages"
set "juliawin_userdata=%juliawin_home%\userdata"


:: Set package specific environment variables
set "JULIA_DEPOT_PATH=%juliawin_userdata%\.julia"
set "ATOM_HOME=%juliawin_userdata%\.atom"
set "CONDA_JL_HOME=%juliawin_packages%\conda"


:: These should also be set in Julia (under juliawinconfig.jl)
:: set "JULIA_PKG_SERVER="
:: set "PYTHON="


:: Make sure packages recompile after relocating
call %functions% DELETE-COMPILED-PACKAGES-IF-RELOCATED "%juliawin_home%"


:: Return early if Windows Path environment is already set
call %functions% TEST-JULIAWIN-PATHS testflag
if "%testflag%" equ "1" (
    goto :EOF
)


:: Add all paths to Windows environment
call %functions% ADD-TO-PATH "%juliawin_packages%\julia\libexec"
call %functions% ADD-TO-PATH "%juliawin_packages%\julia\bin"
call %functions% ADD-TO-PATH "%juliawin_packages%\curl\bin"
call %functions% ADD-TO-PATH "%juliawin_packages%\resource_hacker"
call %functions% ADD-TO-PATH "%juliawin_packages%\vscode"
call %functions% ADD-TO-PATH "%juliawin_packages%\atom"
call %functions% ADD-TO-PATH "%juliawin_packages%\atom\resources\cli"
call %functions% ADD-TO-PATH "%juliawin_packages%\git\cmd"
