@echo off
SETLOCAL EnableDelayedExpansion

:: Access to external functions
set functions="%~dp0functions.bat"

:: Parse the arguments
call %functions% ARG-PARSER %*

if "%ARG_h%%ARG_help%" NEQ "" (
    goto :PRINT-HELP
) else if "%ARG_dest%" EQU ""  (
    echo Error:
    echo   %~n0 %*
    goto :PRINT-HELP
)

:: Set the temp path for downloading the file
if "%ARG_temp%" EQU "" set "ARG_temp=%TEMP%\julia-bootstrap-download-%random%%random%"
mkdir "%ARG_temp%" >nul 2>&1


call %functions% GET-DL-URL juliaurl "https://julialang.org/downloads" "https.*bin/winnt/x64/.*win64.exe"
if "%juliaurl%" EQU "" (
    echo Error: could not find Julia download link from https://julialang.org/downloads
    exit /b -1
)

echo () Got Julia link as %juliaurl%

call %functions% GET-URL-FILENAME exedest "%juliaurl%"
set "exedest=%ARG_TEMP%\%exedest%"
call :TRY-DOWNLOAD-TEN-TIMES "%juliaurl%" "%exedest%"

echo () Extracting %exedest% into "%ARG_dest%"

if exist "%ARG_dest%" %functions% DELETE-DIRECTORY "%ARG_dest%"
call %functions% EXTRACT-INNO "%exedest%" "%ARG_dest%"


if "%ARG_nocleanup%" EQU "" (
    call %functions% DELETE-DIRECTORY "%ARG_temp%"
)

goto :eof

::***************************
:: Print the help menu
::***************************
:PRINT-HELP
    echo Script to automatically download and extract the latest Julia to a specified location.
    echo:
    echo Usage:
    echo   %~n0 [options]
    echo Options:
    echo   /h, /help          Print these options
    echo   /dest ^<folder^>     Portable Julia destination
    echo   /temp ^<folder^>     Optional: Path to download the julia exe to
    echo   /nocleanup         Optional: Don't delete the downloads in %%temp%%\julia-bootstrap-download-*
goto :eof


::***************************
:: Try ten times to download Julia
::***************************
:TRY-DOWNLOAD-TEN-TIMES <url> <dest>
    for /L %%a in (1,1,1,1,1,1,1,1,1,1) do (
        call %functions% DOWNLOAD-FILE "%~1" "%~2"
        if exist "%~2" goto :EOF
    )
goto :eof