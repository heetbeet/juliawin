using Pkg

include(joinpath(@__DIR__, "routines.jl"))

activate_binary("julia")
activate_binary("juliawin-prompt")
activate_binary("7z")

add_startup_script()

function lazyinstall(pkgstring)
  # There must be a better way to infer the package location...
  if !isdir(joinpath(@__DIR__, "..", "userdata", ".julia", "packages", pkgstring))
    Pkg.add(pkgstring)
  end
end

lazyinstall("Revise")
lazyinstall("OhMyREPL")
lazyinstall("ArgParse")

using ArgParse
s = ArgParseSettings(description = "This is the main commandline interface to Juliawin.")
@add_arg_table s begin
    "--install"
        help = "Choose specifig package to install"
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
    while !(answer in ("y", "n"))
        global answer
        answer = lowercase(input(message))
    end
    return answer
end


if parsed_args["install"] !== nothing
    println("This is not implemented yet")

elseif parsed_args["install-dialog"]

    gitinstall = ask_yn("Install MinGW? (This in in order to use Unix shell commands, note "*
                        "that this option is not necessary if you have Git installed on your system) [Y/N]? ")

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
