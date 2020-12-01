@echo off
SETLOCAL EnableDelayedExpansion

:: ***************************************
:: With this script Juliawin can bootstrap itself from absolute nothing, but for all
:: this to work, we can unfortunately not use any external function or scripts yet.
::
:: Also, we have no control where this script will come from or the line-endings that the supplier will use.
:: Github is notorious for replacing windows line endings with uniz line endings. Batch is notorious for 
:: breaking gotos and labels when running with unix line endings. This makes writing this script really 
:: difficult to write. We may not use any goto! Goto considered harmfull for a whole different reason.
:: See https://serverfault.com/questions/429594
:: ***************************************


echo                _
echo    _       _ _(_)_     ^|  Documentation: https://docs.julialang.org
echo   (_)     ^| (_) (_)    ^|
echo    _ _   _^| ^|_  __ _   ^|  Run with "/h" for help
echo   ^| ^| ^| ^| ^| ^| ^|/ _` ^|  ^|
echo   ^| ^| ^|_^| ^| ^| ^| (_^| ^|  ^|  Unofficial installer for Juliawin
echo  _/ ^|\__'_^|_^|_^|\__'_^|  ^|
echo ^|__/                   ^|
echo:

if /i "%1" equ "/help" (
    echo Script to download and run the Juliawin installer directly from Github
    echo:
    echo Usage:
    echo   bootstrap-juliawin-from-github [options]
    echo Options:
    echo   /h, /help           Print these options
    echo   /dir ^<folder^>       Set installation directory
    echo   /force              Overwrite destination without prompting
    echo   /use-nightly-build  For developer previews and not intended for normal use
    exit /b 0
)

set "force=0"
if /i "%1" equ "/force" set "force=1"
if /i "%2" equ "/force" set "force=1"
if /i "%3" equ "/force" set "force=1"
if /i "%4" equ "/force" set "force=1"

set "use-nightly-build=0"
if /i "%1" equ "/use-nightly-build" set "use-nightly-build=1"
if /i "%2" equ "/use-nightly-build" set "use-nightly-build=1"
if /i "%3" equ "/use-nightly-build" set "use-nightly-build=1"
if /i "%4" equ "/use-nightly-build" set "use-nightly-build=1"

set "custom-directory=0"
set "install-directory=%userprofile%\Juliawin"
if /i "%1" equ "/dir" set "install-directory=%~2" & set "custom-directory=1"
if /i "%2" equ "/dir" set "install-directory=%~3" & set "custom-directory=1"
if /i "%3" equ "/dir" set "install-directory=%~4" & set "custom-directory=1"


:: ***************************************
:: Download the master zip directly from github
:: ***************************************
:: This is the most general legacy powershell download command. It should be available on any powershell
echo () Download juliawin from github to temp
set "juliawinzip=%temp%\juliawin-%random%%random%.zip"
call powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/heetbeet/juliawin/archive/main.zip', '%juliawinzip%')"


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
    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if /i "!defaultinstall!" neq "Y" if /i "!defaultinstall!" neq "N"  if /i "!defaultinstall!" neq "D" (
            set /P defaultinstall="Install to %install-directory% [Y/N/D]? "
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

if /i "%defaultinstall%" equ "D" (
    call cscript //nologo "%vbs%" > "%bat%"
    call "%bat%"
)
del "%vbs%" /f /q > nul 2>&1
del "%bat%" /f /q > nul 2>&1

if /i "%defaultinstall%" equ "D" (
    if "%__returnval__%" equ "" (
        echo ^(^) Invalid or no directory provided, please restart installer.
        pause
        exit /b -1
    ) else (
        set "install-directory=%__returnval__%"
    )
)


:: ***************************************
:: Copy to destination directory
:: ***************************************

:: Does the destination directory exist?
if "%force%" equ "0" (
    for /F %%i in ('dir /b /a "%install-directory%\*" 2^> nul') do (
        for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
            if /i "!overwrite!" neq "Y" if /i "!overwrite!" neq "N"  (
                set /P overwrite="Destination is not empty. Overwrite [Y/N]? "
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
:: Run the newly acquired local julia bootstrapper
:: ***************************************
set "args="
if "%force%" equ "1" set "args=/force"
if "%use-nightly-build%" equ "1" set "args=%args% /use-nightly-build"

call "%install-directory%\internals\scripts\bootstrap-juliawin-from-local-directory.bat" %args%