using Pkg

include(joinpath(@__DIR__, "routines.jl"))
add_startup_script()

Pkg.add("Revise")
Pkg.add("OhMyREPL")
Pkg.add("ArgParse")

using ArgParse

s = ArgParseSettings(description = "This is the main commnadline interface to Juliawin.")
@add_arg_table s begin
    "--install"
        help = "Choose specifig package to install"
    "--install-dialog", "-d"
        help = "Enter the installation guide."
        action = :store_true
end
  
parsed_args = parse_args(ARGS, s)
  

if parsed_args["install"] !== nothing
    println("This is not implemented yet")
  
elseif parsed_args["install-dialog"]
  
    vscodeinstall = nothing
    while !(vscodeinstall in ("y", "n") )
      vscodeinstall = lowercase(Input("Install VSCode [Y/N]? "))
    end 
  
    junoinstall = nothing
    while !(junoinstall in ("y", "n") )
      junoinstall = lowercase(Input("Install Juno [Y/N]? "))
    end 
  
    plutoinstall = nothing
    while !(plutoinstall in ("y", "n") )
      plutoinstall = lowercase(Input("Install Pluto [Y/N]? "))
    end 
  
    jupyterinstall = nothing
    while !(jupyterinstall in ("y", "n") )
      jupyterinstall = lowercase(Input("Install Python/Conda and Jupyter [Y/N]? "))
    end
  
  
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
