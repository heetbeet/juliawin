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
