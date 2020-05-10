@echo off
SETLOCAL EnableDelayedExpansion
:: =====================================================
:: This is an automatic install script for Julia
:: First half of the script is written in batch
:: Second half of the script is written in Julia
::
:: The batch part makes sure the environment is set up
:: correctly and that Julia is available, while the
:: heavy lifting is done in Julia itself.
:: =====================================================


:: =====================================================
::    This is the .bat part of the file
::
::     =/\                 /\=
::     / \'._   (\_/)   _.'/ \
::    / .''._'--(o.o)--'_.''. \
::   /.' _/ |`'=/ " \='`| \_ `.\
::  /` .' `\;-,'\___/',-;/` '. '\
:: /.-'       `\(-V-)/`       `-.\
:: `            "   "            `
:: =====================================================

:: For dev-purposes, reset path to minimal OS programs
set "PATH=%systemroot%;%systemroot%\System32;%systemroot%\System32\WindowsPowerShell\v1.0"

call :ARG-PARSER %*

:: Set current file locations (deploy changes all extentions to .bat)
set "thisfile=%~dp0%~n0.bat"
set "juliafile=%~dp0%~n0.jl"
set "pythonfile=%~dp0%~n0.py"


:: ========== Run from explorer.exe? =======
:: We want double-clickers to have a paused window
:: at the end. This is very delicate with many gotcha's
:: and scoping stuff that don't fully understand. The
:: strange "%~dp0%~n0" call is to avoid a inf loop.

:: https://stackoverflow.com/a/61511609/1490584
set "dclickcmdx=%systemroot%\system32\cmd.exe /c xx%~0x x"
set "actualcmdx=%cmdcmdline:"=x%"

:: If double-clicked or /P,  restart with a pause guard
if /I "%dclickcmdx%" EQU "%actualcmdx%" goto restartwithpause
IF "%ARG_P%" EQU "1" goto restartwithpause
goto :exitrestartwithpause
:restartwithpause

    set "ARG_P="
    call "%~dp0%~n0"
    echo:
    pause
    exit /b %errorlevel%

:exitrestartwithpause


:: ========== Help Menu ===================
CALL :SHOW-JULIA-ASCII

if "%ARG_H%" EQU "1" goto help
if "%ARG_HELP%" EQU "1" goto help
goto exithelp

:help
ECHO The setup program accepts one command line parameter.
Echo:
ECHO /HELP, /H
ECHO   Show this information and exit.
ECHO /P
ECHO   Pause before exit. (Default behaviour for Explorer .bat double-click.)
ECHO /Y
ECHO   Yes to all
ECHO /DIR "x:\Dirname"
ECHO   Overwrite the default with custom directory.
ECHO /RMDIR
ECHO   Clear the install directory (if not empty)
goto :EOF-ALIVE
:exithelp


:: ========== Setup Environment ============
set "tempdir=%temp%\juliawin"
mkdir "%tempdir%" 2>NUL

set "toolsdir=%tempdir%\tools"
mkdir "%toolsdir%" 2>NUL
SET "PATH=%toolsdir%;%PATH%"

set "installdir=%userprofile%\Juliawin"

echo %thisfile% > "%tempdir%\thisfile.txt"

:: ========== Custom path provided =========
IF /I "%ARG_DIR%" NEQ "" (
    set "installdir=%ARG_DIR%"
    goto exitchoice
)

:: ========== Choose Install Dir ===========
if "%ARG_Y%" EQU "1" goto exitchoice
:choice
Echo:
Echo   [Y]es: continue
Echo   [N]o: cancel the operation
Echo   [D]irectory: choose my own directory
Echo:
set /P c="Install Julia in %installdir% [Y/N/D]?"
if /I "%c%" EQU "Y" goto :exitchoice
if /I "%c%" EQU "N" goto :EOF-DEAD
if /I "%c%" EQU "D" goto :selectdir
goto :choice
:selectdir

