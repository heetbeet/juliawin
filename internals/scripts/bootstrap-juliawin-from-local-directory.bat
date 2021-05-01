@echo off
SETLOCAL EnableDelayedExpansion

:: Access to external functions
call "%~dp0\..\..\bin\activate-juliawin-environment.bat"

call %functions% ARG-PARSER %*
if "%ARG_h%%ARG_help%" NEQ "" (
    goto :PRINT-HELP
)
if "%ARG_force%" equ "1" goto :forceoverwrite

:questionsstart
echo:

:: Test if we should forcefully install julia
if exist "%juliawin_packages%\julia\bin\julia.exe" (
    call :PROMPT-FORCEINSTALL forceinstall
    echo:
)


echo Note: For a posix shell experience in Julia, you will need a MinGW installation.
echo If you have Git installed, you may skip MinGW installation. 
echo If you are unsure, go ahead and mark MinGW for installation.
echo:

for %%x in (MinGW VSCode Juno Pluto PyCall Jupyter) do (
    call :PROMPT-YES-NO-RESET q %%x
    echo:
    if /i "!q!" equ "y" set "juliawin-install%%x=1"
    if /i "!q!" equ "n" set "juliawin-install%%x=0"
    if /i "!q!" equ "r" goto :questionsstart
)


:: See if Julia should force overwrite
if exist "%juliawin_packages%\julia\bin\julia.exe" (
    if /i "%forceinstall%" EQU "S" goto :skipoverwrite
    if /i "%forceinstall%" NEQ "O" exit /b -1
)

:forceoverwrite
    :: Install Julia
    call %functions% DELETE-DIRECTORY "%juliawin_packages%\julia" 2 > nul
    set "args="
    if "%ARG_use-nightly-build%" equ "1" (
        set "args=/use-nightly-build"
    )
    if "%ARG_use-beta-build%" equ "1" (
        set "args=/use-beta-build"
    )
    call "%~dp0\bootstrap-julia-from-julialang-org.bat" /dest "%juliawin_packages%\julia" %args%
:skipoverwrite

:: Run juliawin installation script
call "%juliawin_packages%\julia\bin\julia.exe" "%juliawin_home%\internals\juliawin_cli.jl" --install-dialog


echo:
echo () End of Juliawin installation
pause

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
    echo   /use-beta-build     Latest beta, possibly unstable
goto :eof


::**************************
:: Prompt forceinstall
::**************************
:PROMPT-FORCEINSTALL <answer>
    set "forceinstall="
    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if /i "!forceinstall!" neq "O"  if /i "!forceinstall!" neq "S" if /i "!forceinstall!" neq "C" (
            set /P forceinstall="Julia installation in packages\julia already exist. Overwrite, skip or cancel [O/S/C]? " || set forceinstall=xxxx
        )
    )
    set "%~1=%forceinstall%"
goto :eof


::**************************
:: Prompt package
::**************************
:PROMPT-YES-NO-RESET <answer> <app>
    set "answer="
    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if /i "!answer!" neq "Y"  if /i "!answer!" neq "N" if /i "!answer!" neq "R" (
            echo Install %2...
            set /P answer="Yes, No, Reset questions [Y/N/R]? " || set answer=xxxx
        )
    )
    set "%~1=%answer%"
goto :eof