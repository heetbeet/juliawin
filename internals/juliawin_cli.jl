using Pkg

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
