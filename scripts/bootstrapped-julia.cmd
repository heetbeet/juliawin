:: **********************************************************
:: Forcefully download julia to vendor/julia and run the command
:: under the newly aquired sh.exe
:: **********************************************************

@echo off
SETLOCAL EnableDelayedExpansion

set "JULIA_DEPOT_PATH=..\userdata\.julia"
set "juliapath=%~dp0..\vendor\julia"
set "juliazipname=juliainstall.zip"
set "juliatmp=%~dp0..\vendor\%juliazipname%"

mkdir "%~dp0..\vendor" 2>NUL
mkdir "%JULIA_DEPOT_PATH%" 2>NUL

if exist "%juliatmp%" (
    del "%juliatmp%" 2>nul
)

if exist "%juliatmp%_tmp" (
    del "%juliatmp%_tmp" 2>nul
)

:: Can we immediately use sh?
if exist "%juliapath%\bin\julia.exe" (
    call "%juliapath%\bin\julia.exe" %*
    exit /b !errorlevel!
)


echo () Julia not installed, bootstrapping from Julialang.org

:: Or do we need to download it first?
set "hompageurl=https://julialang.org/downloads"
set "urlregex=https.*bin/winnt/x64/.*win64.zip"

set "htmlfile=%temp%\juliahtmlfile%random%%random%.html"
for /L %%a in (1,1,1,1,1,1,1,1,1,1) do (
    if not exist "%htmlfile%" (
        call "%~dp0\bootstrapped-sh" -c "curl -g -L -f -o '%htmlfile%' '%hompageurl%'" >nul
    )
    if not exist "%htmlfile%" (
        REM wait one seconds
        ping 127.0.0.1 -n 2 > nul
    )
)
call powershell -Command "(gc '%htmlfile%') -replace '""', [System.Environment]::Newline  | Out-File '%htmlfile%--split' -encoding utf8"

set "downloadurl="
FOR /F "tokens=* USEBACKQ" %%I IN (`findstr /i /r /c:"%urlregex%" "%htmlfile%--split"`) do (
    if "!downloadurl!" equ "" (
        set "downloadurl=%%I"
    )
)

echo () Download link: %downloadurl%

:: Try downloading julia ten times
for /L %%a in (1,1,1,1,1,1,1,1,1,1) do (
    if not exist "%juliatmp%_tmp" (
        call "%~dp0\bootstrapped-sh" -c "curl -g -L -f -o '%juliatmp%_tmp' '%downloadurl%'"
    )
    if not exist "%juliatmp%_tmp" (
        REM wait one seconds
        ping 127.0.0.1 -n 2 > nul
    )
)

ren "%juliatmp%_tmp" "%juliazipname%" 2>nul

call "%~dp0\bootstrapped-sh" -c "unzip -q -d '%juliapath%' '%juliatmp%'"

pushd "%juliapath%\julia-*"
    call "%~dp0\bootstrapped-sh" -c "mv * .."
popd

if exist "%juliatmp%_tmp" (
    del "%juliatmp%_tmp" 2>nul
)

if exist "%juliatmp%" (
    del "%juliatmp%" 2>nul
)

call "%juliapath%\bin\julia.exe" %*
exit /b %errorlevel%
