@echo off
SETLOCAL EnableDelayedExpansion

:: Access to external functions
call "%~dp0\..\..\bin\activate-juliawin-environment.bat"

if /i "%~1" EQU "--help"  goto :PRINT-HELP
if /i "%~1" EQU "-h"  goto :PRINT-HELP
if /i "%~1" EQU "/help"  goto :PRINT-HELP
if /i "%~1" EQU "/h"  goto :PRINT-HELP

:questionsstart
echo:

echo Note: For a posix shell experience in Julia, you will need a MinGW installation.
echo If you have Git installed, you may skip MinGW installation.
echo If you are unsure, go ahead and mark MinGW for installation.
echo:

for %%x in (MinGW VSCode Pluto PyCall Jupyter) do (
    call :PROMPT-YES-NO-RESET q %%x
    echo:
    if /i "!q!" equ "y" set "juliawin-install%%x=1"
    if /i "!q!" equ "n" set "juliawin-install%%x=0"
    if /i "!q!" equ "r" goto :questionsstart
    if /i "!q!" equ "" exit /b -1
)


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
goto :eof


::**************************
:: Prompt package
::**************************
:PROMPT-YES-NO-RESET <answer> <app>
    set "answer="
    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if /i "!answer!" neq "Y"  if /i "!answer!" neq "N" if /i "!answer!" neq "R" (
            echo Install %2...
            set /P answer="Yes, No, Reset questions [Y/N/R]? " || exit /b -1
        )
    )
    set "%~1=%answer%"
goto :eof