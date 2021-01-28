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

:: Set the url for the julia download
set "hompageurl=https://julialang.org/downloads"
if "%ARG_use-nightly-build%" equ "1" set "hompageurl=https://julialang.org/downloads/nightlies"

set "urlregex=https.*bin/winnt/x64/.*win64.zip"
if "%ARG_use-beta-build%" equ "1" set "urlregex=https.*bin/winnt/x64/.*beta.*win64.zip"

:: Get the url of the binary
call %functions% GET-DL-URL juliaurl "%hompageurl%" "%urlregex%"
if "%juliaurl%" EQU "" (
    echo Error: could not find Julia download link with regex %urlregex% from %hompageurl%
    exit /b -1
)

echo () Got Julia link as %juliaurl%

:: Download
call %functions% GET-URL-FILENAME juliazip "%juliaurl%"
set "juliazip=%ARG_TEMP%\%juliazip%"
call :TRY-DOWNLOAD-TEN-TIMES "%juliaurl%" "%juliazip%"

:: Extract
echo () Extracting %juliazip% into "%ARG_dest%"
call %functions% EXTRACT-ZIP-WINDOWS "%juliazip%" "%ARG_dest%"

:: Fix path
call %functions% EXPAND-ASTERIX nested "%ARG_dest%\julia*"
call %functions% FULL-PATH test1 "%ARG_dest%"
call %functions% FULL-PATH test2 "%nested%\.."
if "%test2%" equ "%test1%" (
    call :MOVE-DIRECTORY-HIGHER "%nested%" >nul
    call %functions% :DELETE-DIRECTORY "%nested%"
) else (
    echo Error Unexpected directory layout in Downloaded zip
    exit /b -1
)


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
    echo   /h, /help           Print these options
    echo   /use-nightly-build  For developer previews and not intended for normal use
    echo   /dest ^<folder^>      Portable Julia destination
    echo   /temp ^<folder^>      Optional: Path to download the julia exe to
    echo   /nocleanup          Optional: Don't delete the downloads in %%temp%%\julia-bootstrap-download-*
goto :eof


::***************************
:: Try ten times to download Julia
::***************************
:TRY-DOWNLOAD-TEN-TIMES <url> <dest>
    for /L %%a in (1,1,1,1,1,1,1,1,1,1) do (
        call %functions% DOWNLOAD-FILE "%~1" "%~2"
        if exist "%~2" goto :EOF

        REM wait two seconds
        ping 127.0.0.1 -n 2 > nul
    )
goto :eof

::***************************
:: Move from lower directory to upper directory
:: source https://superuser.com/a/1115241/396793
::***************************
:MOVE-DIRECTORY-HIGHER <src>
    set "MoveFromDir=%~1"
    set "MoveToDir=%~1\.."

    :: Move the folders from the move directory to the move to directory
    FOR /D %%A IN ("%MoveFromDir%\*") DO MOVE /Y "%%~A" "%MoveToDir%"

    :: Move any remaining files (or folders) from the move directory to the move to directory
    FOR /F "TOKENS=*" %%A IN ('DIR /S /B "%MoveFromDir%\*.*"') DO MOVE /Y "%%~A" "%MoveToDir%\"

goto :eof