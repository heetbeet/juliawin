@eval 1# 2>nul & @call "%~dp0julia.bat" "%~dp0%~n0.bat" %* & @goto:eof

pluto_secret_file = joinpath((@__DIR__), "..", "userdata", ".julia", "plutosecret.txt")
using Sockets
using HTTP

get_open_pluto() = begin
    
    if isfile(pluto_secret_file)
        secret = open(pluto_secret_file, "r") do f
            strip(String(read(f)))
        end
    else
        return nothing
    end

    for port in 1234:1250
        pluto_entry = "http://localhost:$(port)/?secret=$(secret)"
        pluto_ping = "http://localhost:$(port)/ping"

        sock = try
            listen(port)
        catch e 
        end

        sock isa Sockets.TCPServer && close(sock)
        
        if sock == nothing && try 
            String(HTTP.request(
                "GET", pluto_ping; connect_timeout=1, readtimeout=1, retry=false, redirect=false
            ).body)
        catch e end == "OK!" && try
            HTTP.request(
                "GET", pluto_entry; connect_timeout=1, readtimeout=1, retry=false, redirect=false
                ).status
        catch e end == 200
            return pluto_entry
        end
    end
end


if length(ARGS) == 1 && lowercase(ARGS[1]) == "--help"
    println("Usage: pluto filename.jl")
    println("Usage: pluto --kwarg1 val1 --kwarg2 val2 ...")
    println()
    println("The available kwargs to Pluto isn't straight-forward and more tailored towards developers.")
    println("The full kwargs configuration logic for Pluto is available here:")
    println("  https://github.com/fonsp/Pluto.jl/blob/master/src/Configuration.jl")
    exit()
end

kwargs = Dict{Symbol, Any}()

if length(ARGS) == 1
    kwargs[:notebook] = ARGS[1]
elseif length(ARGS)%2 != 0
    error("Commandline arguments must come in pairs, like --foo 1 --bar 2")
end

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

plutourl = if keys(kwargs) in [keys(Dict(:notebook=>0)), keys(Dict())]
    get_open_pluto()
end


if plutourl === nothing
    # Open new instance of Pluto

    using Pluto
    options = Pluto.Configuration.from_flat_kwargs(; kwargs...)
    session = Pluto.ServerSession(;options=options)
    session.secret = String(rand(union('a':'z', 'A':'Z', '0':'9'), 8))

    try
        open(pluto_secret_file, "w") do f
            write(f, session.secret)
        end
    catch e end

    try
        Pluto.run(session)
    finally
        rm(pluto_secret_file)
    end
else
    # Open Old instance of Pluto directly

    if haskey(kwargs, :notebook) # open a file
        plutourl = replace(plutourl, "?secret=" => "open?path=$(kwargs[:notebook])&secret=")
    end

    Base.run(`powershell.exe Start "'$plutourl'"`)
end