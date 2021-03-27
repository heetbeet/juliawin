@echo off
:: ************************************************
:: A file full of reusable bat routines to be called
:: from an external file.
::
:: Usage: functions <functionname> <arg1> <arg2> ...
:: ************************************************

:: Redirect to the functions
call :%*
goto :EOF


::*********************************************************
:: https://stackoverflow.com/a/61552059
:: Parse commandline arguments into sane variables
:: See the following scenario as usage example:
:: >> thisfile.bat /a /b "c:\" /c /foo 5
:: >> CALL :ARG-PARSER %*
:: ARG_a=1
:: ARG_b=c:\
:: ARG_c=1
:: ARG_foo=5
::*********************************************************
:ARG-PARSER <arg1> <arg2> <etc>
    ::Loop until two consecutive empty args
    :__loopargs__
        IF "%~1%~2" EQU "" GOTO :EOF

        set "__arg1__=%~1"
        set "__arg2__=%~2"

        :: Capture assignments: eg. /foo bar baz  -> ARG_FOO=bar ARG_FOO_1=bar ARG_FOO_2=baz
        IF "%__arg1__:~0,1%" EQU "/"  IF "%__arg2__:~0,1%" NEQ "/" IF "%__arg2__%" NEQ "" (
            call :ARG-PARSER-HELPER %1 %2 %3 %4 %5 %6 %7 %8 %9
        )
        :: This is for setting ARG_FOO=1 if no value follows
        IF "%__arg1__:~0,1%" EQU "/" IF "%__arg2__:~0,1%" EQU "/" (
            set "ARG_%__arg1__:~1%=1"
        )
        IF "%__arg1__:~0,1%" EQU "/" IF "%__arg2__%" EQU "" (
            set "ARG_%__arg1__:~1%=1"
        )

        shift
    goto __loopargs__

goto :EOF

:: Helper routine for ARG-PARSER
:ARG-PARSER-HELPER <arg1> <arg2> <etc>
    set "ARG_%__arg1__:~1%=%~2"
    set __cnt__=0
    :__loopsubargs__
        shift
        set "__argn__=%~1"
        if "%__argn__%"      equ "" goto :EOF
        if "%__argn__:~0,1%" equ "/" goto :EOF

        set /a __cnt__=__cnt__+1
        set "ARG_%__arg1__:~1%_%__cnt__%=%__argn__%"
    goto __loopsubargs__
goto :EOF


:: ***********************************************
:: Remove trailing slash if exists
:: ***********************************************
:NO-TRAILING-SLASH <return> <input>
    set "__notrailingslash__=%~2"
    IF "%__notrailingslash__:~-1%" == "\" (
        SET "__notrailingslash__=%__notrailingslash__:~0,-1%"
    )
    set "%1=%__notrailingslash__%"
goto :EOF


:: ***********************************************
:: Expand path like c:\bla\fo* to c:\bla\foo
:: Expansion only works for last item!
:: ***********************************************
:EXPAND-ASTERIX <return> <filepath>
    ::basename with asterix expansion
    set "__inputfilepath__=%~2"
    call :NO-TRAILING-SLASH __inputfilepath__ "%__inputfilepath__%"

    set "_basename_="
    for /f "tokens=*" %%F in ('dir /b "%__inputfilepath__%" 2^> nul') do (
        set "_basename_=%%F"
        goto :__endofasterixexp__
    )
    :__endofasterixexp__

    ::concatenate with dirname is basename found (else "")
    if "%_basename_%" NEQ "" (
        set "%~1=%~dp2%_basename_%"
    ) ELSE (
        set "%~1="
    )

    set _basename_=
goto :EOF


:: ***********************************************
:: Return full path to a filepath
:: ***********************************************
:FULL-PATH <return> <filepath>
    set "%1=%~dpnx2"
goto :EOF


