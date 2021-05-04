:: **********************************************************
:: Forcefully download Git Bash to vendor/git and run the command 
:: under this newly aquired sh.exe environment
:: **********************************************************

@echo off
SETLOCAL EnableDelayedExpansion

set "gitpath=%~dp0..\vendor\git"
set "gitexename=gitinstall.exe"
set "gittmp=%~dp0..\vendor\%gitexename%"
mkdir "%~dp0..\vendor" 2>NUL

if exist "%gittmp%" (
    del "%gittmp%" 2>nul
)

if exist "%gittmp%_tmp" (
    del "%gittmp%_tmp" 2>nul
)

:: Can we immediately use sh?
call "%gitpath%\bin\sh.exe" -c ":" >nul 2>&1
if "%errorlevel%" equ "0" (
    call "%gitpath%\bin\sh.exe" %*
    exit /b !errorlevel!
)


echo () Git Bash not installed, bootstrapping from GitHub

:: Or do we need to download it first?
set "hompageurl=https://github.com/git-for-windows/git/releases"
set "urlregex=/download/.*PortableGit.*64-bit.7z.exe"

set "htmlfile=%temp%\githtmlfile%random%%random%.html"
call powershell -Command "(New-Object Net.WebClient).DownloadFile('%hompageurl%', '%htmlfile%')"
call powershell -Command "(gc '%htmlfile%') -replace '""', [System.Environment]::Newline  | Out-File '%htmlfile%--split' -encoding utf8"

set "downloadurl="
FOR /F "tokens=* USEBACKQ" %%I IN (`findstr /i /r /c:"%urlregex%" "%htmlfile%--split"`) do (
    if "!downloadurl!" equ "" (
        set "downloadurl=https://github.com/%%I"
    )
)

echo () Download link: %downloadurl%

set downloadmethod=webclient
call powershell -Command "gcm Invoke-WebRequest" >nul 2>&1
if "%errorlevel%" EQU "0" set downloadmethod=webrequest

:: Try downloading git ten times
for /L %%a in (1,1,1,1,1,1,1,1,1,1) do (
    if not exist "%gittmp%_tmp" (
        if "%downloadmethod%" equ "webclient" (
            call powershell -Command "(New-Object Net.WebClient).DownloadFile('%downloadurl%', '%gittmp%_tmp')"
        ) else (
            call powershell -Command "Invoke-WebRequest '%downloadurl%' -OutFile '%gittmp%_tmp'"
        )
    )
    if not exist "%gittmp%_tmp" (
        REM wait one seconds
        ping 127.0.0.1 -n 2 > nul
    )
)

ren "%gittmp%_tmp" "%gitexename%" 2>nul

call "%gittmp%" -o"%gitpath%" -y

if exist "%gittmp%_tmp" (
    del "%gittmp%_tmp" 2>nul
)

if exist "%gittmp%" (
    del "%gittmp%" 2>nul
)

call "%gitpath%\bin\sh.exe" %*
exit /b %errorlevel%
