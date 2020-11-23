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


::*********************************************************
:: Find a file like "Applicaton.yaml" somewhere in an upper directory
:: Cd up up up until the file is found
::*********************************************************
:FIND-PARENT-WITH-FILE <returnvar> <startdir> <filename>
	pushd "%~2"
		:__filesearchloop__
			set "__thisdir__=%cd%"
			if "%__thisdir__%" neq "%__thisdir_prev__%" goto :__continuefilesearch__
			    echo Could not find Application.yaml
			    set "%1=NUL"
			    goto :__filesearchcomplete__
			:__continuefilesearch__

			if exist "%3" (
				set "%1=%cd%"
				goto :__filesearchcomplete__
			)
		    cd ..
		    set "__thisdir_prev__=%thisdir%"
			goto :__filesearchloop__

	:__filesearchcomplete__
	popd

	set __thisdir__=
    set __thisdir_prev__=
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
::
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

    call :SLUGIFY-URL _urlslug_ "%~2"

    set "_htmlfile_=%temp%\%_urlslug_%"
    set "_linksfile_=%temp%\%_urlslug_%-links.txt"

    :: Download the download-page html
    call :DOWNLOAD-FILE "%~2" "%_htmlfile_%"

    if %errorlevel% NEQ 0 goto EOF-DEAD

    :: Split file on '"' quotes so that valid urls will land on a seperate line
    powershell -Command "(gc '%_htmlfile_%') -replace '""', [System.Environment]::Newline  | Out-File '%_htmlfile_%--split' -encoding utf8"

    ::Find the lines of all the valid Regex download links
    findstr /i /r /c:"%~3" "%_htmlfile_%--split" > "%_linksfile_%"


    ::Save first occurance to head by reading the file with powershell and taking the first line
    for /f "usebackq delims=" %%a in (`powershell -Command "(Get-Content '%_linksfile_%')[0]"`) do (set "head=%%a")


    ::Save the result to the outputvariable
    set "%~1=%head%"

    if "%_linksfile_%" EQU "" (
        echo Could not find regex %~3 on webpage %~2
        goto :EOF-DEAD
    )

    set _htmlfile_=
    set _linksfile_=
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


:: ***********************************************
:: Extract MSI installer with portable settings and
:: redirecting userprofile junk
:: ***********************************************
:EXTRACT-INNO <srce> <dest>
    ::Don't affect surrounding scope
    setlocal

    ::Make a decoy userprofile to capture unwanted startmenu icons and junk
    mkdir "%TEMP%\userprofiledecoy" >nul 2>&1
    SET "USERPROFILE=%TEMP%\userprofiledecoy"
    SET "APPDATA=%TEMP%\userprofiledecoy"
    SET "LOCALAPPDATE=%TEMP%\userprofiledecoy"

    ::Install/extract the exe to the given location using most portable possible settings
    mkdir "%~2" >nul 2>&1
    call "%~1" /DIR="%~2" /SP- /VERYSILENT /SUPPRESSMSGBOXES /CURRENTUSER

    ::Remove the decoy userprofile
    call :DELETE-DIRECTORY "%TEMP%\userprofiledecoy" >nul 2>&1

goto :EOF


:: ***********************************************
:: Extract Python installer to final location
:: dark.exe is required for the extraction
:: ***********************************************
:EXTRACT-PYTHON <darkexe> <srce> <dest>
    ::Don't affect surrounding scope
    setlocal

    set "__pytemp__=%TEMP%\pythontempextract"

    ::del /f /q /s "%__pytemp__%" >nul 2>&1
    call :DELETE-DIRECTORY "%__pytemp__%"

    call :DELETE-DIRECTORY "%~3" >nul 2>&1
    mkdir "%~3" 2>NUL

    "%~1" "%~2" -x "%__pytemp__%"

    ::Loop through msi files and extract the neccessary ones
    FOR %%I in ("%__pytemp__%\AttachedContainer\*.msi") DO call :__msiextractpython__ "%%I" "%~3"
    goto :__guardmsiextractpython__
        :__msiextractpython__ <srce> <dest>
            setlocal
            ::filer out unneeded msi installs
            if /i "%~n1" EQU "test" goto :EOF
            if /i "%~n1" EQU "doc" goto :EOF
            if /i "%~n1" EQU "dev" goto :EOF
            if /i "%~n1" EQU "launcher" goto :EOF
            if /i "%~n1" EQU "test" goto :EOF
            if /i "%~n1" EQU "ucrt" goto :EOF
            if /i "%~n1" EQU "path" goto :EOF
            if /i "%~n1" EQU "pip" goto :EOF

            msiexec /a "%~1" /qb TARGETDIR="%~2"
        goto :EOF
    :__guardmsiextractpython__

    FOR %%I in ("%~2\*.msi") DO del /q /s "%%I"
    call :DELETE-DIRECTORY "%__pytemp__%"

    set __pytemp__=
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
    FOR /F "tokens=* USEBACKQ" %%I IN (`%3`) do set "%1=%%I"
    set "%2=%errorlevel%"
