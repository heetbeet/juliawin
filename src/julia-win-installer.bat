@echo off
SETLOCAL EnableDelayedExpansion
:: =====================================================
:: This is an automatic install script for Julia
::
:: The batch part makes sure the environment is set up
:: correctly and that Julia is available, while the
:: heavy lifting is done in Julia itself.
:: =====================================================

:: To minimise unsuspecting clashes, reset path to minimal OS programs
set "PATH=%systemroot%;%systemroot%\System32;%systemroot%\System32\WindowsPowerShell\v1.0;%systemroot%\System32\wbem"


:: Access to external functions
set func="%~dp0functions.bat"

:: Parse the arguments
call %func% ARG-PARSER %*


if "%ARG_debug%" EQU "1" echo %*

:: Set the location to the sister-scripts
set "batfile=%~dp0%~n0.bat"
set "juliafile=%~dp0%~n0.jl"

set "temphome=%temp%"


:: ========== Help Menu ===================
if "%ARG_NOBANNER%" EQU "" CALL %func% SHOW-JULIA-ASCII

if "%ARG_H%" EQU "1" goto help
if "%ARG_HELP%" EQU "1" goto help
goto exithelp

:help
ECHO The setup program accepts one command line parameter.
Echo:
ECHO /HELP, /H
ECHO   Show this information and exit.
ECHO /DIR "x:\Dirname"
ECHO   Overwrite the default with custom directory.
ECHO /NO-REPL
ECHO   Disable the pop-up REPL that is launched while waiting for the installer
goto :EOF
:exithelp


:: ========== Setup Environment ============
set "tempdir=%temp%\juliawin"
mkdir "%tempdir%" 2>NUL

set "toolsdir=%tempdir%\tools"
mkdir "%toolsdir%" 2>NUL
SET "PATH=%toolsdir%;%PATH%"

set "install-directory=%userprofile%\Juliawin"

echo %batfile% > "%tempdir%\batfile.txt"


:: ========== Custom path provided =========
IF /I "%ARG_DIR%" NEQ "" set "install-directory=%ARG_DIR%"


:: ========== Default configurations =========
set "config=%tempdir%\juliawin-config.bat"

echo :: Save and exit to overwrite the defaults. Don't add spaces! >  "%config%"
echo: >> "%config%"
echo set "juliawin-directory=%install-directory%" >> "%config%"
echo: >> "%config%"
echo set "install-juno=1" >> "%config%"
echo set "install-pluto=1" >> "%config%"
echo set "install-vscode=1" >> "%config%"
echo set "install-python-jupyter=0" >> "%config%"
echo: >> "%config%"
echo set "add-juliawin-to-user-path=0" >> "%config%"

call "%config%"

:: ========== May we skip to the installation part? ===========
if "%ARG_skipinitial%" NEQ "" goto :skipinitial


:: ========== Choose Install Dir ===========
if "%ARG_Y%" EQU "1" goto exitchoice
:choice
Echo:
Echo   [E]dit: choose my own settings
Echo   [D]efault: use default settings
Echo   [C]ancel: cancel the installation
Echo:
set /P c="Edit default settings for %install-directory% [E/D/C]? "
if /I "%c%" EQU "E" goto :selectdir
if /I "%c%" EQU "D" goto :exitchoice
if /I "%c%" EQU "C" goto :EOF-DEAD
goto :choice
:selectdir

echo Please edit your selection in Notepad
call %func% GET-SETTINGS-VIA-BAT-FILE "%config%"

:exitchoice

call %func% DOWNLOAD-FROM-GITHUB-DIRECTORY "https://github.com/heetbeet/juliawin/tree/master/src" "%tempdir%\src"
call %func% DOWNLOAD-FROM-GITHUB-DIRECTORY "https://github.com/heetbeet/juliawin/tree/master/assets" "%tempdir%\assets"

if "%ARG_debug%" NEQ "1" goto :overwite_local
    robocopy "%~dp0." "%tempdir%\src" /s /e > nul 2>&1
    robocopy "%~dp0..\assets" "%tempdir%\assets" /s /e  > nul 2>&1
:overwite_local


:: ========== Restart from the downloaded script ===========
call "%tempdir%\src\julia-win-installer.bat" /SKIPINITIAL /NOBANNER /DIR "%install-directory%" %*
GOTO :EOF

:skipinitial


:: ========== Ensure install dir is r/w ====
mkdir "%install-directory%" 2>NUL
echo: > "%install-directory%\thisisatestfiledeleteme"
del /f /q "%install-directory%\thisisatestfiledeleteme" >nul 2>&1
if %errorlevel% NEQ 0 (
    ECHO: 1>&2
    ECHO Error, can't read/write to %install-directory% 1>&2
    goto :EOF-DEAD
)

:: ========== Ensure no files in dir ====
:: Test if directory is empty/clean
rmdir "%install-directory%" >nul 2>&1
mkdir "%install-directory%" >nul 2>&1
if "%errorlevel%" EQU "0" goto :directoryisgood
    :: directory is not good...
    :diremptychoice
    set /P c="Directory is not empty. Force delete and continue [Y/N]? "
    if /I "%c%" EQU "_" goto :directoryisgood_skipdelete
    if /I "%c%" EQU "Y" goto :directoryisgood
    if /I "%c%" NEQ "N" goto diremptychoice

    ECHO: 1>&2
    ECHO Error: the install directory is not empty. 1>&2
    ECHO:
    ECHO You can run the remove command and try again: 1>&2
    ECHO ^>^> rmdir /s "%install-directory%" 1>&2
    goto :EOF-DEAD

