#= 2>NUL

:: =====================================================
:: This is an automatic install script for Julia
:: First half of the script is written in batch
:: Second half of the script is written in Julia
::
:: The batch part makes sure the environment is set up
:: correctly and that Julia is available, while the
:: heavy lifting is done in Julia itself.
:: =====================================================

@echo off
SETLOCAL
cls

:: For dev-purposes, reset path to minimal OS programs
set "PATH=%systemroot%;%systemroot%\System32;%systemroot%\System32\WindowsPowerShell\v1.0"


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


SETLOCAL EnableDelayedExpansion

:: Ensure thisfile has file extension
set "thisfile=%~0"
if "%~n0" EQU "%~n0%~x0" (set "thisfile=%thisfile%.bat")

set "arg1=%~1"
set "arg2=%~2"


:: ========== Run from explorer.exe? =======
:: https://stackoverflow.com/a/61511609/1490584
set "dclickcmdx=%systemroot%\system32\cmd.exe /c xx%~0x x"
set "actualcmdx=%cmdcmdline:"=x%"

:: If double clicked, restart with a pause guard
if /I "%dclickcmdx%" EQU "%actualcmdx%" (
    call "%~dpn0" %*
    echo:
    pause
    goto :EOF
)

:: If given flag, run with pause guard
IF /I "%arg1%" EQU "/P" (
    call "%~dpn0"
    echo:
    pause
    goto :EOF
)

:: ========== Help Menu ===================
CALL :SHOW-JULIA-ASCII

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
ECHO /P
ECHO   Pause before exit. (Default Explorer double-click behaviour.)
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
SET "PATH=%toolsdir%;%PATH%"

set "installdir=%userprofile%\Juliawin"

echo %thisfile% > "%tempdir%\thisfile.txt"

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


:: ========== Ensure install dir is r/w ====
mkdir "%installdir%" 2>NUL
echo: > "%installdir%\thisisatestfiledeleteme"
del /f /q "%installdir%\thisisatestfiledeleteme" >nul 2>&1
if %errorlevel% NEQ 0 (
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
    ECHO ^>^> rmdir "%installdir%" /s 1>&2
    goto :EOF-DEAD
)


:: ========== Save this path to a file ==
echo %installdir% > "%tempdir%\installdir.txt"

:: ========== SETUP PATH VARS =============
SET "PATH=%installdir%\julia\bin;%PATH%"
SET "PATH=%installdir%\julia\libexec;%PATH%"
SET "PATH=%installdir%\atom;%PATH%"
SET "PATH=%installdir%\atom\resources\cli;%PATH%"
SET "PATH=%installdir%\curl\bin;%PATH%"

set "JULIA_DEPOT_PATH=%installdir%\.julia"
set "ATOM_HOME=%installdir%\.atom"

:: ========== DOWNLOAD AND INSTALL LATEST JULIA
ECHO:
ECHO () Configuring the download source

call :BOOTSTRAP-CURL

call :GET-DL-URL juliaurl "https://julialang.org/downloads" "https.*bin/winnt/x64/.*win64.exe"
if %errorlevel% NEQ 0 goto :EOF-DEAD

call :GET-URL-FILENAME juliafname "%juliaurl%"

ECHO () Download %juliaurl% to
ECHO () %tempdir%\%juliafname%


 call :DOWNLOAD-FILE "%juliaurl%" "%tempdir%\%juliafname%"
 if %errorlevel% NEQ 0 goto :EOF-DEAD


ECHO () Extracting into %installdir%\julia
call "%tempdir%\%juliafname%" /SP- /VERYSILENT /DIR="%installdir%\julia"


