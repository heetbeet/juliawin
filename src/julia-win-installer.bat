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
set "PATH=%systemroot%;%systemroot%\System32;%systemroot%\System32\WindowsPowerShell\v1.0"

:: Access to external functions
set func="%~dp0functions.bat"

:: Parse the arguments
call %func% ARG-PARSER %*

if "%ARG_DEBUG%" EQU "1" echo %*

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
ECHO /P
ECHO   Pause before exit. (Default behaviour when double-clicking this bat file.)
ECHO /Y
ECHO   Yes to all.
ECHO /DIR "x:\Dirname"
ECHO   Overwrite the default with custom directory.
goto :EOF
:exithelp


:: ========== Setup Environment ============
set "tempdir=%temp%\juliawin"
mkdir "%tempdir%" 2>NUL

set "toolsdir=%tempdir%\tools"
mkdir "%toolsdir%" 2>NUL
SET "PATH=%toolsdir%;%PATH%"

set "installdir=%userprofile%\Juliawin"

echo %batfile% > "%tempdir%\batfile.txt"


:: ========== Custom path provided =========
IF /I "%ARG_DIR%" NEQ "" set "installdir=%ARG_DIR%"

:: ========== May we skip to the installation part? ===========
if "%ARG_skipinitial%" NEQ "" goto :skipinitial


:: ========== Choose Install Dir ===========
IF "%ARG_DIR%" NEQ ""  goto exitchoice
if "%ARG_Y%" EQU "1" goto exitchoice
:choice
Echo:
Echo   [Y]es: continue
Echo   [N]o: cancel the operation
Echo   [D]irectory: choose my own directory
Echo:
set /P c="Install Julia in %installdir% [Y/N/D]? "
if /I "%c%" EQU "Y" goto :exitchoice
if /I "%c%" EQU "N" goto :EOF-DEAD
if /I "%c%" EQU "D" goto :selectdir
goto :choice
:selectdir

call %func% BROWSE-FOR-FOLDER installdir
if /I "%installdir%" EQU "Dialog Cancelled" (
    ECHO: 1>&2
    ECHO Dialog box cancelled 1>&2
    goto :EOF-DEAD
)

if /I "%installdir%" EQU "" (
    ECHO: 1>&2
    ECHO Error, folder selection broke 1>&2
    goto :EOF-DEAD
)
:exitchoice

if "%ARG_DEBUG%" NEQ "1" (
    call %func% :DOWNLOAD-FROM-GITHUB-DIRECTORY "https://github.com/heetbeet/juliawin/tree/refactor/src" "%tempdir%\src"
    call %func% :DOWNLOAD-FROM-GITHUB-DIRECTORY "https://github.com/heetbeet/juliawin/tree/refactor/assets" "%tempdir%\assets"
) ELSE (
    robocopy "%~dp0." "%tempdir%\src" /s /e
    robocopy "%~dp0..\assets" "%tempdir%\assets" /s /e
)


:: ========== Restart from the downloaded script ===========
call "%tempdir%\src\julia-win-installer.bat" /SKIPINITIAL /NOBANNER /DIR "%installdir%" %*
GOTO :EOF

:skipinitial


:: ========== Ensure install dir is r/w ====
mkdir "%installdir%" 2>NUL
echo: > "%installdir%\thisisatestfiledeleteme"
del /f /q "%installdir%\thisisatestfiledeleteme" >nul 2>&1
if %errorlevel% NEQ 0 (
    ECHO: 1>&2
    ECHO Error, can't read/write to %installdir% 1>&2
    goto :EOF-DEAD
)


:: ========== Ensure no files in dir ====
:: Test if directory is empty/clean
rmdir "%installdir%" >nul 2>&1
mkdir "%installdir%" >nul 2>&1
if "%errorlevel%" EQU "0" goto :directoryisgood
    :: directory is not good...
    :diremptychoice
    set /P c="Directory is not empty. Force delete and continue [Y/N]? "
    if /I "%c%" NEQ "Y" if /I "%c%" NEQ "N" goto diremptychoice
    if /I "%c%" EQU "Y" goto :directoryisgood

    ECHO: 1>&2
    ECHO Error: the install directory is not empty. 1>&2
    ECHO:
    ECHO You can run the remove command and try again: 1>&2
    ECHO ^>^> rmdir /s "%installdir%" 1>&2
    goto :EOF-DEAD

:directoryisgood

call %func% DELETE-DIRECTORY "%installdir%" >nul 2>&1
mkdir "%installdir%" >nul 2>&1


:: ========== Log paths to txt files ==
echo %installdir% > "%tempdir%\installdir.txt"

set "packagedir=%installdir%\packages"
mkdir "%packagedir%" >nul 2>&1
echo %packagedir% > "%tempdir%\packagedir.txt"

set "userdatadir=%installdir%\userdata"
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

if "%ARG_debug%" equ "1" echo "%juliadirname%"

ECHO () Download %juliaurl% to
ECHO () %tempdir%\%juliafname%

if "%ARG_debug%" equ "1" if exist "%tempdir%\%juliafname%" goto :nodownloadjulia
    call %func% DOWNLOAD-FILE "%juliaurl%" "%tempdir%\%juliafname%"
    if "%errorlevel%" NEQ "0" goto :EOF-DEAD "Error: could not download Julia from %juliaurl%"
:nodownloadjulia


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
call julia "%juliafile%" INSTALL-ATOM
call julia "%juliafile%" INSTALL-JUNO


echo () End of installation

:: ========== Clean up after ourselves ====
:removetmp
set /P c="Delete all downloads in %tmp%\juliawin [Y/N]? "
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