:directoryisgood

call %func% DELETE-DIRECTORY "%install-directory%" >nul 2>&1
mkdir "%install-directory%" >nul 2>&1

:directoryisgood_skipdelete

:: ========== Log paths to txt files ==
echo %install-directory% > "%tempdir%\install-directory.txt"

set "packagedir=%install-directory%\packages"
mkdir "%packagedir%" >nul 2>&1
echo %packagedir% > "%tempdir%\packagedir.txt"

set "userdatadir=%install-directory%\userdata"
mkdir "%userdatadir%" >nul 2>&1
echo %userdatadir% > "%tempdir%\userdatadir.txt"


:: ========== Download and install latest julia
ECHO:
ECHO () Configuring the download source

call %SYSTEMROOT%\System32\curl.exe --help >nul 2>&1
if "%errorlevel%" NEQ "0" call %func% BOOTSTRAP-CURL "%tempdir%\tools"


call %func% GET-DL-URL juliaurl "https://julialang.org/downloads" "https.*bin/winnt/x64/.*win64.exe"
if "%errorlevel%" NEQ "0" goto :EOF-DEAD "Error: could not find Julia download link from https://julialang.org/downloads"

call %func% GET-URL-FILENAME juliafname "%juliaurl%"
call %func% DIR-NAME-EXT _ juliadirname _ "%juliafname%"


ECHO () Download %juliaurl% to
ECHO () %tempdir%\%juliafname%


call %func% DOWNLOAD-FILE "%juliaurl%" "%tempdir%\%juliafname%"
if "%errorlevel%" NEQ "0" goto :EOF-DEAD "Error: could not download Julia from %juliaurl%"

ECHO () Extracting into %packagedir%\%juliadirname%
call %func% EXTRACT-INNO "%tempdir%\%juliafname%" "%packagedir%\%juliadirname%"
call :SET-PATHS

:: ========== Run Julia code scripts ======
call julia --color=yes -e "Base.banner()"

call julia "%juliafile%" ADD-STARTUP-SCRIPT
call julia "%juliafile%" INSTALL-CURL
call :SET-PATHS

call julia "%juliafile%" INSTALL-RESOURCEHACKER
call :SET-PATHS

call julia "%juliafile%" ADD-JULIA-EXE

IF "%ARG_NO-REPL%" EQU "1" goto :skip_repl
    start cmd /c "julia --color=yes -e "Base.banner()" & echo Welcome to Julia^! & echo You can play in this REPL while waiting for the installer to finish & echo: & julia --banner=no"
:skip_repl

if "%add-juliawin-to-user-path%" equ "1"(
    setx PATH "%juliawin-directory%;%PATH%"
)

if "%install-pluto%" equ "1" (
    call :SET-PATHS
    call julia "%juliafile%" INSTALL-PLUTO
)

if "%install-vscode%" equ "1" (
    call julia "%juliafile%" INSTALL-VSCODE
)

if "%install-juno%" equ "1" (
    call julia "%juliafile%" INSTALL-ATOM
    call julia "%juliafile%" INSTALL-JUNO
)

if "%install-python-jupyter%" equ "1" (
   call julia "%juliafile%" INSTALL-JUPYTER
)

echo () End of installation

:: ========== Clean up after ourselves ====
:removetmp
set /P c="Clean up leftover files in %tmp%\juliawin [Y/N]? "
if /I "%c%" NEQ "Y" if /I "%c%" NEQ "N" goto :removetmp
if /I "%c%" EQU "Y" (
    REM Delete current .bat without error https://stackoverflow.com/a/20333575/1490584
    (goto) 2>nul & call %func% DELETE-DIRECTORY "%tempdir%" >nul 2>&1
)

goto :EOF
:: ***********************************************
:: Set PATH variables (rerun when more packages are available)
:: ***********************************************
:SET-PATHS
    call %func% ADD-TO-PATH "%toolsdir%"
    call %func% ADD-ASTERIXABLE-TO-PATH "%packagedir%\julia-*" "bin"
    call %func% ADD-ASTERIXABLE-TO-PATH "%packagedir%\julia-*" "libexec"
    call %func% ADD-ASTERIXABLE-TO-PATH "%packagedir%\atom-*"
    call %func% ADD-ASTERIXABLE-TO-PATH "%packagedir%\atom-*" "resources\cli"
    call %func% ADD-ASTERIXABLE-TO-PATH "%packagedir%\curl*"  "bin"
    call %func% ADD-ASTERIXABLE-TO-PATH "%packagedir%\nsis*"  "bin"
    call %func% ADD-ASTERIXABLE-TO-PATH "%packagedir%\resource_hacker*" "bin"

    set "JULIA_DEPOT_PATH=%userdatadir%\.julia"
    set "ATOM_HOME=%userdatadir%\.atom"
goto :EOF


:: ***********************************************
:: End in error
:: ***********************************************
:EOF-DEAD <message>
    if "%~1" NEQ "" echo %~1
    exit /b 1