goto :EOF


::*********************************************************
:: Test git
::*********************************************************
:TEST-GIT <return>
    call git --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo "Git is not installed or added to your path!"
        echo "Get git from https://git-scm.com/downloads"
        set "%1=0"
        goto :EOF
    )

    set "%1=1"
goto :EOF


::*********************************************************
:: Test the project's git directory
::*********************************************************
:GIT-PROJECT-DIR <return> <startpath>
    set %1=

    call :TEST-GIT __gitflag__
    if __gitflag__ equ 0 (
        goto :EOF
    )

    :: ****************************
    :: Get the base git directory
    pushd "%~2"
        ::git toplevel
        call :EXEC __gitdir__ __err__ "git rev-parse --show-toplevel"

        ::but what if it is deploy-scripts submodule with basename deploy-scripts
        for /F %%I in ("%__gitdir__%") do  if "%%~nI" neq "deploy-scripts" (goto :__nogitnest__)
        pushd "%__gitdir__%\.."
            call :EXEC __gitdir__ __err__ "git rev-parse --show-toplevel"
        popd
        :__nogitnest__

        :: turn into correct slashes
        call :FULL-PATH __gitdir__ "%__gitdir__%"
    popd

    if __err__ neq 1 (
        set "%1=%__gitdir__%"
    )
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
:: Expand a asterix path to a full path
:: ***********************************************
:ADD-ASTERIXABLE-TO-PATH <asterixable path> <optional\extra\path\>
    :: first part may be extended with an asterix
    call :EXPAND-ASTERIX _path_ "%~1"

    if "%_path_%" EQU "" goto :EOF

    :: second part may be empty
    if "%~2" NEQ "" set "_path_=%_path_%\%~2"

    set "PATH=%_path_%;%PATH%"
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


::*********************************************************
:: Shift arguments to the right
::*********************************************************
:SHIFT-ARGS <return> <argstoshift...>
    set __returnname__=%1
    shift
    shift
    set __args__=%1
    :__parse__
        shift
        set __first__=%1
        if not defined __first__ goto :__endparse__
        set __args__=%__args__% %__first__%
    goto :__parse__
    :__endparse__

    set %__returnname__%=%__args__%
goto :EOF


:: ***********************************************
:: Find Download method
:: ***********************************************
:REGISTER-DOWNLOAD-METHOD

    call curl --help >nul 2>&1
    set downloadmethod=curl
    if %errorlevel% EQU 0 goto :_dlmethodsuccess_

    call powershell -Command "gcm Invoke-WebRequest" >nul 2>&1
    set downloadmethod=webrequest
    if %errorlevel% EQU 0 goto :_dlmethodsuccess_

    call wget --help >nul 2>&1
    set downloadmethod=wget
    if %errorlevel% EQU 0 goto :_dlmethodsuccess_

    call powershell -Command "(New-Object Net.WebClient)" >nul 2>&1
    set downloadmethod=webclient
    if %errorlevel% EQU 0 goto :_dlmethodsuccess_

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

    :_dlmethodsuccess_
    set "%~1=%downloadmethod%"

goto :EOF


:: ***********************************************
:: Download a file
:: ***********************************************
:DOWNLOAD-FILE <url> <filelocation>
    call :REGISTER-DOWNLOAD-METHOD downloadmethod
    if "%errorlevel%" NEQ "0" goto :EOF-DEAD

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
:: Ensure a temporary CURL is available and in PATH
:: ***********************************************
:BOOTSTRAP-CURL <directory>
    mkdir "%~1" 2>NUL
    echo ^(^) Bootstrap a temporary curl
    call :DOWNLOAD-FILE "https://raw.githubusercontent.com/heetbeet/juliawin/master/tools/curl-ca-bundle.crt" "%~1\curl-ca-bundle.crt"
    call :DOWNLOAD-FILE "https://raw.githubusercontent.com/heetbeet/juliawin/master/tools/curl.exe" "%~1\curl.exe"

    call :ADD-TO-PATH "%~1"

goto :EOF


