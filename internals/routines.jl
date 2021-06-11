using Pkg

# We assume this file is located under packages\Juliawin
juliawinhome = abspath(joinpath(@__DIR__, ".."))
juliawinbin = joinpath(juliawinhome, "bin")
juliawinpackages = joinpath(juliawinhome, "packages")
juliawinuserdata = joinpath(juliawinhome, "userdata")
juliatemp = joinpath(tempdir(), "juliawin")

mkpath(juliawinhome)
mkpath(juliawinbin)
mkpath(juliawinpackages)
mkpath(juliawinuserdata)
mkpath(juliatemp)

function add_to_current_environment(path)
    pathsep = if Sys.iswindows() ";" else ":" end
    ENV["PATH"] = path*pathsep*ENV["PATH"]
end

add_to_current_environment(juliawinbin)

function urlslug(url)
    url = replace(url, "/"=>"-")
    url = replace(url, ":"=>"")
    url = replace(url, "?"=>"-")
    url = replace(url, "="=>"-")
    return url
end


function activate_binary(name)
    if isfile(joinpath(juliawinhome, "($name.exe)"))
        mv(joinpath(juliawinhome, "($name.exe)"), joinpath(juliawinhome, "$name.exe"), force=true)
    end

    if isfile(joinpath(juliawinbin, "($name.bat)"))
        mv(joinpath(juliawinbin, "($name.bat)"), joinpath(juliawinbin, "$name.bat"), force=true)
    end
end


function deactivate_binary(name)
    if isfile(joinpath(juliawinhome, "$name.exe"))
        mv(joinpath(juliawinhome, "$name.exe"), joinpath(juliawinhome, "($name.exe)"), force=true)
    end

    if isfile(joinpath(juliawinbin, "$name.bat"))
        mv(joinpath(juliawinbin, "$name.bat"), joinpath(juliawinbin, "($name.bat)"), force=true)
    end
end


#******************************************************
# Get a downloadable url from a website's homepage
#******************************************************
function get_dl_url(url, domatch; notmatch=nothing, prefix="")
    urlslug = replace(url, "/"=>"-")
    urlslug = replace(urlslug, ":"=>"")
    urlslug = replace(urlslug, "?"=>"-")
    urlslug = replace(urlslug, "="=>"-")

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


#******************************************************
# Download something to the juliawin temp directory
#******************************************************
function download_asset(dlurl)
    fname = urlslug(split(dlurl, "/")[end])

    path = joinpath(juliatemp, fname)
    if !isfile(path)
        println("() Downloading $dlurl to")
        println("() $path, this may take a while")
        download(dlurl, path)
    end
    return path
end


#******************************************************
# Get url from homepage and download the url
#******************************************************
function download_from_homepage(url, domatch; notmatch=nothing, prefix="")
    dlurl = get_dl_url(url, domatch; notmatch=notmatch, prefix=prefix)
    dlzip = download_asset(dlurl)

    return dlzip
end


#******************************************************
# Extract files using 7zip extractor
#******************************************************
function extract_file(archive, destdir, fixdepth=true)
    rm(destdir, recursive=true, force=true)
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


#*******************************************
# Windows bat files cannot handle unix line endings
#*******************************************
function writecrlf(f, txt)
    write(f, replace(txt, "\r\n"=>"\n"), "\n"=>"\r\n")
end


#*******************************************
# Add startup script to Julia to force Julia to use proper curl library
#*******************************************
function add_startup_script()
    scripthome = joinpath(juliawinhome, "userdata", ".julia", "config")
    scriptpath = joinpath(scripthome, "startup.jl")

    header = """include(joinpath(@__DIR__, "juliawinconfig.jl"))
    """

    txt = if isfile(scriptpath) read(scriptpath, String) else "" end
    if !contains(txt, strip(header))
        txt = header * txt
    end

    open(scriptpath, "w") do f
        write(f, txt)
    end
end


function install_curl()
    curl_zip = download_from_homepage(
        "https://curl.haxx.se/windows/",
        r"dl.*win64.*zip";
        prefix="https://curl.haxx.se/windows/"
    )

    extract_file(curl_zip, joinpath(juliawinpackages, "curl"))
    activate_binary("curl")
end


function install_atom()
    dlreg = if Sys.iswindows()
         r"/atom/atom/.*x64.*zip"
    else #linux
         r"/atom/atom/.*amd64.*tar.gz"
    end

    #https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
    atom_zip = download_from_homepage("https://github.com/atom/atom/releases",
                        dlreg;
                        notmatch=r"-beta",
                        prefix="https://github.com/")

    extract_file(atom_zip, joinpath(juliawinpackages, "atom"))
    activate_binary("atom")
    activate_binary("apm")
end


function install_juno()
    activate_binary("atom")
    activate_binary("apm")
    activate_binary("juno")

    apmbin = if Sys.iswindows() "$juliawinbin/apm.bat" else apmbin = "apm" end

    # https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
    # make apm available as .bat as well
    run(`$apmbin install language-julia`)
    run(`$apmbin install julia-client`)
    run(`$apmbin install ink`)
    run(`$apmbin install uber-juno`)
    run(`$apmbin install latex-completions`)
    run(`$apmbin install indent-detective`)
    run(`$apmbin install hyperclick`)
    run(`$apmbin install tool-bar`)
    run(`$apmbin install file-watcher`)

    Pkg.add("Atom")
    Pkg.add("Juno")

end


function install_pluto()
    Pkg.add("Pluto")
    Pkg.add("HTTP")
    activate_binary("pluto")
    activate_binary("open-with-julia-or-pluto")
end


function install_jupyter()
    Pkg.add("PyCall")
    Pkg.add("IJulia")
    Pkg.add("Conda")

    # Everything is in an eval to get around global scope and 
    # the world age problem
    @eval begin 
        using Conda
        Conda.add("jupyter")
        Conda.add("jupyterlab")
    end

    activate_binary("python")
    activate_binary("IJulia-notebook")
    activate_binary("IJulia-lab")

end


function install_vscode()
    activate_binary("code")
    activate_binary("code-cli")
    activate_binary("julia-vscode")

    vscodehome = joinpath(juliawinpackages, "vscode")

    #run(`"$juliawinbin/curl.bat" -L -o"$juliatemp/vscode.exe" "https://aka.ms/win32-x64-user-stable"`)
    vscode_zip = download_asset("https://update.code.visualstudio.com/latest/win32-x64-archive/stable")
    extract_file(vscode_zip, vscodehome)

    mkpath("$vscodehome/data/user-data")
    mkpath("$vscodehome/data/extensions")

    run(`"$juliawinhome/bin/code-cli.bat" --install-extension julialang.language-julia`)

end


function install_git()

    # https://github.com/git-for-windows/git/releases/download/v2.29.2.windows.2/PortableGit-2.29.2.2-64-bit.7z.exe
    git_zip = download_from_homepage("https://github.com/git-for-windows/git/releases/",
                        r"/download/.*PortableGit.*64-bit.7z.exe";
                        prefix="https://github.com/")
    extract_file(git_zip, joinpath(juliawinpackages, "git"))

end
