@echo off
SETLOCAL EnableDelayedExpansion


:: Access to external functions
call "%~dp0\set-juliawin-environment.bat"

call %functions% ARG-PARSER %*
if "%ARG_h%%ARG_help%" NEQ "" (
    goto :PRINT-HELP
)

:: Test if we should forcefully install julia
if "%ARG_force%" neq "1" if exist "%juliawin_packages%\julia\bin\julia.exe" (
    call :PROMPT-FORCEINSTALL forceinstall
)
if /i "%forceinstall%" EQU "N" exit /b -1


:: Install Julia
call %functions% DELETE-DIRECTORY "%juliawin_packages%\julia" 2 > nul
set "args="
if "%ARG_use-nightly-build%" equ "1" (
    set "args=/use-nightly-build"
)
call "%~dp0\bootstrap-julia-from-julialang-org.bat" /dest "%juliawin_packages%\julia" %args%


:: Run juliawin installation script
call "%juliawin_packages%\julia\bin\julia.exe" "%juliawin_home%\internals\juliawin_cli.jl" --install-dialog


goto :eof

::***************************
:: Print the help menu
::***************************
:PRINT-HELP
    echo Script to install Juliawin into a specified directory.
    echo:
    echo Usage:
    echo   %~n0 [options]
    echo Options:
    echo   /h, /help           Print these options
    echo   /force              Overwrite current "/packages/julia" installation without prompt
    echo   /use-nightly-build  For developer previews and not intended for normal use
goto :eof


::**************************
:: Prompt forceinstall
::**************************
:PROMPT-FORCEINSTALL <answer>
    set "%~1="
    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if /i "!forceinstall!" neq "Y"  if /i "!forceinstall!" neq "N" (
            set /P forceinstall="Julia installation in packages\julia exist, overwrite [Y/N]? "
        )
    )
    set "%~1=%forceinstall%"
goto :eof