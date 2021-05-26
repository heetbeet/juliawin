@echo off
SETLOCAL EnableDelayedExpansion

:: ***************************************
:: With this script Juliawin can bootstrap itself from absolute nothing, but for all
:: this to work, we can unfortunately not use any external function or scripts yet.
::
:: Also, we have no control where this script will come from or the line-endings that the supplier will use.
:: Github is notorious for replacing windows line endings with unix line endings. Batch is notorious for
:: breaking gotos and labels when running with unix line endings. This made this script really
:: difficult to write, since we may not use any goto! Goto considered harmful for a whole different reason.
:: See https://serverfault.com/questions/429594
:: ***************************************


echo                 _
echo     _       _ _(_)_           _        ^| Juliawin commandline installer
echo    ^| ^|     ^| (_) (_)         (_)       ^|
echo    ^| ^|_   _^| ^|_  __ _ __   __ _ _ __   ^| GitHub.com/heetbeet/juliawin
echo    ^| ^| ^| ^| ^| ^| ^|/ _` ^|'/ _ \'^| ^| '_ \  ^|
echo  __/ ^| ^|_^| ^| ^| ^| (_^| ^| \/ \/ ^| ^| ^| ^| ^| ^| Run with "/h" for help
echo ^|___/ \__'_^|_^|_^|\__'_^|\__/\_/^|_^|_^| ^|_^| ^|
echo:


if /i "%1" equ "/help" set "dohelp=1"
if /i "%1" equ "/h" set "dohelp=1"
if "%dohelp%" equ "1" (
    echo Script to download and run the Juliawin installer directly from Github
    echo:
    echo Usage:
    echo   bootstrap-juliawin-from-github [options]
    echo Options:
    echo   /h, /help           Print these options
    echo   /dir ^<folder^>       Set installation directory
    echo   /force              Overwrite destination without prompting
    echo   /use-nightly-build  Latest preview build, not intended for normal use
    echo   /use-beta-build     Latest beta, possibly unstable 
    exit /b 0
)


::This doesn't scale well
set "force=0"
if /i "%1" equ "/force" set "force=1"
if /i "%2" equ "/force" set "force=1"
if /i "%3" equ "/force" set "force=1"
if /i "%4" equ "/force" set "force=1"
if /i "%5" equ "/force" set "force=1"

set "use-nightly-build=0"
if /i "%1" equ "/use-nightly-build" set "use-nightly-build=1"
if /i "%2" equ "/use-nightly-build" set "use-nightly-build=1"
if /i "%3" equ "/use-nightly-build" set "use-nightly-build=1"
if /i "%4" equ "/use-nightly-build" set "use-nightly-build=1"
if /i "%5" equ "/use-nightly-build" set "use-nightly-build=1"


set "use-beta-build=0"
if /i "%1" equ "/use-beta-build" set "use-beta-build=1"
if /i "%2" equ "/use-beta-build" set "use-beta-build=1"
if /i "%3" equ "/use-beta-build" set "use-beta-build=1"
if /i "%4" equ "/use-beta-build" set "use-beta-build=1"
if /i "%5" equ "/use-beta-build" set "use-beta-build=1"


set "custom-directory=0"
set "install-directory=%userprofile%\Juliawin"
if /i "%1" equ "/dir" set "install-directory=%~2" & set "custom-directory=1"
if /i "%2" equ "/dir" set "install-directory=%~3" & set "custom-directory=1"
if /i "%3" equ "/dir" set "install-directory=%~4" & set "custom-directory=1"
if /i "%4" equ "/dir" set "install-directory=%~5" & set "custom-directory=1"


:: ***************************************
:: Download the master zip directly from github
:: ***************************************
:: This is the most general legacy powershell download command. It should be available on any powershell
echo () Download Juliawin installer from GitHub.com into temp
set "juliawinzip=%temp%\juliawin-%random%%random%.zip"
call powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/heetbeet/juliawin/archive/main.zip', '%juliawinzip%')"

if not exist "%juliawinzip%" (
    echo Download from github.com/heetbeet/juliawin failed
    exit /b -1
)

:: ***************************************
:: Unzip the master zip into a temporary directory
:: ***************************************
:: https://stackoverflow.com/questions/21704041/creating-batch-script-to-unzip-a-file-without-additional-zip-tools
echo () Unzip juliawin to temp
set "juliawintemp=%temp%\juliawin-%random%%random%"
mkdir "%juliawintemp%" 2>NUL

set "vbs=%temp%\_%random%%random%.vbs"

set vbs_quoted="%vbs%"
> "%vbs%"  echo set objShell = CreateObject("Shell.Application")
>>"%vbs%"  echo set FilesInZip=objShell.NameSpace("%juliawinzip%").items
>>"%vbs%"  echo objShell.NameSpace("%juliawintemp%").CopyHere(FilesInZip)

cscript //nologo "%vbs%"
del "%vbs%" /f /q > nul 2>&1


:: ***************************************
:: Set destination directory
:: ***************************************
set "vbs=%temp%\_%random%%random%.vbs"
set "bat=%vbs%.bat"

:: Wow, this is so difficult without a goto...
echo:
echo   [Y]es: choose the default installation directory
echo   [N]o: cancel the installation
echo   [D]irectory: choose my own directory
echo:
if "%force%" equ "0" if "%custom-directory%" equ "0" (
    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if /i "!defaultinstall!" neq "Y" if /i "!defaultinstall!" neq "N"  if /i "!defaultinstall!" neq "D" (
            set /P defaultinstall="Install to %install-directory% [Y/N/D]? " || set defaultinstall=xxxxxx
        )
    )
)
if /i "%defaultinstall%" EQU "N" exit /b -1

> "%vbs%" echo set shell=WScript.CreateObject("Shell.Application")
>>"%vbs%" echo set f=shell.BrowseForFolder(0,"Select Juliwin install directory",0,"")
>>"%vbs%" echo if typename(f)="Nothing" Then
>>"%vbs%" echo    wscript.echo "set __returnval__="
>>"%vbs%" echo    WScript.Quit(1)
>>"%vbs%" echo end if
>>"%vbs%" echo set fs=f.Items():set fi=fs.Item()
>>"%vbs%" echo p=fi.Path:wscript.echo "set __returnval__=" ^& p

set "__returnval__="
if /i "%defaultinstall%" equ "D" (
    for %%a in (0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if "!__returnval__!" equ "" (
            if "%%a" equ "1" echo ^(^) Error selecting directory, please try again.
            call cscript //nologo "%vbs%" > "%bat%"
            call "%bat%"
        )
    )
    set "install-directory=!__returnval__!"
)

del "%vbs%" /f /q > nul 2>&1
del "%bat%" /f /q > nul 2>&1


:: ***************************************
:: Copy to destination directory
:: ***************************************

:: Does the destination directory exist?
if "%force%" equ "0" (
    for /F %%i in ('dir /b /a "%install-directory%\*" 2^> nul') do (
        for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
            if /i "!overwrite!" neq "Y" if /i "!overwrite!" neq "N"  (
                set /P overwrite="Destination is not empty. Overwrite [Y/N]? " || set overwrite=xxxxxx
            )
        )
    )
)
if /i "%overwrite%" equ "N" (
    echo ^(^) Installation cancelled
    pause
    exit /b -1
)

del "%install-directory%\packages\julia" /f /q /s > nul 2>&1
robocopy "%juliawintemp%\juliawin-main" "%install-directory%" /s /e /mov > nul 2>&1
del "%juliawinzip%" /f /q > nul 2>&1


:: ***************************************
:: Run the newly downloaded local julia bootstrapper
:: ***************************************
set "args="
if "%force%" equ "1" set "args=/force"
if "%use-nightly-build%" equ "1" set "args=%args% /use-nightly-build"
if "%use-beta-build%" equ "1" set "args=%args% /use-beta-build

call "%install-directory%\internals\scripts\bootstrap-juliawin-from-local-directory.bat" %args%
