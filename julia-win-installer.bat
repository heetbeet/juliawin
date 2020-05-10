#!/usr/bin/env python
#=
""" 
cls
:: ========== Batch part ==========
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
set "juliafile=%~dp0%~n0.bat"
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


exit /b 
"""
# ========== Python part ==========
from __future__ import print_function
print("""
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Run with "/h" for help
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Unofficial installer for Juliawin
 _/ |\__'_|_|_|\__'_|  |
|__/                   |
""")

import os
import sys
import shutil
import subprocess
import tarfile
FNULL = open(os.devnull, 'w')
import tempfile


#input for python 2
try: raw_input
except: raw_input=input

#%%
#printing for errors
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


#%%
def download_file(url, filelocation):
    """
    Download a file using wget or curl.
    """
    filelocation = os.path.abspath(filelocation)
    try:
        subprocess.call(['wget', '--help'], 
                        stdout=FNULL, 
                        stderr=subprocess.STDOUT)
        iswget = True
    except:
        iswget = False
        

    if iswget:      
       subprocess.call(["wget", 
                        url, 
                        "-O", 
                        os.path.abspath(filelocation)])
    else:
        subprocess.call(["curl", "-g", "-L", "-f", "-o", 
                         os.path.abspath(filelocation),
                         url])
        
    
#%%
def move_tree(source, dest):
    '''
    Move a tree from source to destination
    '''
    source = os.path.abspath(source)
    dest = os.path.abspath(dest)

    try:
        os.makedirs(dest)
    except: 
        pass

    for ndir, dirs, files in os.walk(source):
        for d in dirs:
            absd = os.path.abspath(ndir+"/"+d)
            try:
                os.makedirs(dest + '/' + absd[len(source):])
            except:
                pass

        for f in files:
            absf = os.path.abspath(ndir+"/"+f)
            os.rename(absf, dest + '/' + absf[len(source):])
    shutil.rmtree(source)
    
    
#%%
def unnest_dir(dirname):
    r'''
    de-nesting single direcotry paths:
        From:
        (destdir)--(nestdir)--(dira)
                           \__(dirb)
        To:
        (destdir)--(dira)
                \__(dirb)
    '''
    
    if len(os.listdir(dirname)) == 1:
        deepdir = dirname+'/'+os.listdir(dirname)[0]
        if os.path.isdir(dirname):
            move_tree(deepdir, dirname)
            return True
        
    return False
    

#%%
def rmtree(dirname):
    '''
    Rmtree with exist_ok=True
    '''
    if os.path.isdir(dirname):
        shutil.rmtree(dirname)


#%%
def rmpath(pathname):
    '''
    Like rmtree, but file/tree agnostic
    '''
    rmtree(pathname)
    try:
        os.remove(pathname)
    except:
        pass
    
    
#%%
def cppath(srce, dest):
    '''
    File/tree agnostic copy
    '''
    dest = os.path.abspath(dest)
    try:
        os.makedirs(os.path.dirname(dest))
    except:
        pass
    
    if os.path.isdir(srce):
        shutil.copytree(srce, dest)
    else:
        shutil.copy(srce, dest)


#%%        
def untar(fname, output):
    try:
        os.makedirs(output)
    except:
        pass
    
    if fname.lower().endswith("tar.gz"):
        tar = tarfile.open(fname, "r:gz")
        tar.extractall(path=output)
        tar.close()
    elif fname.lower().endswith("tar"):
        tar = tarfile.open(fname, "r:")
        tar.extractall(path=output)
        tar.close()
    else:
        raise ValueError("Cannot extract filetype "+fname)


#%% Parse the arguments
args = {}
for i, arg1 in enumerate(sys.argv[1:]):
    if i == len(sys.argv[1:])-1:
        arg2 = ''
    else:
        arg2 = sys.argv[1:][i+1]
        
    tst1 =  arg1.replace('/','-')[:1] 
    tst2 =  arg2.replace('/','-')[:1] 
    
    if tst1 == '-' and (tst2 == '-' or tst2 == ''):
        args[arg1[1:].lower()] = True
    elif tst1 == '-':
        args[arg1[1:].lower()] = arg2
        
        
