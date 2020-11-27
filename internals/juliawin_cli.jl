using Pkg
include(joinpath(@__DIR__, "routines.jl"))

function tryusing(pkgsym)
  try
    @eval using $pkgsym
    return true
  catch e
      return e
  end
  
if tryusing(:ArgParse) !== true
  Pkg.add("ArgParse")
  using ArgParse
end

  
s = ArgParseSettings(description = "This is the main commnadline interface to Juliawin.")
@add_arg_table s begin
    "--install"
        help = "Choose specifig package to install"
    "--install-dialog", "-d"
        help = "Enter the installation guide."
        action = :store_true
end
  
parsed_args = parse_args(ARGS, s)
  
