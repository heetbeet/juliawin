@echo off
SETLOCAL EnableDelayedExpansion


:: Access to external functions
set functions="%~dp0functions.bat"
call "%functions%" FULL-PATH juliawinhome "%~dp0.."

call %functions% ARG-PARSER %*
if "%ARG_h%%ARG_help%" NEQ "" (
    goto :PRINT-HELP
)

:: Test if we should forcefully install julia
if exist "%~dp0..\packages\julia\bin\julia.exe" if "%ARG_force%" neq "1" (
    call :PROMPT-FORCEINSTALL forceinstall
)
if /i "%forceinstall%" EQU "N" exit /b -1


:: Install Julia
call %functions% DELETE-DIRECTORY "%~dp0..\packages\julia" 2 > nul
call "%~dp0\bootstrap-julia-from-julialang-org.bat" /dest "%~dp0..\packages\julia"


:: Run juliawin installation script
call "%~dp0\juliawin.bat" --install


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
    echo   /h, /help      Print these options
    echo   /force         Overwrite current "/packages/julia" installation without prompt
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