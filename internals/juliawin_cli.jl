using Pkg

include(joinpath(@__DIR__, "routines.jl"))

# We cannot be sure that Julia have already setup it's startup script
include(joinpath(@__DIR__, "..", "userdata", ".julia", "config", "juliawinconfig.jl"))

activate_binary("julia")
activate_binary("juliawin-prompt")
activate_binary("7z")

add_startup_script()

function installAndUse(pkgsym)
     try
        @eval using $pkgsym
        return true
    catch e
        Pkg.add(String(pkgsym))
        @eval using $pkgsym
    end
end

installAndUse(:Revise)
installAndUse(:OhMyREPL)
installAndUse(:ArgParse)

using ArgParse
s = ArgParseSettings(description = "This is the main commandline interface to Juliawin.")
@add_arg_table s begin
    "--install"
        help = "Choose specific package to install"
    "--install-dialog", "-d"
        help = "Enter the installation guide."
        action = :store_true
end

parsed_args = parse_args(ARGS, s)

function input(prompt::String="")::String
    print(prompt)
    return chomp(readline())
end

function ask_yn(message)
    answer = nothing
    while true
        answer = lowercase(input(message))
        if answer == "y" || answer == "n"
            return answer
        end
    end
end


if parsed_args["install"] !== nothing
    println("This is not implemented yet")

elseif parsed_args["install-dialog"]

    println("Note: For a good posix shell experience in in Julia, you will need a MinGW installation. "*
            "If you already have Git installed, you already have a proper MinGW installation, and can skip installation. "*
            "If you are unsure, go ahead and mark MinGW for installation.")

    gitinstall = ask_yn("Install MinGW [Y/N]? ")
    vscodeinstall = ask_yn("Install VSCode [Y/N]? ")
    junoinstall = ask_yn("Install Juno [Y/N]? ")
    plutoinstall = ask_yn("Install Pluto [Y/N]? ")
    pycallinstall = ask_yn("Install PyCall [Y/N]? ")
    jupyterinstall = ask_yn("Install Jupyter [Y/N]? ")

    if !isfile("$juliawinpackages/curl/bin/curl.exe")
        install_curl()
    end

    if gitinstall == "y"
        install_git()
    end

    if vscodeinstall == "y"
        install_vscode()
    end

    if junoinstall == "y"
        install_atom()
        install_juno()
    end

    if plutoinstall == "y"
        install_pluto()
    end

    if pycallinstall == "y"
        @eval Pkg.add("PyCall")
        activate_binary("python")
    end

    if jupyterinstall == "y"
       install_jupyter()
    end
end