#%% Print help menu
if 'h' in args:
    print("The setup program accepts the following command line parameters:")
    print("")
    print("-HELP, -H")
    print("   Show this information and exit")
    print("/Y")
    print("   Yes to all")
    print('/DIR "\path\to\Dirname"')
    print("   Overwrite the default with custom directory")
    print("/RMDIR")
    print("   Clear the install directory (if not empty)")
    exit(0)
    

#%% Set up the environment
installdir = "~/Juliawin"
juliatemp = os.path.join(tempfile.gettempdir(), "juliawin")
try:
    os.makedirs(juliatemp)
except: #FileExistsError not in python 2
    pass

try: __file__
except: __file__ = os.getcwd()+'/julia-win-installer.bat'
open(juliatemp+'/thisfile.txt', 'w').write(os.path.abspath(__file__))


#%% choose a directory
if "dir" in args:
    installdir = args["dir"]
    
if not "y" in args and not "dir" in args:
    print("""
      [Y]es: continue
      [N]o: cancel the operation
      [D]irectory: choose my own directory
    """)
    
    ynd = "xxx"
    if "y" in args:
        ynd = "y"
    while ynd.lower() not in "ynd":
        
        ynd = raw_input("Install Juliawin in "+installdir+" [Y/N/D]? ")
            
        if ynd.lower() == "n":
            exit(-1)
            
        if ynd.lower() == "d":
            installdir = raw_input("Please enter custom directory: ")
            if installdir == "":
                ynd = "xxx"
    
    
#%% make sure directory is valid
installdir = os.path.abspath(os.path.expanduser(installdir))
if "rmdir" in args:
    shutil.rmtree(installdir)
     
try:
    os.makedirs(installdir)
except: #FileExistsError not in python 2
    pass
    
if not "rmdir" in args:
    #test if write-readable
    try:
        with open(installdir+"/thisisatestfiledeleteme", 'w') as f: pass
        os.remove(installdir+"/thisisatestfiledeleteme")
    except:
        eprint("Error, can't read/write to "+installdir)
        exit(1)
        
    if len(os.listdir(installdir)) > 0:
        eprint("Error, the install directory is not empty.")
        exit(1)


#%% write location of this script to tempdirectory
open(juliatemp+'/installdir.txt', 'w').write(installdir)


#%% Setup path environment
os.environ["PATH"] = os.pathsep.join([
    installdir+'/julia/bin',
    installdir+'/julia/libexec',
    installdir+'/atom',
    installdir+'/atom/resources/cli',
    installdir+'/atom/resources/app/apm/bin',
    os.environ["PATH"]
])
    
os.environ["JULIA_DEPOT_PATH"] = installdir+'/.julia'
os.environ["ATOM_HOME"] = installdir+'/.atom'

    
#%% Download lates julia linux
print("() Configuring the download source")
download_file("https://julialang.org/downloads",
              juliatemp+'/julialang_org_downloads')


#yes: https://julialang-s3.julialang.org/bin/linux/x64/1.4/julia-1.4.1-linux-x86_64.tar.gz
#no:  https://julialang-s3.julialang.org/bin/linux/aarch64/1.0/julia-1.0.5-linux-aarch64.tar.gz
dlurl = None
for i in open(juliatemp+'/julialang_org_downloads').read().split('"'):
    if (i.startswith('http') and '/bin/linux/' in i and "x86" in i and i.endswith('64.tar.gz')):
        dlurl = i
    
fname = juliatemp+'/'+dlurl.split('/')[-1]

print("() Download "+dlurl+" to ")
print("() "+fname)
download_file(dlurl, fname)

untar(fname, installdir+"/julia")
unnest_dir(installdir+"/julia")

#%%Install the Julia scripts
if os.path.isfile(os.path.splitext(__file__)[0]+'.jl'):
    juliafile = os.path.splitext(__file__)[0]+'.jl'
