#= 2>NUL
@echo off
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
::	This is the .bat part of the file
:: 
::     =/\                 /\=
::     / \'._   (\_/)   _.'/ \
::    / .''._'--(o.o)--'_.''. \
::   /.' _/ |`'=/ " \='`| \_ `.\
::  /` .' `\;-,'\___/',-;/` '. '\
:: /.-'       `\(-V-)/`       `-.\
:: `            "   "            `
:: =====================================================


SETLOCAL EnableDelayedExpansion
CALL :SHOW-JULIA-ASCII

set "arg1=%~1"
set "arg2=%~2"


:: ========== Run from explorer.exe? =======
:: https://stackoverflow.com/a/61511609/1490584
set "dclickcmdx=%systemroot%\system32\cmd.exe /c xx%~0x x"
set "actualcmdx=%cmdcmdline:"=x%"

set isdoubleclicked=0
if /I "%dclickcmdx%" EQU "%actualcmdx%" (
	set isdoubleclicked=1
)

:: ========== Help Menu ===================
if /I "%arg1%" EQU "/?" goto help
if /I "%arg1%" EQU "/H" goto help
if /I "%arg1%" EQU "/HELP" goto help
if /I "%arg1%" EQU "-H" goto help
if /I "%arg1%" EQU "-HELP" goto help
goto exithelp
:help
ECHO The setup program accepts one command line parameter.
Echo:
ECHO /HELP, /H, /?
ECHO   Show this information.
ECHO /Y
ECHO   Select default directory name.
ECHO /DIR="x:\Dirname"
ECHO   Overwrite the default with custom directory.
goto :EOF-ALIVE
:exithelp


:: ========== Setup Environment ============
set "tempdir=%temp%\juliawin"
mkdir "%tempdir%" 2>NUL
 
set "toolsdir=%tempdir%\tools"
mkdir "%toolsdir%" 2>NUL

set "installdir=%userprofile%\JuliaWin"


:: ========== Custom path provided =========
IF /I "%arg1%" EQU "/DIR" (
	set "installdir=%arg2%"
	goto exitchoice
)


:: ========== Choose Install Dir ===========
if /I "%arg1%" EQU "/Y" goto exitchoice
:choice
Echo: 
Echo   [Y]es: continue
Echo   [N]o: cancel the operation
Echo   [D]irectory: choose my own directory
Echo: 
set /P c="Install Julia in %installdir% [Y/N/D]?"
if /I "%c%" EQU "Y" goto :exitchoice
if /I "%c%" EQU "N" goto :EOF-FORCE
if /I "%c%" EQU "D" goto :selectdir
goto :choice
:selectdir

call :BROWSE-FOR-FOLDER installdir
if /I "%installdir%" EQU "Dialog Cancelled" (
	ECHO: 1>&2
	ECHO Dialog box cancelled 1>&2
	goto :EOF-FORCE
)

if /I "%installdir%" EQU "" (
	ECHO: 1>&2
	ECHO Error, folder selection broke 1>&2
	goto :EOF-DEAD
)
:exitchoice


:: ========== Ensure install dir is r/w ====
mkdir "%installdir%" 2>NUL
echo: > "%installdir%\thisisatestfiledeleteme"
rm "%installdir%\thisisatestfiledeleteme" >nul 2>&1
if errorlevel 1 (
	ECHO: 1>&2
	ECHO Error, can't read/write to %installdir% 1>&2
	goto :EOF-DEAD
)


:: ========== Ensure install dir is empty ==
call :IS-DIRECTORY-EMPTY checkempty "%installdir%"
if "%checkempty%" EQU "0" (
	ECHO: 1>&2
	ECHO Error, the install directory is not empty. 1>&2
	ECHO: 
	ECHO You can run the remove command and try again: 1>&2
	ECHO ^>^> rm "%installdir%" 1>&2
	goto :EOF-DEAD
)


:: ========== SETUP PATH VARS =============
SET "PATH=%systemroot%\System32\WindowsPowerShell\v1.0;%PATH%"
SET "PATH=%installdir%\julia\bin;%PATH%"
SET "PATH=%installdir%\atom;%PATH%"
SET "PATH=%installdir%atom\resources\cli;%PATH%"
SET "PATH=%toolsdir%;%PATH%"


:: ========== DOWNLOAD AND INSTALL LATEST JULIA
ECHO: 
ECHO () Configuring the download source
call :GET-DL-URL juliaurl "https://julialang.org/downloads" "https.*bin/winnt/x64/.*win64.exe"

call :GET-URL-FILENAME juliafname "%juliaurl%"

ECHO:
ECHO () Download %juliaurl% to
ECHO () %tempdir%\%juliafname%

call :DOWNLOAD-FILE "%juliaurl%" "%tempdir%\%juliafname%"

ECHO:
ECHO () Extracting into %installdir%\julia
call "%tempdir%\%juliafname%" /SP- /VERYSILENT /DIR="%installdir%\julia"

julia %0 


:: ================================================
::	This is where we store the .bat subroutines
:: 
::     =/\                 /\=
::     / \'._   (\_/)   _.'/ \
::    / .''._'--(o.o)--'_.''. \
::   /.' _/ |`'=/ " \='`| \_ `.\
::  /` .' `\;-,'\___/',-;/` '. '\
:: /.-'       `\(-V-)/`       `-.\
:: `            "   "            `
:: ================================================
goto :EOF-ALIVE


