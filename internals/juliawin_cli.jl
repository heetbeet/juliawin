using Pkg

include(joinpath(@__DIR__, "routines.jl"))

# We cannot be sure that Julia have already setup it's startup script
include(joinpath(@__DIR__, "..", "userdata", ".julia", "config", "juliawinconfig.jl"))

activate_binary("julia")
activate_binary("juliawin-prompt")
activate_binary("7z")

add_startup_script()

try
   using ArgParse
catch e
   Pkg.add("ArgParse")
   using ArgParse
end


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

function doflagset(app, dict)
    key = "juliawin-install$(app)"

    if key in keys(ENV)
        if lowercase(ENV[key]) == "1"
            return dict[app] = true
        elseif lowercase(ENV[key]) == "0"
            return dict[app] = false
        end
    end

    if (ans = lowercase(ask_yn("Install $app [Y/N]? "))) == "y"
        dict[app] = true
    elseif ans == "n"
        dict[app] = false
    end
end


if parsed_args["install"] !== nothing
    println("This is not implemented yet")

elseif parsed_args["install-dialog"]

    println("Note: For a good posix shell experience in in Julia, you will need a MinGW installation. "*
            "If you already have Git installed, you already have a proper MinGW installation, and can skip installation. "*
            "If you are unsure, go ahead and mark MinGW for installation.")
    println()


    dict = Dict()
    for app in ["MinGW", "VSCode", "Juno", "Pluto", "PyCall", "Jupyter" ]
        doflagset(app, dict)
    end

    if !isfile("$juliawinpackages/curl/bin/curl.exe")
        install_curl()
    end

    if dict["MinGW"]
        install_git()
    end

    if dict["VSCode"]
        install_vscode()
    end

    if dict["Juno"]
        install_atom()
        install_juno()
    end

    if dict["Pluto"]
        install_pluto()
    end

    if dict["PyCall"]
        @eval Pkg.add("PyCall")
        activate_binary("python")
    end

    if dict["Jupyter"]
       install_jupyter()
    end
end