:: ***********************************************
:: Remove all non-filename characters from a valid url
:: ***********************************************
:SLUGIFY-URL <returnvar> <theurl>
    set "_urlslugified_=%~2"
    set "_urlslugified_=%_urlslugified_:/=-%"
    set "_urlslugified_=%_urlslugified_::=-%"
    set "_urlslugified_=%_urlslugified_:?=-%"
    set "%~1=%_urlslugified_%"

    set _urlslugified_=
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
:GET-DL-URL <outputvarname> <download page url> <regex string>
    set "%~1="

    call :SLUGIFY-URL _urlslug_ "%~2"
    set "_htmlfile_=%temp%\%_urlslug_%"

    :: Download the download-page html
    call :DOWNLOAD-FILE "%~2" "%_htmlfile_%"
    if not exist "%_htmlfile_%" goto EOF-DEAD

    :: Split file on '"' quotes so that valid urls will land on a seperate line
    powershell -Command "(gc '%_htmlfile_%') -replace '""', [System.Environment]::Newline  | Out-File '%_htmlfile_%--split' -encoding utf8"

    FOR /F "tokens=* USEBACKQ" %%I IN (`findstr /i /r /c:"%~3" "%_htmlfile_%--split"`) do (
        set "%1=%%I"
        goto :EOF
    )
    goto EOF-DEAD

goto :EOF


:: ***********************************************
:: Given a download link, what is the name of that file
:: (last thing after last "/")
:: ***********************************************
:GET-URL-FILENAME <outputvarname> <url>

    :: Loop through each "/" separation and set %~1
    :: https://stackoverflow.com/a/37631935/1490584

    set "_List_=%~2"
    set _ItemCount_=0

    :_NextItem_
        if "%_List_%" == "" goto :_exitnextitem_

        set /A _ItemCount_+=1
        for /F "tokens=1* delims=/" %%a in ("%_List_%") do (
            :: echo Item %_ItemCount_% is: %%a
            set "_List_=%%b"
            set "_out_=%%a"
        )
        goto _NextItem_
    :_exitnextitem_

    ::remove non filename characters
    call :SLUGIFY-URL "%~1" "%_out_%"

    set _List_=
    set _itemcount_=
    set _out_=
goto :EOF


:: ***********************************************
:: Extract an archive file using 7zip
:: ***********************************************
:EXTRACT-ARCHIVE <7zipexe> <srce> <dest>
    ::Try to make a clean slate for extractor
    call :DELETE-DIRECTORY "%~3" >nul 2>&1
    mkdir "%~3" 2>NUL

    ::Extract to output directory
    call "%~1" x -y "-o%~3" "%~2"

goto :EOF


:: ***************************************
:: Unzip the master zip into a temporary directory
:: ***************************************
:: https://stackoverflow.com/questions/21704041/creating-batch-script-to-unzip-a-file-without-additional-zip-tools
:EXTRACT-ZIP-WINDOWS <srce> <dest>
    if not exist "%~1" (
        echo Error file doesn't exist: "%~1"
        exit /b -1
    )

    :: VBS is not happy with two slashes and stuff
    call :FULL-PATH src "%~1"
    call :DELETE-DIRECTORY "%~2"
    mkdir "%~2" 2>NUL

    set "vbs=%temp%\_%random%%random%.vbs"
    > "%vbs%"  echo set objShell = CreateObject("Shell.Application")
    >>"%vbs%"  echo set FilesInZip=objShell.NameSpace("%src%").items
    >>"%vbs%"  echo objShell.NameSpace("%~2").CopyHere(FilesInZip)

    cscript //nologo "%vbs%"
    :: del "%vbs%" /f /q > nul 2>&1
goto :EOF


:: ***********************************************
:: Extract MSI installer with portable settings and
:: redirecting userprofile junk
:: ***********************************************
:EXTRACT-INNO <srce> <dest>
    ::Don't affect surrounding scope
    setlocal
    set __COMPAT_LAYER=RUNASINVOKER

    ::Make a decoy userprofile to capture unwanted startmenu icons and junk
    set "userdecoy=%TEMP%\userprofiledecoy%random%%random%"
    
    mkdir "%userdecoy%" >nul 2>&1
    SET "USERPROFILE=%userdecoy%"
    SET "APPDATA=%userdecoy%"
    SET "LOCALAPPDATA=%userdecoy%"

    ::Install/extract the exe to the given location using most portable possible settings
    mkdir "%~2" >nul 2>&1
    call "%~1" /DIR="%~2" /SP- /VERYSILENT /SUPPRESSMSGBOXES /CURRENTUSER /DisableFinishedPage=yes /skipifsilent

    ::Remove the decoy userprofile
    call :DELETE-DIRECTORY "%userdecoy%" >nul 2>&1

