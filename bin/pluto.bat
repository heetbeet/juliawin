@eval 1# 2>nul & @call "%~dp0julia.bat" "%~0" %* & @goto:eof

using Pluto

if length(ARGS) == 1 && lowercase(ARGS[1]) == "--help"
    println("The available arguments to Pluto isn't straight-forward and more tailored towards developers.")
    println("Here is the Configuration logic for Pluto in GitHub.")
    Base.run(`powershell.exe Start "https://github.com/fonsp/Pluto.jl/blob/master/src/Configuration.jl"`)
    exit()
end

if length(ARGS)%2 != 0
    error("Commandline arguments must come in pairs, like --foo 1 --bar 2")
end

kwargs = Dict{Symbol, Any}()
for i = (1:floor(Int, length(ARGS)/2))
    key = Symbol(lstrip(ARGS[i*2-1], ['-']))
    value = ARGS[i*2]
    try
        value = parse(Bool, ARGS[i*2])
    catch e end
    try
        value = parse(Float, ARGS[i*2])
    catch e end
    try
        value = parse(Int, ARGS[i*2])
    catch e end
end

Pluto.run(;kwargs...)