call :BROWSE-FOR-FOLDER installdir
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


:: ========== Remove nonempty install dir ==
if "%ARG_RMDIR%" EQU 1 (
    rmdir  /s /q "%installdir%"
)


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
::Delete dir and make it again (if we can, it is/was an empty dir)
rmdir "%installdir%" >nul 2>&1
mkdir "%installdir%" >nul 2>&1
if "%errorlevel%" EQU "0" goto :directoryisgood
    :: directory is not good...
    :diremptychoice
    set /P c="Directroy is not empty, continue [Y/N]?"
    if /I "%c%" NEQ "Y" if /I "%c%" NEQ "N" goto diremptychoice
    if /I "%c%" EQU "Y" goto :directoryisgood

    ECHO: 1>&2
    ECHO Error, the install directory is not empty. 1>&2
    ECHO:
    ECHO You can run the remove command and try again: 1>&2
    ECHO ^>^> rmdir /s "%installdir%" 1>&2
    goto :EOF-DEAD

:directoryisgood
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

call :BOOTSTRAP-CURL
call :SET-PATHS

call :GET-DL-URL juliaurl "https://julialang.org/downloads" "https.*bin/winnt/x64/.*win64.exe"
if %errorlevel% NEQ 0 goto :EOF-DEAD

call :GET-URL-FILENAME juliafname "%juliaurl%"
call :FILE-NOEXT juliadirname "%juliafname%"

ECHO () Download %juliaurl% to
ECHO () %tempdir%\%juliafname%

if exist "%tempdir%\%juliafname%" goto :nodownloadjulia
    call :DOWNLOAD-FILE "%juliaurl%" "%tempdir%\%juliafname%"
    if %errorlevel% NEQ 0 goto :EOF-DEAD
:nodownloadjulia

ECHO () Extracting into %packagedir%\%juliadirname%
call "%tempdir%\%juliafname%" /SP- /VERYSILENT /DIR="%packagedir%\%juliadirname%"
call :SET-PATHS

:: ========== Run Julia code scripts ======
call julia --color=yes -e "Base.banner()"
pause
call julia "%juliafile%" ADD-STARTUP-SCRIPT
call julia "%juliafile%" INSTALL-CURL
call julia "%juliafile%" INSTALL-NSIS
call julia "%juliafile%" INSTALL-RESOURCEHACKER
call julia "%juliafile%" MAKE-BATS

call julia "%juliafile%" INSTALL-ATOM
call :SET-PATHS

call julia "%juliafile%" INSTALL-JUNO
call :SET-PATHS

call julia "%juliafile%" INSTALL-JUPYTER
call :SET-PATHS

call julia "%juliafile%" MAKE-BATS

echo () End of installation

:: ================================================
::    This is where we store the .bat subroutines
::
::     =/\                 /\=
::     / \'._   (\_/)   _.'/ \
::    / .''._'--(o.o)--'_.''. \
::   /.' _/ |`'=/ " \='`| \_ `.\
::  /` .' `\;-,'\___/',-;/` '. '\
:: /.-'       `\(-V-)/`       `-.\
:: `            "   "            `
:: ================================================
goto :EOF