:: ***********************************************
:: Find Download method
:: ***********************************************
:REGISTER-DOWNLOAD-METHOD
	powershell -Command "gcm Invoke-WebRequest" >nul 2>&1
	set downloadmethod=webrequest
	if NOT errorlevel 1 goto :EOF

	wget --help >nul 2>&1
	set downloadmethod=wget
	if NOT errorlevel 1 goto :EOF

	curl --help >nul 2>&1
	set downloadmethod=curl
	if NOT errorlevel 1 goto :EOF

	powershell -Command "(New-Object Net.WebClient)" >nul 2>&1
	set downloadmethod=webclient
	if NOT errorlevel 1 goto :EOF

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
	GOTO :EOF-FORCE

goto :EOF


:: ***********************************************
:: Download a file
:: ***********************************************
:DOWNLOAD-FILE <url> <filelocation>
	if "%downloadmethod%"=="" call :REGISTER-DOWNLOAD-METHOD
	if errorlevel 1 goto :EOF-FORCE

	IF "%downloadmethod%" == "webrequest" (
	   
		powershell -Command "Invoke-WebRequest '%~1' -OutFile '%~2'"

	) ELSE IF "%downloadmethod%" == "wget" (
	   
		wget "%1" -O "%2"

	) ELSE IF "%downloadmethod%" == "curl" (

		curl -s -S -g -L -f -o "%~1" "%~2"

	) ELSE IF "%downloadmethod%" == "webclient" (

		powershell -Command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2')"
	)

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

	:: Download the download-page html
	call :DOWNLOAD-FILE "%~2" "%tempdir%\download-page.txt"

	:: Split file on '"' quotes so that valid urls will land on a seperate line
	powershell -Command "(gc '%tempdir%\download-page.txt') -replace '""', [System.Environment]::Newline  | Out-File '%tempdir%\download-page.txt' -encoding utf8"

	::Find the lines of all the valid Regex download links
	findstr /i /r /c:"%~3" "%tempdir%\download-page.txt" > "%tempdir%\download-links.txt" 

	::Save first occurance to head by reading the file with powershell and taking the first line
	for /f "usebackq delims=" %%a in (`powershell -Command "(Get-Content '%tempdir%\download-links.txt')[0]"`) do (set "head=%%a")

	::Clean up our temp files
	rm "%tempdir%\download-page.txt"
	rm "%tempdir%\download-links.txt"

	::Save the result to the outputvariable
	set "%~1=%head%"

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
:: Test if a directory is empty
:: ***********************************************
:IS-DIRECTORY-EMPTY <%~1 outputvarname> <%~2 directory-path>
	:: No-existant is empty
	if not exist "%~2" (
	  set "%~1=1"
	  goto :EOF
	)

	:: Is folder empty
	set _TMP_=
	for /f "delims=" %%a in ('dir /b "%~2"') do set _TMP_=%%a

	IF {%_TMP_%}=={} (
	  set "%~1=1"
	) ELSE (
	  set "%~1=0"
	)

goto :EOF


:: ***********************************************
:: Convert content of a variable to upper case. Expensive O(26N)
:: ***********************************************
:TOUPPER <%~1 inputoutput variable>
    for %%L IN (^^ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO SET %1=!%1:%%L=%%L!

GOTO :EOF


:: ***********************************************
:: Print the Julia logo
:: ***********************************************
:SHOW-JULIA-ASCII
	echo                _                                                   
	echo    _       _ _(_)_     ^|  Documentation: https://docs.julialang.org
	echo   (_)     ^| (_) (_)    ^|                                           
	echo    _ _   _^| ^|_  __ _   ^|  Run with "/?" for help                   
	echo   ^| ^| ^| ^| ^| ^| ^|/ _` ^|  ^|                                           
	echo   ^| ^| ^|_^| ^| ^| ^| (_^| ^|  ^|  Unofficial installer for JuliaWin        
	echo  _/ ^|\__'_^|_^|_^|\__'_^|  ^|                                           
	echo ^|__/                   ^|                                           
GOTO :EOF


:: ***********************************************
:: Three exit stategies
:: ***********************************************
:EOF-DEAD
	::courtesy pause for explorer runners
	if "%isdoubleclicked%" EQU "1" (
		ECHO:
		pause
	)
	exit /b 1

:EOF-FORCE
	::We don't care about pausing
	exit /b 1

:EOF-ALIVE
	::courtesy pause for explorer runners
	if "%isdoubleclicked%" EQU "1" (
		ECHO:
		pause
	)
	goto :EOF



:: ====================================================================
::	This is the end of our batch script...
::  below are the Julia part of this file
::                _
::    _       _ _(_)_     |  
::   (_)     | (_) (_)    |
::    _ _   _| |_  __ _   | 
::   | | | | | | |/ _` |  |
::   | | |_| | | | (_| |  |                            
::  _/ |\__'_|_|_|\__'_|  |                                         
:: |__/                   |
:: ====================================================================
=#


println("hello world")