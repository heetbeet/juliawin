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

set do-questions=0
if /i "%1" neq "/skip-questions" if /i "%2" neq "/skip-questions" if /i "%3" neq "/skip-questions" if /i "%4" neq "/skip-questions" if /i "%5" neq "/skip-questions"  set "do-questions=1"

if "%do-questions%" equ "1" (
    echo  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^_^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
    echo  ^ ^ ^ ^ ^_^ ^ ^ ^ ^ ^ ^ ^_^ ^_^(^_^)^_^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^_^ ^ ^ ^ ^ ^ ^ ^ ^|^ ^J^u^l^i^a^w^i^n^ ^c^o^m^m^a^n^d^l^i^n^e^ ^i^n^s^t^a^l^l^e^r
    echo  ^ ^ ^ ^|^ ^|^ ^ ^ ^ ^ ^|^ ^(^_^)^ ^(^_^)^ ^ ^ ^ ^ ^ ^ ^ ^ ^(^_^)^ ^ ^ ^ ^ ^ ^ ^|^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
    echo  ^ ^ ^ ^|^ ^|^_^ ^ ^ ^_^|^ ^|^_^ ^ ^_^_^ ^_^ ^_^_^ ^ ^ ^_^_^ ^_^ ^_^ ^_^_^ ^ ^ ^|^ ^G^i^t^H^u^b^.^c^o^m^/^h^e^e^t^b^e^e^t^/^j^u^l^i^a^w^i^n^ ^ 
    echo  ^ ^ ^ ^|^ ^|^ ^|^ ^|^ ^|^ ^|^ ^|^/^ ^_^`^ ^|^'^/^ ^_^ ^\^'^|^ ^|^ ^'^_^ ^\^ ^ ^|^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
    echo  ^ ^_^_^/^ ^|^ ^|^_^|^ ^|^ ^|^ ^|^ ^(^_^|^ ^|^ ^\^/^ ^\^/^ ^|^ ^|^ ^|^ ^|^ ^|^ ^|^ ^R^u^n^ ^w^i^t^h^ ^"^/^h^"^ ^f^o^r^ ^h^e^l^p^ ^ ^ ^ ^ ^ ^ ^ 
    echo  ^|^_^_^_^/^ ^\^_^_^'^_^|^_^|^_^|^\^_^_^'^_^|^\^_^_^/^\^_^/^|^_^|^_^|^ ^|^_^|^ ^|^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
    echo:

    if /i "%1" equ "/help" set "dohelp=1"
    if /i "%1" equ "/h" set "dohelp=1"
    if "!dohelp!" equ "1" (
        echo Script to download and run the Juliawin installer directly from Github
        echo:
        echo Usage:
        echo   "bootstrapped-juliawin-installer.cmd" [options]
        echo Options:
        echo   /h, /help           Print these options
        echo   /dir ^<folder^>       Set installation directory
        echo   /force              Overwrite destination without prompting
        exit /b 0
    )


    ::This doesn't scale well
    set "force=0"
    if /i "%1" equ "/force" set "force=1"
    if /i "%2" equ "/force" set "force=1"
    if /i "%3" equ "/force" set "force=1"
    if /i "%4" equ "/force" set "force=1"
    if /i "%5" equ "/force" set "force=1"


    set "custom-directory=0"
    set "install-directory=!userprofile!\Juliawin"
    if /i "%1" equ "/dir" set "install-directory=%~2" & set "custom-directory=1"
    if /i "%2" equ "/dir" set "install-directory=%~3" & set "custom-directory=1"
    if /i "%3" equ "/dir" set "install-directory=%~4" & set "custom-directory=1"
    if /i "%4" equ "/dir" set "install-directory=%~5" & set "custom-directory=1"


    :: ***************************************
    :: Ask questions about what to install
    :: ***************************************
    set "answer=R"
    for %%r in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
        if /i "!answer!" equ "R" (
            set "answer="
            for %%x in (VSCode Juno Pluto PyCall Jupyter) do (
                if /i "!answer!" neq "R" (
                    set "answer="
                    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
                        if /i "!answer!" neq "Y"  if /i "!answer!" neq "N" if /i "!answer!" neq "R" (
                            echo Install %%x...
                            set /P answer="Yes, No, Reset questions [Y/N/R]? " || set answer=xxxx
                        )
                    )
                    echo:
                    if /i "!answer!" equ "y" set "juliawin_install_%%x=1"
                    if /i "!answer!" equ "n" set "juliawin_install_%%x=0"
                )
            )
        )
    )
)

set "juliawinzip=!temp!\juliawin-!random!!random!.zip"
set "vbs=!temp!\_!random!!random!.vbs"
set "bat=!vbs!.bat"
set "juliawintemp=!temp!\juliawin-!random!!random!"


:: ***************************************
:: Test to see if this script is already in it's sourrounding environment
:: ***************************************
if exist "%~dp0\bootstrapped-julia.cmd" if exist "%~dp0\..\bin\julia" (
    set "dontdownload=1"
    set "install-directory=%~dp0.."
)


:: ***************************************
:: Oterwise, bootstrap this scripts environment from the official Github website
:: ***************************************
if "%dontdownload%" neq "1" (

    REM ***************************************
    REM Set destination directory
    REM ***************************************

    REM Wow, this is so difficult without a goto...
    echo:
    echo   [Y]es: choose the default installation directory
    echo   [N]o: cancel the installation
    echo   [D]irectory: choose my own directory
    echo:
    if "!force!" equ "0" if "!custom-directory!" equ "0" (
        for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
            if /i "!defaultinstall!" neq "Y" if /i "!defaultinstall!" neq "N"  if /i "!defaultinstall!" neq "D" (
                set /P defaultinstall="Install to !install-directory! [Y/N/D]? " || set defaultinstall=xxxxxx
            )
        )
    )
    if /i "!defaultinstall!" EQU "N" exit /b -1

    > "!vbs!" echo set shell=WScript.CreateObject^("Shell.Application"^)
    >>"!vbs!" echo set f=shell.BrowseForFolder^(0,"Select Juliwin install directory",0,""^)
    >>"!vbs!" echo if typename^(f^)="Nothing" Then
    >>"!vbs!" echo    wscript.echo "set __returnval__="
    >>"!vbs!" echo    WScript.Quit^(1^)
    >>"!vbs!" echo end if
    >>"!vbs!" echo set fs=f.Items^(^):set fi=fs.Item^(^)
    >>"!vbs!" echo p=fi.Path:wscript.echo "set __returnval__=" ^& p


    set "__returnval__="
    if /i "!defaultinstall!" equ "D" (
        for %%a in (0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
            if "!__returnval__!" equ "" (
                if "%%a" equ "1" echo ^(^) Error selecting directory, please try again.
                call cscript //nologo "!vbs!" > "!bat!"
                call "!bat!"
            )
        )
        set "install-directory=!__returnval__!"
    )

    del "!vbs!" /f /q > nul 2>&1
    del "!bat!" /f /q > nul 2>&1


    REM ***************************************
    REM Copy to destination directory
    REM ***************************************

    REM Does the destination directory exist?
    if "!force!" equ "0" (
        for /F %%i in ('dir /b /a "!install-directory!\*" 2^> nul') do (
            for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
                if /i "!overwrite!" neq "Y" if /i "!overwrite!" neq "N"  (
                    set /P overwrite="Destination is not empty. Overwrite [Y/N]? " || set overwrite=xxxxxx
                )
            )
        )
    )
    if /i "!overwrite!" equ "N" (
        echo ^(^) Installation cancelled
        pause
        exit /b -1
    )


    REM ***************************************
    REM This is the most general legacy powershell download command. It should be available on any powershell
    REM ***************************************

    echo ^(^) Download Juliawin installer from GitHub.com into temp
    call powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/heetbeet/juliawin/archive/main.zip', '!juliawinzip!')"

    if not exist "!juliawinzip!" (
        echo Download from github.com/heetbeet/juliawin failed
        exit /b -1
    )


    REM ***************************************
    REM Unzip the master zip into a temporary directory
    REM ***************************************
    REM https://stackoverflow.com/questions/21704041/creating-batch-script-to-unzip-a-file-without-additional-zip-tools
    echo ^(^) Unzip juliawin
    mkdir "!juliawintemp!" 2>NUL

    set "vbs=!temp!\_!random!!random!.vbs"

    set vbs_quoted="!vbs!"
    > "!vbs!"  echo set objShell = CreateObject^("Shell.Application"^)
    >>"!vbs!"  echo set FilesInZip=objShell.NameSpace^("!juliawinzip!"^).items
    >>"!vbs!"  echo objShell.NameSpace^("!juliawintemp!"^).CopyHere^(FilesInZip^)

    cscript //nologo "!vbs!"
    del "!vbs!" /f /q > nul 2>&1


    REM ***************************************
    REM Move to final location
    REM ***************************************
    del "!install-directory!" /f /q /s > nul 2>&1
    robocopy "!juliawintemp!\juliawin-main" "!install-directory!" /s /e /mov > nul 2>&1
    del "!juliawinzip!" /f /q > nul 2>&1

)


:: ***************************************
:: Run this installer again, but without bootstrapping this time
:: ***************************************
if "%do-questions%" equ "1" (
    call "%install-directory%\scripts\bootstrapped-juliawin-installer.cmd" /skip-questions
    exit /b !errorlevel!
)


if "!force!" equ "1" (
    set "forceinstall=O"
) else (
    set "forceinstall="
    if exist "%install-directory%\vendor\julia\bin\julia.exe" (
        for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
            if /i "!forceinstall!" neq "O"  if /i "!forceinstall!" neq "K" if /i "!forceinstall!" neq "C" (
                set /P forceinstall="Julia installation in packages\julia already exist. Overwrite, Keep or cancel [O/K/C]? " || set forceinstall=xxxx
            )
            if /i "!forceinstall!" equ "C" (
                exit /b -1
            )
        )
    )
)

:: In the case where we want to clear the old Julia (forced overwrite)
if /i "!forceinstall!" EQU "O" (
    call "%~dp0\bootstrapped-sh.cmd" -c "rm -rf '%install-directory%\vendor\julia'"
)


:: Finally, run the actual Julia version of this code
call "%~dp0\bootstrapped-julia.cmd" "%~dp0\juliawin_installer.jl" --install-dialog