:: ***********************************************
:: Browse for a folder on your system
:: ***********************************************
:BROWSE-FOR-FOLDER <return>
    ::I have no idea how this works exactly...
    ::https://stackoverflow.com/a/39593074/1490584
    set %~1=
    set _vbs_="%temp%\browse_for_folder.vbs"
    set _cmd_="%temp%\browse_for_folder.cmd"
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
:: Print the Julia logo
:: ***********************************************
:DOWNLOAD-FROM-GITHUB-DIRECTORY <githublink> <destdir>
    echo () Downloading %~1 to %~2
    mkdir "%~2" 2>NUL

    set "_htmlfile_=%temp%\githubrawhtml.html"
    set "_linksfile_=%temp%\githubfiles.txt"

    :: Download the download-page html
    call :DOWNLOAD-FILE "%~1" "%_htmlfile_%" >nul 2>&1

    if %errorlevel% NEQ 0 goto EOF-DEAD

    :: Split file on '"' quotes so that valid urls will land on a seperate line
    powershell -Command "(gc '%_htmlfile_%') -replace '""', [System.Environment]::Newline  | Out-File '%_htmlfile_%--split' -encoding utf8"

    ::Find the lines of all the valid Regex download links
    findstr /i /r /c:"/.*/blob/.*/.*" "%_htmlfile_%--split" > "%_linksfile_%"

    ::https://raw.githubusercontent.com/heetbeet/juliawin/blob/master/README.md
    ::https://raw.githubusercontent.com/heetbeet/juliawin/master/julia-win-installer.bat
    for /F "usebackq tokens=*" %%A in ("%_linksfile_%") do call :__githubdownload__ "%%A" "%~2"
    goto :__guardgithubdownload__
        :__githubdownload__ <githublink> <destdir>
            call :GET-URL-FILENAME _fname_ "%~1"
            set "_filelink_=https://raw.githubusercontent.com%~1"
            set "_filelink_=%_filelink_:/blob/=/%"
            call :DOWNLOAD-FILE "%_filelink_%" "%~2\%_fname_%" >nul 2>&1
        goto :EOF
    :__guardgithubdownload__

GOTO :EOF


:: ***********************************************
:: Get settings via a bat file
:: ***********************************************
:GET-SETTINGS-VIA-BAT-FILE <batfile>
    set "batname=%~n1"
    set "tempfile=%temp%\%batname%-%random%%random%.bat%"
    echo f | xcopy "%~1" "%tempfile%" /y > nul 2>1

    call :EDIT-FILE-IN-NOTEPAD "%tempfile%"
    call "%tempfile%"
    del "%tempfile%" /s /f /q > nul 2>1

goto :EOF

:: ***********************************************
:: Open notepad to edit a file
:: ***********************************************
:EDIT-FILE-IN-NOTEPAD <filepath>
    if not exist "%~1" (
        echo: > "%~1"
    )

    ::start notepad
    for /f "tokens=2 delims==; " %%a in (' wmic process call create "notepad.exe "%~1"" ^| find "ProcessId" ') do set PID=%%a

    call :GET-FOCUS-OF-PID %PID%

    ::wait until closed
    :waitfornotepad
        TASKLIST | findstr "notepad.*%PID%.*" > "%temp%\checkfindstroutput.txt"
        FOR /F "usebackq" %%A IN ('%temp%\checkfindstroutput.txt') DO set checkfindstroutput=%%~zA
        IF "%checkfindstroutput%" EQU "0" goto :donewithnotepad
        goto :waitfornotepad
    :donewithnotepad

goto :EOF


:: ***********************************************
:: Get the focus of a window via it's PID
:: ***********************************************
:GET-FOCUS-OF-PID <PID>
    set "randnum=%RANDOM%%RANDOM%RANDOM"
    echo var sh=new ActiveXObject("WScript.Shell");              >   "%temp%\focusmaker%randnum%.js"
    echo if (sh.AppActivate(WScript.Arguments.Item(1)) == 0) {   >>  "%temp%\focusmaker%randnum%.js"
    echo     sh.SendKeys("%% r");                                >>  "%temp%\focusmaker%randnum%.js"
    echo }                                                       >>  "%temp%\focusmaker%randnum%.js"

    cscript //E:JScript //nologo "%temp%\focusmaker%randnum%.js" "focusmaker%randnum%.js" "%~1"
    del "%temp%\focusmaker%randnum%.js" /s /f /q > nul 2>1

goto :EOF


:: ***********************************************
:: End in error
:: ***********************************************
:EOF-DEAD
    exit /b 1

GOTO :EOF