else:
    juliafile = __file__


subprocess.call(["julia", "--color=yes", "-e", "Base.banner()"])

subprocess.call(["julia", juliafile, "INSTALL-ATOM"])

subprocess.call(["julia", juliafile, "INSTALL-JUNO"])

subprocess.call(["julia", juliafile, "INSTALL-JUPYTER"])

subprocess.call(["julia", juliafile, "MAKE-BASHES"])


'''
=#
# ========== Julia part ==========
paths = [
(raw"packages\julia-*", "bin"),
(raw"packages\julia-*", "libexec"),
(raw"packages\atom-*", ""),
(raw"packages\atom-*", "resources\\cli"),
(raw"packages\curl-*", "bin"),
(raw"packages\nsis-*", ""),
(raw"packages\resource_hacker*", "")
]

thisfile = abspath(@__FILE__)
juliatemp = joinpath(tempdir(), "juliawin")

installdir = strip(read(open(joinpath(juliatemp, "installdir.txt")), String))
packagedir = strip(read(open(joinpath(juliatemp, "packagedir.txt")), String))
userdatadir =  strip(read(open(joinpath(juliatemp, "userdatadir.txt")), String))


if length(ARGS)>=1
    runroutine = ARGS[1]
else
    runroutine = "HELLO-WORLD"
end


#******************************************************
# Automatic paths
#******************************************************
function get_execs()
    exts = ".exe .bat .cmd .vbs .vbe .js .msc" |> split
    files = Dict{String, Tuple{String, String, String}}()
    for (i,j) in paths
        fullpath = expand_fullpath(joinpath(installdir, i))
        if fullpath === nothing
            continue
        end

        for file in readdir(joinpath(fullpath, j))
            #make sure exe > others
            (name, ext) = splitext(file)
            if ext == ".exe"
                files[name] = (i,j,file)
            end
            if ! haskey(files, name) && ext in exts
                files[name] = (i,j,file)
            end
        end
    end
    return files
end


#******************************************************
# Bat method equivalent
#******************************************************
function get_dl_url(url, domatch; notmatch=nothing, prefix="")
    urlslug = replace(url, "/"=>"-")
    urlslug = replace(urlslug, ":"=>"")
    urlslug = replace(urlslug, "?"=>"-")
    lnkpath = joinpath(juliatemp, urlslug)
    download(url, lnkpath)
    println(lnkpath)
    open(lnkpath) do file
        pagecontent = read(file, String)
        for line in split(pagecontent, "\"") #"
            if match(domatch, ""*line) != nothing
                if notmatch==nothing || match(notmatch, ""*line) == nothing
                    return prefix*line
                end
            end
        end
    end
end


function download_asset(dlurl)
    urlslug = split(dlurl, "/")[end]
    urlslug = replace(urlslug, ":"=>"")
    urlslug = replace(urlslug, "?"=>"-")

    path = joinpath(juliatemp, urlslug)
    if !isfile(path)
        println("() Downloading $dlurl to")
        println("() $path, this may take a while")
        download(dlurl, path)
    end
    return path
end


function extract_file(archive, destdir, fixdepth=true)
    mkpath(destdir)
    if Sys.iswindows()
        run(`7z x -y "-o$destdir" "$archive"`)
    else
        if endswith(lowercase(archive), ".tar.gz")
                run(`tar -xzf "$archive" -C "$destdir"`)
        elseif endswith(lowercase(archive), ".tar")
                run(`tar -xf "$archive" -C "$destdir"`)
        else
            error("unimplemented")
        end
    end

    if fixdepth
        dirs = filter(x -> isdir(joinpath(destdir, x)), readdir(destdir))
        if length(dirs) == 1
            tmpdest = destdir*"--resolve-depth"
            mv(destdir, tmpdest, force=true)
            mv(joinpath(tmpdest,dirs[1]), destdir, force=true)
            rm(tmpdest, force=true, recursive=true)
        end
    end
end

function install_from_homepage(url, domatch; notmatch=nothing, prefix="")
    dlurl = get_dl_url(url, domatch; notmatch=notmatch, prefix=prefix)
    dlzip = download_asset(dlurl)
    dldest = joinpath(packagedir, splitext(basename(dlzip))[1])
    extract_file(dlzip, dldest)
    return dldest
end


function expand_fullpath(filepath)
    """
    Helper to expand paths ending with an asterix
    """
    dir = dirname(filepath)
    base = basename(filepath)
    if !endswith(base, "*")
        return joinpath(dir, base)
    end

    base = replace(base, "*"=>"")
    matches = [i for i in readdir(dir) if startswith(lowercase(i), lowercase(base))]
    if length(matches) == 0 return nothing
    end

    return joinpath(dir, sort(matches)[1])
end


if runroutine == "HELLO-WORLD"

    println("() Hello World")

end


if runroutine == "ADD-STARTUP-SCRIPT"
    juliahome = expand_fullpath(joinpath(packagedir,"julia-*"))
    open(joinpath(juliahome, "etc", "julia", "startup.jl"), "w") do f
        write(f, raw"""
        # This file should contain site-specific commands to be executed on Julia startup;
        # Users may store their own personal commands in `~/.julia/config/startup.jl`.


        #*****************************
        # Use portable package location
        #*****************************
        DEPOT_PATH[1] = abspath(String(@__DIR__)*raw"/../../../../userdata/.julia")


        if Sys.iswindows()
            #*****************************
            # Add curl from packages to path
            #*****************************
            for i=1 #to keep scope clear
                packagedir = abspath(String(@__DIR__)*raw"/../../..")
                curlpackages = [i for i in readdir(packagedir) if startswith(i, "curl")]
                if length(curlpackages)>0
                    ENV["PATH"] = abspath(packagedir*"/"*curlpackages[1]*"/bin")*";"*ENV["PATH"]
                end
            end


            #*****************************
            # Make use of curl and overwrite download_powershell for stubborn libraries.
            #*****************************
            if Sys.which("curl") !== nothing
                ENV["BINARYPROVIDER_DOWNLOAD_ENGINE"] = "curl"
                Base.download_powershell(url::AbstractString, filename::AbstractString) = Base.download_curl(Sys.which("curl"), url, filename)
                download = Base.download
            end

        end
        """)
    end
end


if runroutine == "INSTALL-CURL"
    #download external url for julia
    install_from_homepage("https://curl.haxx.se/windows/",
                         r"dl.*win64.*zip";
                         prefix="https://curl.haxx.se/windows/")
    try
        rm(joinpath(packagedir, "curl"), recursive=true)
    catch e end
end


if runroutine == "INSTALL-ATOM"
    if Sys.iswindows()
        dlreg = r"/atom/atom/.*x64.*zip"
    else #linux
        dlreg = r"/atom/atom/.*amd64.*tar.gz"
    end

    #https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
    install_from_homepage("https://github.com/atom/atom/releases",
                        dlreg;
                        notmatch=r"-beta",
                        prefix="https://github.com/")

    mkpath(joinpath(userdatadir, ".atom"))
end


if runroutine == "INSTALL-JUNO"

    if Sys.iswindows()
        apmbin = "apm.cmd"
    else #linux
        apmbin = "apm"
    end

    #https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
    #make apm available as .bat as well
    run(`$apmbin install language-julia`)
    run(`$apmbin install julia-client`)
    run(`$apmbin install ink`)
    run(`$apmbin install uber-juno`)
    run(`$apmbin install latex-completions`)
    run(`$apmbin install indent-detective`)
    run(`$apmbin install hyperclick`)
    run(`$apmbin install tool-bar`)

    using Pkg;
    Pkg.add("Atom")
    Pkg.add("Juno")
end


if runroutine == "INSTALL-JUPYTER"
    using Pkg
    Pkg.add("PyCall")
    Pkg.add("IJulia")
    Pkg.add("Conda")

    using Conda
    Conda.add("jupyter")
    Conda.add("jupyterlab")

    Pkg.add("PyPlot")
end


if runroutine == "INSTALL-NSIS"
    #extra redirect
    dlurl = install_from_homepage("https://nsis.sourceforge.io/Download",
                                 r"http.*//.*/nsis/nsis-.*exe.*download")
end


if runroutine == "INSTALL-RESOURCEHACKER"
    dlurl = install_from_homepage("http://www.angusj.com/resourcehacker/",
                                 r"resource_hacker.*.zip";
                                 prefix="http://www.angusj.com/resourcehacker/")
end

if runroutine == "MAKE-BATS"
    binpath = joinpath(installdir, "bin")
    mkpath(binpath)

    batroutines = raw"""
        goto :EOF

        :: ***********************************************
        :: Expand a asterix path to a full path
        :: ***********************************************
        :EXPAND-FULLPATH

            ::basename with asterix expansion
            set "_basename_="
            for /f "tokens=*" %%F in ('dir /b "%~2" 2^> nul') do set "_basename_=%%F"

            ::If asterix expansion failed, return ""
            if "%_basename_%" NEQ "" goto :continueexpand
                set "%~1="
                goto :EOF
            :continueexpand

            ::If success, return "path\expandable\with\asterix\optional\second\part"
            set "_path_=%~dp2%_basename_%"
            if "%~3" NEQ "" set "_path_=%_path_%\%~3"
            set "%~1=%_path_%"

        goto :EOF

        :: ***********************************************
        :: Add a path to window's %PATH% (if exists)
        :: ***********************************************
        :ADD-TO-PATH

            call :EXPAND-FULLPATH _path_ "%~1" "%~2"
            if "%_path_%" NEQ "" set "PATH=%_path_%;%PATH%"

        goto :EOF
        """

    battemplate=raw"""
        @echo off
        SETLOCAL
        call %~dp0\juliawin-environment.bat

        __exec__

        exit /b %errorlevel%


        """*batroutines

    juliawinenviron=raw"""
        @echo off

        __setpath__

        set "JULIA_DEPOT_PATH=%~dp0..\userdata\.julia"
        set "ATOM_HOME=%~dp0..\userdata\.atom"


        """*batroutines

    #Inject the paths
    juliawinenviron = replace(juliawinenviron,
        "__setpath__"=>
        join(["""call :ADD-TO-PATH "%~dp0..\\$(i[1])" "$(i[2])" """ for i in paths], "\n")
    )


    #Write the environment setup to bin/juliawin-en...
    open(joinpath(binpath,"juliawin-environment.bat"), "w") do f
        write(f, juliawinenviron)
    end


    for (name, (i,j,file)) in get_execs()
        exectxt = """
        call :EXPAND-FULLPATH execpath "%~dp0..\\$i" "$j"
        call "%execpath%\\$file" %*
        """
        battxt = replace(battemplate, "__exec__"=>exectxt)
        open(joinpath(binpath,name*".bat"), "w") do f
            write(f, battxt)
        end
    end


    #Custom one for atom, since atom can't be next to julia.bat (why???)
    if isfile(joinpath(binpath, "atom.bat"))
        atomtxt = read(joinpath(binpath, "atom.bat"), String)
        open(joinpath(binpath, "atom.bat"), "w") do f
            atomtxt_ = replace(atomtxt,
                "call :EXPAND-FULLPATH "=>
                """
                ::for some reason juno hates being next to julia.bat
                ::this is clearly a bug that needs to be addressed with atom
                set "curdir=%~dp0"
                set "curdir=%curdir:~0,-1%"
                if /i "%cd%" EQU "%curdir%" cd ..\\packages

                call :EXPAND-FULLPATH """)

            write(f, atomtxt_)
        end
    end

    open(joinpath(binpath, "noshell.vbs"), "w") do f
        quadstr = "\"\"\"\""
        write(f, """
        If WScript.Arguments.Count >= 1 Then
            ReDim arr(WScript.Arguments.Count-1)
            For i = 0 To WScript.Arguments.Count-1
                Arg = WScript.Arguments(i)
                If InStr(Arg, " ") > 0 Then Arg = $quadstr & Arg & $quadstr
              arr(i) = Arg
            Next

            RunCmd = Join(arr)
            CreateObject("Wscript.Shell").Run RunCmd, 0, True
        End If
        """)
    end

    #******************************************************
    # Hand-picked paths
    #******************************************************
    open(joinpath(binpath,"IJulia-Lab.bat"),"w") do f
        write(f, raw"""
        @echo off
        call %~dp0\julia.bat -e "using IJulia; jupyterlab()"
        exit /b %errorlevel%
        """
        )
    end

    open(joinpath(binpath,"IJulia-Notebook.bat"),"w") do f
        write(f, raw"""
        @echo off
        call %~dp0\julia.bat -e "using IJulia; notebook()"
        exit /b %errorlevel%
        """
        )
    end
end


if runroutine == "MAKE-EXES"
    #Original source: WinPython
    nsistemplate = raw"""
    ;================================================================
    !addincludedir ""
    !define COMMAND __command__
    !define PARAMETERS __parameters__
    !define WORKDIR ""
    ;!define Icon ""
    !define OutFile __outfile__
    ;================================================================
    # Standard NSIS plugins
    !include "WordFunc.nsh"
    !include "FileFunc.nsh"

    SilentInstall silent
    AutoCloseWindow true
    ShowInstDetails nevershow
    RequestExecutionLevel user

    Section ""
    Call Execute
    SectionEnd

    Function Execute
    ;Set working Directory ===========================
    StrCmp ${WORKDIR} "" 0 workdir
    System::Call "kernel32::GetCurrentDirectory(i ${NSIS_MAX_STRLEN}, t .r0)"
    SetOutPath $0
    Goto end_workdir
    workdir:
    SetOutPath "${WORKDIR}"
    end_workdir:
    ;Get Command line parameters =====================
    ${GetParameters} $R1
    StrCmp "${PARAMETERS}" "" end_param 0
    StrCpy $R1 "${PARAMETERS} $R1"
    end_param:
    ;===== Execution =================================
    Exec '"${COMMAND}" $R1'
    FunctionEnd
    """


    for (program, shell) in [("atom", false), ("julia", true), ("IJulia-Lab", false), ("IJulia-Notebook", false)]
        if shell
            data = [("__command__", "\$EXEDIR\\bin\\$(program).bat"),
                    ("__parameters__", ""),
                    ("__outfile__", "$(program).exe")]
        else
            data = [("__command__", "wscript.exe"),
                    ("__parameters__", "\$EXEDIR\\bin\\noshell.vbs \$EXEDIR\\bin\\$(program).bat"),
                    ("__outfile__", "$(program).exe")]
        end

        nsis_txt = nsistemplate
        for (fnd, repl) in data
            nsis_txt = replace(nsis_txt, fnd => "\"$(repl)\"")
        end

        nspath = joinpath(juliatemp, "$program.nsi")
        tmpexe = joinpath(juliatemp, "$program.exe")
        outpath = joinpath(installdir, "$program.exe")
        open(nspath, "w") do f
            write(f, nsis_txt)
        end

        run(`makensis -V2 "$nspath"`)
        cp("$tmpexe", "$outpath", force=true)

        if haskey(get_execs(), program)
            (i,j,k) = get_execs()[program]
            filepath = joinpath(expand_fullpath(joinpath(installdir, i)), j, k)
            respath = joinpath(juliatemp, "$(program).res")

            #read(`ResourceHacker -open "$filepath" -save "$respath" -action extract -mask ,,, `)
            read(`ResourceHacker -open "$tmpexe" -save "$(tmpexe)_tmp.exe" -action addoverwrite -res "$respath"`)
        end
        if isfile("$(tmpexe)_tmp.exe")
            cp("$(tmpexe)_tmp.exe", "$(outpath)_tmp.exe", force=true)
        #else
        #    mv("$tmpexe", "$outpath", force=true)
        end

    end
end


# '''