call julia --color=yes -e "Base.banner()"
call julia "%thisfile%" ADD-STARTUP-SCRIPT
call julia "%thisfile%" INSTALL-CURL
call julia "%thisfile%" INSTALL-ATOM
call julia "%thisfile%" INSTALL-JUNO
call julia "%thisfile%" INSTALL-JUPYTER
call julia "%thisfile%" MAKE-BATS

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
        call :DOWNLOAD-FILE "https://raw.githubusercontent.com/heetbeet/juliawin/bugfix/win7support/tools/curl-ca-bundle.crt" "%toolsdir%\curl-ca-bundle.crt"
        call :DOWNLOAD-FILE "https://raw.githubusercontent.com/heetbeet/juliawin/bugfix/win7support/tools/curl.exe" "%toolsdir%\curl.exe"
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
:: Get base directory of a file path
:: ***********************************************
:DIRNAME <%~1 output> <filelocation>
    set "%~1=%~dp2"
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
    echo   ^| ^| ^|_^| ^| ^| ^| (_^| ^|  ^|  Unofficial installer for Juliawin
    echo  _/ ^|\__'_^|_^|_^|\__'_^|  ^|
    echo ^|__/                   ^|
GOTO :EOF


:: ***********************************************
:: End in error
:: ***********************************************
:EOF-DEAD
    exit /b 1


:: ====================================================================
::    This is the end of our batch script...
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


juliatemp = joinpath(tempdir(), "juliawin")
installdir = strip(read(open(joinpath(juliatemp, "installdir.txt")), String))
thisfile = strip(read(open(joinpath(juliatemp, "thisfile.txt")), String))
runroutine = ARGS[1]

#=
Same method as the bat equivalent
=#
function get_dl_url(url, domatch; notmatch=nothing, prefix="")
    urlslug = replace(url, "/"=>"-")
    urlslug = replace(urlslug, ":"=>"")
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
    path = joinpath(juliatemp, split(dlurl, "/")[end])
    println("() Downloading $dlurl to")
    println("() $path, this may take a while")
    download(dlurl, path)
    return path
end


function extract_file(archive, destdir, fixdepth=true)
    mkpath(destdir)
    run(`7z x -y "-o$destdir" "$archive"`)
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


if runroutine == "HELLO-WORLD"

    println("() Hello World")

end


if runroutine == "ADD-STARTUP-SCRIPT"
    open(joinpath(installdir, "julia", "etc", "julia", "startup.jl"), "w") do f
        write(f, raw"""
        # This file should contain site-specific commands to be executed on Julia startup;
        # Users may store their own personal commands in `~/.julia/config/startup.jl`.


        #*****************************
        # Use portable package location
        #*****************************
        DEPOT_PATH[1] = abspath(String(@__DIR__)*raw"/../../../.julia")


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
        # Make use of the available curl
        #*****************************
        if Sys.which("curl") !== nothing
            ENV["BINARYPROVIDER_DOWNLOAD_ENGINE"] = "curl"
            Base.download(url::AbstractString, filename::AbstractString) = Base.download_curl(Sys.which("curl"), url, filename)
            download = Base.download
        end

        """)
    end
end


if runroutine == "INSTALL-CURL"
	#download external url for julia
    curlurl = get_dl_url("https://curl.haxx.se/windows/",
                        r"dl.*win64.*zip";
                        prefix="https://curl.haxx.se/windows/")
    curlzip = download_asset(curlurl)
	extract_file(curlzip, joinpath(installdir, "curl-tmp"))
	mv(joinpath(installdir, "curl-tmp"), joinpath(installdir, "curl"), force=true)

    #We want to move towards version numbers in directories
	#remove bootsrap curl if it exists
	#curlpackages = [i for i in readdir(installdir) if startswith(i, "curl")]
	#if length(curlpackages) >= 2 && "curl" in curlpackages
	#	rm(joinpath(installdir, "curl"), recursive=true)
	#end
end


if runroutine == "INSTALL-ATOM"
    #https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
    atomurl = get_dl_url("https://github.com/atom/atom/releases",
                        r"/atom/atom/.*x64.*zip",
                        notmatch=r"-beta",
                        prefix="https://github.com/")
    atomzip = download_asset(atomurl)

    extract_file(atomzip, joinpath(installdir, "atom"))
    mkpath(joinpath(installdir, ".atom"))

end


if runroutine == "INSTALL-JUNO"

    #https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
    #make apm available as .bat as well
    run(`apm.cmd install language-julia`)
    run(`apm.cmd install julia-client`)
    run(`apm.cmd install ink`)
    run(`apm.cmd install uber-juno`)
    run(`apm.cmd install latex-completions`)
    run(`apm.cmd install indent-detective`)
    run(`apm.cmd install hyperclick`)
    run(`apm.cmd install tool-bar`)

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


if runroutine == "MAKE-BATS"
    mkpath(joinpath(installdir, "scripts"))

    juliawinenviron=raw"""
        @echo off
        __setpath__

        set "JULIA_DEPOT_PATH=%~dp0..\.julia"
        set "ATOM_HOME=%~dp0..\.atom"
        """

    battemplate=raw"""
        @echo off
        SETLOCAL
        call %~dp0\juliawin-environment.bat

        __exec__

        exit /b %errorlevel%
        """

    paths = raw"""
        julia\bin
        atom
        atom\resources\cli
        curl\bin
        """ |> split

    pathsbat = join(["""SET "PATH=%~dp0..\\$path;%PATH%" """ for path in paths], "\n")
    juliawinenviron = replace(juliawinenviron, "__setpath__"=>pathsbat)
    open(joinpath(installdir,"scripts","juliawin-environment.bat"), "w") do f
        write(f, juliawinenviron)
    end

    exts = ".exe .bat .cmd .vbs .vbe .js .msc" |> split
    files = Dict{String, String}()
    for path in paths
        println(path)
        for file in readdir(joinpath(installdir, path))
            #make sure exe > others
            (name, ext) = splitext(file)
            if ext == ".exe"
                files[name] = joinpath(path, file)
            end
            if ! haskey(files, name) && ext in exts
                files[name] = joinpath(path, file)
            end
        end
    end

    for (name, path) in files
        battxt = replace(battemplate, "__exec__"=>"call \"%~dp0\\..\\$path\" %*")
        open(joinpath(installdir,"scripts",name*".bat"), "w") do f
            write(f, battxt)
        end
    end

    #Custom one for atom, since atom can't be next to julia.bat (why???)
    open(joinpath(installdir,"scripts","atom.bat"), "w") do f
        (name, path) = ("atom", files["atom"])

        battxt = replace(battemplate, "__exec__"=> """

            ::for some reason juno hates (!!!) being next to julia.bat
            set "curdir=%~dp0"
            set "curdir=%curdir:~0,-1%"
            if /i "%cd%" EQU "%curdir%" cd ..\\atom

            call \"%~dp0\\..\\$path\" %*
            """)

        write(f, battxt)
    end

    open(joinpath(installdir, "scripts", "noshell.vbs"), "w") do f
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

    open(joinpath(installdir,"julia.bat"),"w") do f
        write(f, raw"""
        @echo off
        call %~dp0\scripts\julia.bat %*
        exit /b %errorlevel%
        """
        )
    end

    open(joinpath(installdir,"IJulia-Lab.bat"),"w") do f
        write(f, raw"""
        @echo off
        call %~dp0\scripts\julia.bat -e "using IJulia; jupyterlab()"
        exit /b %errorlevel%
        """
        )
    end

    open(joinpath(installdir,"IJulia-Notebook.bat"),"w") do f
        write(f, raw"""
        @echo off
        call %~dp0\scripts\julia.bat -e "using IJulia; notebook()"
        exit /b %errorlevel%
        """
        )
    end

    open(joinpath(installdir,"atom.bat"),"w") do f
        write(f, raw"""
        @echo off

        ::for some reason juno hates (!!!) being next to julia.bat
        set "curdir=%~dp0"
        set "curdir=%curdir:~0,-1%"
        if /i "%cd%" EQU "%curdir%" cd atom

        start "" "%~dp0\scripts\noshell.vbs" "%~dp0\scripts\atom.bat" %*
        exit /b %errorlevel%
        """
        )
    end

end