goto :EOF


:: ***********************************************
:: Windows del command is too limited
:: ***********************************************
:DELETE-DIRECTORY <dirname>
    if not exist "%~1" ( goto :EOF )
    powershell -Command "Remove-Item -LiteralPath '%~1' -Force -Recurse"

goto :EOF


::*********************************************************
:: Execute a command and return the value
::*********************************************************
:EXEC <returnvar> <returnerror> <command>
    set "errorlevel=0"
    FOR /F "tokens=* USEBACKQ" %%I IN (`%3`) do (
        set "%1=%%I"
        goto :_done_first_line_
    )
    :_done_first_line_
    set "%2=%errorlevel%"
goto :EOF


::*********************************************************
:: Choose a file from the file selection menu
::*********************************************************
:CHOOSE-FILE <return>
    rem preparation command
    set _pwshcmd_=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|out-null; $OpenFileDialog.FileName}"
    rem exec commands powershell and get result in FileName variable
    for /f "delims=" %%I in ('%_pwshcmd_%') do set "_FileName_=%%I"

    set "%~1=%_FileName_%"
goto :EOF


::*********************************************************
:: Split a file into its dir, name, and ext
::*********************************************************
:DIR-NAME-EXT <returndir> <returnname> <returnext> <inputfile>
    set "%~1=%~dp4"
    set "%~2=%~n4"
    set "%~3=%~x4"
goto :EOF


::*********************************************************
:: Get the local date in format yyyy-mm-dd
::*********************************************************
:LOCAL-DATE <return>

    :: adapted from http://stackoverflow.com/a/10945887/1810071
    set "MyDate="
    for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined MyDate set MyDate=%%x
    for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do set %%x
    set fmonth=00%Month%
    set fday=00%Day%
    set _today_=%Year%-%fmonth:~-2%-%fday:~-2%
    set "%~1=%_today_%"
goto :EOF


::*********************************************************
:: Get the local time in format hhmmss.ms
::*********************************************************
:LOCAL-TIME <return>
    set "_tmp_=%time: =0%"
    set "_tmp_=%_tmp_:,=%"
    set "_tmp_=%_tmp_::=%"
    set "%1=%_tmp_%"
goto :EOF


::*********************************************************
:: Get a timestamp in format yyyy-mm-dd-hhmmss.ms
::*********************************************************
:TIME-STAMP <return>
    call :LOCAL-DATE _date_
    call :LOCAL-TIME _time_
    set "%~1=%_date_%-%_time_%"

goto :EOF


:: ***********************************************
:: Add a path to windows path
:: ***********************************************
:ADD-TO-PATH <path>
    call :FULL-PATH _path_ "%~1"
    set "PATH=%_path_%;%PATH%"
goto :EOF


::*********************************************************
:: Test if the parameters of a function is as expected
::*********************************************************
:TEST-OUTCOME <expected> <actual> <testname>
    if "%~1" EQU "%~2" goto :EOF

    echo *********************************************
    if "%~3" NEQ "" echo For test %~3
    echo Expected: %1
    echo Got     : %2
    echo:

goto :EOF


