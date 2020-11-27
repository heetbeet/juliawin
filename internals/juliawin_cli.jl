using Pkg

include(joinpath(@__DIR__, "routines.jl"))
add_startup_script()

function lazyinstall(pkgstring)
  if !(pkgstring ∈ keys(Pkg.installed()))
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


function ask_yn(message)
    answer = nothing
    while !(answer in ("y", "n"))
        global answer
        answer = lowercase(Input(message))
    end
    return answer
end


if parsed_args["install"] !== nothing
    println("This is not implemented yet")
  
elseif parsed_args["install-dialog"]
  
    vscodeinstall = ask_yn("Install VSCode [Y/N]? ")
    junoinstall = ask_yn("Install Juno [Y/N]? ")
    plutoinstall = ask_yn("Install Pluto [Y/N]? ")
    jupyterinstall = ask_yn("Install Python/Conda and Jupyter [Y/N]? ")

    if !isfile("$juliawinpackages/curl/bun/curl.exe")
        install_curl()
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
    
    if jupyterinstall == "y"
       install_jupyter()
    end
end
