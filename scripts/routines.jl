using Pkg

# We assume this file is located under scripts
juliawinhome = abspath(joinpath(@__DIR__, ".."))
juliawinbin = joinpath(juliawinhome, "bin")
juliawinvendor = joinpath(juliawinhome, "vendor")
juliawinuserdata = joinpath(juliawinhome, "userdata")
juliatemp = joinpath(tempdir(), "juliawin")

mkpath(juliawinhome)
mkpath(juliawinbin)
mkpath(juliawinvendor)
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

    extract_file(atom_zip, joinpath(juliawinvendor, "atom"))
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
    activate_binary("pluto")
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

    vscodehome = joinpath(juliawinvendor, "vscode")

    vscode_zip = download_asset("https://update.code.visualstudio.com/latest/win32-x64-archive/stable")
    extract_file(vscode_zip, vscodehome)

    mkpath("$vscodehome/data/user-data")
    mkpath("$vscodehome/data/extensions")

    run(`"$juliawinhome/bin/code-cli.bat" --install-extension julialang.language-julia`)

end


function install_tcc()
    if !(Sys.iswindows())
         error("unimplemented")
    end

    #https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
    tcc_zip = download_from_homepage("http://download.savannah.gnu.org/releases/tinycc/",
                        r"tcc-0.9.27-win64-bin.zip";
                        prefix="http://download.savannah.gnu.org/releases/tinycc/")

    extract_file(tcc_zip, joinpath(juliawinvendor, "tcc"))
    #activate_binary("atom")
    #activate_binary("apm")
end