:: ***********************************************
:: Find Download method
:: ***********************************************
:REGISTER-DOWNLOAD-METHOD <downloadmethod>
    set "%~1="

    call curl --help >nul 2>&1
    set downloadmethod=curl
    if "%errorlevel%" EQU "0" goto :_dlmethodsuccess_

    call powershell -Command "gcm Invoke-WebRequest" >nul 2>&1
    set downloadmethod=webrequest
    if "%errorlevel%" EQU "0" goto :_dlmethodsuccess_

    call wget --help >nul 2>&1
    set downloadmethod=wget
    if "%errorlevel%" EQU "0" goto :_dlmethodsuccess_

    call powershell -Command "(New-Object Net.WebClient)" >nul 2>&1
    set downloadmethod=webclient
    if "%errorlevel%" EQU "0" goto :_dlmethodsuccess_


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

    :_dlmethodsuccess_
    set "%~1=%downloadmethod%"

goto :EOF


:: ***********************************************
:: Download a file
:: ***********************************************
:DOWNLOAD-FILE <url> <filelocation>
    call :REGISTER-DOWNLOAD-METHOD downloadmethod
    if "downloadmethod" EQU "" goto :EOF-DEAD

    IF "%downloadmethod%" == "curl" (
        call curl -g -L -f -o "%~2" "%~1"
        if "%errorlevel%" NEQ 0 goto EOF-DEAD

    ) ELSE IF "%downloadmethod%" == "webrequest" (

        call powershell -Command "Invoke-WebRequest '%~1' -OutFile '%~2'"
        if "%errorlevel%" NEQ 0 goto EOF-DEAD

    ) ELSE IF "%downloadmethod%" == "wget" (

        call wget "%1" -O "%2"
        if "%errorlevel%" NEQ 0 goto EOF-DEAD

    ) ELSE IF "%downloadmethod%" == "webclient" (
    
        call powershell -Command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2')"
        if "%errorlevel%" NEQ 0 goto EOF-DEAD
    )

goto :EOF


:: ***********************************************
:: Browse for a folder on your system
:: ***********************************************
:BROWSE-FOR-FOLDER <return>
    ::I have no idea how this works exactly...
    ::https://stackoverflow.com/a/39593074/1490584
    set %~1=
    set _vbs_="%temp%\browse_for_folder_%random%%random%.vbs"
    set _cmd_="%temp%\browse_for_folder_%random%%random%.cmd"
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
:TO-UPPER <return> <text>
    set "_text_=%~2"
    :: https://stackoverflow.com/a/2773504
    for %%L IN (^^ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO call SET "_text_=%%_text_:%%L=%%L%%"
    set "%1=%_text_%"

GOTO :EOF


:: ***********************************************
:: Print the Julia logo
:: ***********************************************
:SHOW-JULIA-ASCII

    echo                 _
    echo     _       _ _(_)_           _        ^| Juliawin commandline installer
    echo    ^| ^|     ^| (_) (_)         (_)       ^|
    echo    ^| ^|_   _^| ^|_  __ _ __   __ _ _ __   ^| GitHub.com/heetbeet/juliawin
    echo    ^| ^| ^| ^| ^| ^| ^|/ _` ^|'/ _ \'^| ^| '_ \  ^|
    echo  __/ ^| ^|_^| ^| ^| ^| (_^| ^| \/ \/ ^| ^| ^| ^| ^| ^| Run with "/h" for help
    echo ^|___/ \__'_^|_^|_^|\__'_^|\__/\_/^|_^|_^| ^|_^| ^|
    echo:

GOTO :EOF


:: ***********************************************
:: Get the focus of a window via it's PID
:: ***********************************************
:TEST-JULIAWIN-PATHS <testflag>
    set "%~1=1"

    call :FULL-PATH teststring "%~dp0..\packages\julia\bin"
    call set "xpath_mutated=x%%PATH:%teststring%=xxx%%"
    if "x%PATH%" equ "%xpath_mutated%" (
        set "%~1=0"
    )

goto :EOF


:: ***************************************************
:: Test if a directory is empty
:: **************************************************
:IS-DIRECTORY-EMPTY <flag>
    set "%~1=0"
    for /F %%i in ('dir /b "c:\test directory\*.*"') do (
       echo set "%~1=1"
       goto :eof
    )
goto :eof


:: ***********************************************
:: End in error
:: ***********************************************
:EOF-DEAD
    exit /b 1
    
GOTO :EOF