::*********************************************************
:: Parse commandline arguments into sane variables
:: See the following scenario as usage example:
:: >> thisfile.bat /a /b "c:\" /c /foo 5
:: >> CALL :ARG-PARSER %*
:: ARG_a=1
:: ARG_b=c:\
:: ARG_c=1
:: ARG_foo=5
::*********************************************************
:ARG-PARSER <pass %*>
    ::Loop until two consecutive empty args
    :loopargs
        IF "%~1%~2" EQU "" GOTO :EOF

        set "arg1=%~1" 
        set "arg2=%~2"
        shift

        ::Get first character of arg1 as "/" or "-"
        set "tst1=%arg1%" 
        set "tst1=%tst1:-=/%"
        if "%arg1%" NEQ "" (
            set "tst1=%tst1:~0,1%"
        ) ELSE (
            set "tst1="
        )

        ::Get first character of arg2 as "/" or "-"
        set "tst2=%arg2%"
        set "tst2=%tst2:-=/%"
        if "%arg2%" NEQ "" (
            set "tst2=%tst2:~0,1%"
        ) ELSE (
            set "tst2="
        )

        ::Capture assignments (eg. /foo bar)
        IF "%tst1%" EQU "/"  IF "%tst2%" NEQ "/" IF "%tst2%" NEQ "" (
            set "ARG_%arg1:~1%=%arg2%"
            GOTO loopargs
        )

        ::Capture flags (eg. /foo)
        IF "%tst1%" EQU "/" (
            set "ARG_%arg1:~1%=1"
            GOTO loopargs
        )
    goto loopargs
GOTO :EOF


:: ***********************************************
:: Set PATH variables (rerun when more packages are available)
:: ***********************************************
:SET-PATHS
    call :ADD-TO-PATH "%toolsdir%"
    call :ADD-TO-PATH "%packagedir%\julia-*" "bin"
    call :ADD-TO-PATH "%packagedir%\julia-*" "libexec"
    call :ADD-TO-PATH "%packagedir%\atom-*"
    call :ADD-TO-PATH "%packagedir%\atom-*" "resources\cli"
    call :ADD-TO-PATH "%packagedir%\curl*"  "bin"
    call :ADD-TO-PATH "%packagedir%\nsis*"  "bin"
    call :ADD-TO-PATH "%packagedir%\resource_hacker*" "bin"

    set "JULIA_DEPOT_PATH=%userdatadir%\.julia"
    set "ATOM_HOME=%userdatadir%\.atom"
goto :EOF


:: ***********************************************
:: Expand a asterix path to a full path
:: ***********************************************
:EXPAND-FULLPATH <return> <filepath>
    ::basename with asterix expansion
    set "_basename_="
    for /f "tokens=*" %%F in ('dir /b "%~2" 2^> nul') do set "_basename_=%%F"

    ::concatenate with dirname is basename found (else "")
    if "%_basename_%" NEQ "" (
        set "%~1=%~dp2%_basename_%"
    ) ELSE (
        set "%~1="
    )
goto :EOF


:: ***********************************************
:: Expand a asterix path to a full path
:: ***********************************************
:ADD-TO-PATH <asterixable path> <optional\extra\path\>
    :: first part may be extended with an asterix
    call :EXPAND-FULLPATH _path_ "%~1"
    if "%_path_%" EQU "" goto :EOF

    :: second part may be empty 
    if "%~2" NEQ "" set "_path_=%_path_%\%~2"

    echo %_path_%; | findstr /i /c:"%PATH%" >nul 2>&1
    if "%errorlevel%" EQU "0" goto :EOF

    set "PATH=%_path_%;%PATH%"
goto :EOF


:: ***********************************************
:: Find Download method
:: ***********************************************
:REGISTER-DOWNLOAD-METHOD

    call curl --help >nul 2>&1
    set downloadmethod=curl
    if %errorlevel% EQU 0 goto :method-success

    call powershell -Command "gcm Invoke-WebRequest" >nul 2>&1
    set downloadmethod=webrequest
    if %errorlevel% EQU 0 goto :method-success

    call wget --help >nul 2>&1
    set downloadmethod=wget
    if %errorlevel% EQU 0 goto :method-success

    call powershell -Command "(New-Object Net.WebClient)" >nul 2>&1
    set downloadmethod=webclient
    if %errorlevel% EQU 0 goto :method-success

    SET downloadmethod=

    :: We can't find any download method
    ECHO: 1>&2
    ECHO Can't find any of these file download utilities: 1>&2
    ECHO   - PowerShell's Invoke-WebRequest  1>&2
    ECHO   - PowerShell's Net.WebClients  1>&2
    ECHO   - wget  1>&2
    ECHO   - curl  1>&2
    ECHO: 1>&2
    ECHO Install any of the above and try again... 1>&2
    GOTO :EOF-DEAD

    :method-success
    echo () Download method %downloadmethod% is available

