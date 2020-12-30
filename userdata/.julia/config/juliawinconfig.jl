# Force libgit2 to download packages in stead of downloading tarballs
ENV["PYTHON"] = ""
ENV["JULIA_PKG_SERVER"] = ""

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

# Juliawin uses curl as the default downloader
if Sys.iswindows()
    # Add curl from packages to path
    for i=1 #to keep scope clear
        packagedir = abspath(String(@__DIR__)*raw"/../../../packages")
        curlpackages = [i for i in readdir(packagedir) if startswith(i, "curl")]
        if length(curlpackages)>0
            ENV["PATH"] = abspath(packagedir*"/"*curlpackages[1]*"/bin")*";"*ENV["PATH"]
        end
    end

    # Make use of curl and overwrite download_powershell for stubborn libraries.
    if Sys.which("curl") !== nothing
        ENV["BINARYPROVIDER_DOWNLOAD_ENGINE"] = "curl"

        # try to overwrite download_powershell
        try
	        Base.download_powershell(url::AbstractString, filename::AbstractString) = Base.download_curl(Sys.which("curl"), url, filename)
	        download = Base.download
		catch x
		    if !isa(x, LoadError) && !isa(x, UndefVarError)
		        throw(x)
		    end
		end
    end

end