goto :EOF


:: ***********************************************
:: Download a file
:: ***********************************************
:DOWNLOAD-FILE <url> <filelocation>
    call :REGISTER-DOWNLOAD-METHOD
    if %errorlevel% EQU 1 goto :EOF-DEAD

    IF "%downloadmethod%" == "curl" (

        call curl -g -L -f -o "%~2" "%~1"
        if %errorlevel% NEQ 0 goto EOF-DEAD

    ) ELSE IF "%downloadmethod%" == "webrequest" (

        call powershell -Command "Invoke-WebRequest '%~1' -OutFile '%~2'"
        if %errorlevel% NEQ 0 goto EOF-DEAD

    ) ELSE IF "%downloadmethod%" == "wget" (

        call wget "%1" -O "%2"
        if %errorlevel% NEQ 0 goto EOF-DEAD

    ) ELSE IF "%downloadmethod%" == "webclient" (
    
        call powershell -Command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2')"
        if %errorlevel% NEQ 0 goto EOF-DEAD
    )

goto :EOF


:: ***********************************************
:: Make sure a fairly new CURL is available for this
:: Julia installation, and force julia to use curl.
:: ***********************************************
:BOOTSTRAP-CURL
    ::If we don't have curl, then download it from github
    call %SYSTEMROOT%\System32\curl.exe --help >nul 2>&1
    if %errorlevel% EQU 0 goto :_skipcurldownload_
        :: copy curl and place in tools and (temporarily) in Juliawin
        call :DOWNLOAD-FILE "https://raw.githubusercontent.com/heetbeet/juliawin/master/tools/curl-ca-bundle.crt" "%toolsdir%\curl-ca-bundle.crt"
        call :DOWNLOAD-FILE "https://raw.githubusercontent.com/heetbeet/juliawin/master/tools/curl.exe" "%toolsdir%\curl.exe"
        mkdir "%installdir%\curl\bin" 2>NUL        
        copy "%toolsdir%\curl.exe" "%installdir%\curl\bin\curl.exe"
        copy "%toolsdir%\curl-ca-bundle.crt" "%installdir%\curl\bin\curl-ca-bundle.crt"
    :_skipcurldownload_
goto :EOF


:: ***********************************************
:: Get a download link from a download page by matching
:: a regex and using the first match.
::
:: Example:
:: call :GET-DL-URL linkvar "https://julialang.org/downloads/" "https.*bin/winnt/x64/.*win64.exe"
:: echo %linkvar%
::
:: ***********************************************
:GET-DL-URL <%~1 outputvarname> <%~2 download page url> <%~3 regex string>

    ::name of html file
    set "_urlslug_=%~2"
    set "_urlslug_=%_urlslug_:/=-%"
    set "_urlslug_=%_urlslug_::=%"

    set "_htmlfile_=%tempdir%\%_urlslug_%"
    set "_linksfile_=%tempdir%\%_urlslug_%-links.txt"

    echo () Download link is in %~2
    echo () Fetch as %_htmlfile_%


    :: Download the download-page html
    call :DOWNLOAD-FILE "%~2" "%_htmlfile_%"
    if %errorlevel% NEQ 0 goto EOF-DEAD

    ::echo () Find download link in %_htmlfile_%

    :: Split file on '"' quotes so that valid urls will land on a seperate line
    powershell -Command "(gc '%_htmlfile_%') -replace '""', [System.Environment]::Newline  | Out-File '%_htmlfile_%--split' -encoding utf8"

    ::Find the lines of all the valid Regex download links
    findstr /i /r /c:"%~3" "%_htmlfile_%--split" > "%_linksfile_%"
    del /f /q "%_htmlfile_%--split"

    ::Save first occurance to head by reading the file with powershell and taking the first line
    for /f "usebackq delims=" %%a in (`powershell -Command "(Get-Content '%_linksfile_%')[0]"`) do (set "head=%%a")

    ::Clean up our temp files
    ::nope leave it alone...

    ::Save the result to the outputvariable
    set "%~1=%head%"

    if %errorlevel% NEQ 0 goto EOF-DEAD
goto :EOF


:: ***********************************************
:: Given a download link, what is the name of that file
:: (last thing after last "/")
:: ***********************************************
:GET-URL-FILENAME <%~1 outputvarname> <%~2 url>

    :: Loop through each "/" separation and set %~1
    :: https://stackoverflow.com/a/37631935/1490584

    set "_List_=%~2"
    set _ItemCount_=0

    :_NextItem_
    if "%_List_%" == "" goto :EOF

    set /A _ItemCount_+=1
    for /F "tokens=1* delims=/" %%a in ("%_List_%") do (
        :: echo Item %_ItemCount_% is: %%a
        set "_List_=%%b"
        set "%~1=%%a"
    )
    goto _NextItem_

goto :EOF


:: ***********************************************
:: Browse for a folder on your system
:: ***********************************************
:BROWSE-FOR-FOLDER <%~1 outputvarname>
    ::I have no idea how this works exactly...
    ::https://stackoverflow.com/a/39593074/1490584
    set %~1=
    set _vbs_="%temp%\_.vbs"
    set _cmd_="%temp%\_.cmd"
    for %%f in (%_vbs_% %_cmd_%) do if exist %%f del %%f
    for %%g in ("_vbs_ _cmd_") do if defined %%g set %%g=
    (
        echo set shell=WScript.CreateObject("Shell.Application"^)
        echo set f=shell.BrowseForFolder(0,"%~1",0,"%~2"^)
        echo if typename(f^)="Nothing" Then
        echo wscript.echo "set %~1=Dialog Cancelled"
        echo WScript.Quit(1^)
        echo end if
        echo set fs=f.Items(^):set fi=fs.Item(^)
        echo p=fi.Path:wscript.echo "set %~1=" ^& p
    )>%_vbs_%
    cscript //nologo %_vbs_% > %_cmd_%
    for /f "delims=" %%a in (%_cmd_%) do %%a
    for %%f in (%_vbs_% %_cmd_%) do if exist %%f del /f /q %%f
    for %%g in ("_vbs_ _cmd_") do if defined %%g set %%g=

goto :EOF


:: ***********************************************
:: Convert content of a variable to upper case. Expensive O(26N)
:: ***********************************************
:TOUPPER <%~1 inputoutput variable>
    for %%L IN (^^ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO SET %1=!%1:%%L=%%L!

GOTO :EOF


:: ***********************************************
:: Get base directory of a file path
:: ***********************************************
:DIRNAME <%~1 output> <filelocation>
    set "%~1=%~dp2"
GOTO :EOF


:: ***********************************************
:: Get base directory of a file path
:: ***********************************************
:FILE-NOEXT <%~1 output> <filelocation>
    set "%~1=%~n2"
GOTO :EOF

:: ***********************************************
:: Print the Julia logo
:: ***********************************************
:SHOW-JULIA-ASCII
    echo                _
    echo    _       _ _(_)_     ^|  Documentation: https://docs.julialang.org
    echo   (_)     ^| (_) (_)    ^|
    echo    _ _   _^| ^|_  __ _   ^|  Run with "/h" for help
    echo   ^| ^| ^| ^| ^| ^| ^|/ _` ^|  ^|
    echo   ^| ^| ^|_^| ^| ^| ^| (_^| ^|  ^|  Unofficial installer for Juliawin
    echo  _/ ^|\__'_^|_^|_^|\__'_^|  ^|
    echo ^|__/                   ^|
GOTO :EOF


:: ***********************************************
:: End in error
:: ***********************************************
:EOF-DEAD
    exit /b 1
