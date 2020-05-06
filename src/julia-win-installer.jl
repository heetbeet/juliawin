juliatemp = joinpath(tempdir(), "juliawin")
installdir = strip(read(open(joinpath(juliatemp, "installdir.txt")), String))
thisfile = strip(read(open(joinpath(juliatemp, "thisfile.txt")), String))
runroutine = ARGS[1]

#=
Same method as the bat equivalent
=#
function get_dl_url(url, domatch, notmatch=nothing, prefix="")
	urlslug = replace(url, "/"=>"-")
	urlslug = replace(urlslug, ":"=>"")
	lnkpath = joinpath(juliatemp, urlslug)
	download(url, lnkpath)
	println(lnkpath)
	open(lnkpath) do file
		pagecontent = read(file, String)
		for line in split(pagecontent, "\"") #"
			if match(domatch, ""*line) != nothing
				if notmatch==nothing || match(notmatch, ""*line) == nothing
					return prefix*line
				end
			end
		end
	end
end

function download_asset(dlurl)
	path = joinpath(juliatemp, split(dlurl, "/")[end])
	println("() Downloading $dlurl to")
	println("() $path, this may take a while")
	download(dlurl, path)
	return path
end


function extract_file(archive, destdir, fixdepth=true)
	mkpath(destdir)
	if Sys.iswindows()
    	run(`7z x -y "-o$destdir" "$archive"`)
	else
    	if endswith(lowercase(archive), ".tar.gz")
            	run(`tar -xzf "$archive" -C "$destdir"`)
    	elseif endswith(lowercase(archive), ".tar")
            	run(`tar -xf "$archive" -C "$destdir"`)
        else
            error("unimplemented")
        end 
    end
    
	if fixdepth
		dirs = filter(x -> isdir(joinpath(destdir, x)), readdir(destdir))
		if length(dirs) == 1
			tmpdest = destdir*"--resolve-depth"
			mv(destdir, tmpdest, force=true)
			mv(joinpath(tmpdest,dirs[1]), destdir, force=true)
			rm(tmpdest, force=true, recursive=true)
		end
	end
end


if runroutine == "HELLO-WORLD"

	println("() Hello World")

end

if runroutine == "INSTALL-ATOM"
    
    if Sys.iswindows()
        dlreg = r"/atom/atom/.*x64.*zip"
    else #linux
        dlreg = r"/atom/atom/.*amd64.*tar.gz"
    end
    
	#https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
	atomurl = get_dl_url("https://github.com/atom/atom/releases",
						dlreg,
						r"-beta",
						"https://github.com/")
	atomzip = download_asset(atomurl)

	extract_file(atomzip, joinpath(installdir, "atom"))
	mkpath(joinpath(installdir, ".atom"))

end

if runroutine == "INSTALL-JUNO"

    if Sys.iswindows()
        apmbin = "apm.cmd"
    else #linux
        apmbin = "apm"
    end
    
	#https://github.com/atom/atom/releases/download/v1.45.0/atom-x64-windows.zip
	#make apm available as .bat as well
	run(`$apmbin install language-julia`)
	run(`$apmbin install julia-client`)
	run(`$apmbin install ink`)
	run(`$apmbin install uber-juno`)
	run(`$apmbin install latex-completions`)
	run(`$apmbin install indent-detective`)
	run(`$apmbin install hyperclick`)
	run(`$apmbin install tool-bar`)

	using Pkg;
	Pkg.add("Atom")
	Pkg.add("Juno")
end


if runroutine == "INSTALL-JUPYTER"
	using Pkg
	Pkg.add("PyCall")
	Pkg.add("IJulia")
	Pkg.add("Conda")

	using Conda
	Conda.add("jupyter")
	Conda.add("jupyterlab")

	Pkg.add("PyPlot")
end


if runroutine == "MAKE-BATS"
	mkpath(joinpath(installdir, "scripts"))

	juliawinenviron=raw"""
		@echo off
		__setpath__

		set "JULIA_DEPOT_PATH=%~dp0..\.julia"
		set "ATOM_HOME=%~dp0..\.atom"
		"""

	battemplate=raw"""
		@echo off
		SETLOCAL
		call %~dp0\juliawin-environment.bat

		__exec__

		exit /b %errorlevel%
		"""

	paths = raw"""
		julia\bin
		atom
		atom\resources\cli
		""" |> split

	pathsbat = join(["""SET "PATH=%~dp0..\\$path;%PATH%" """ for path in paths], "\n")
	juliawinenviron = replace(juliawinenviron, "__setpath__"=>pathsbat)
	open(joinpath(installdir,"scripts","juliawin-environment.bat"), "w") do f
		write(f, juliawinenviron)
	end

	exts = ".exe .bat .cmd .vbs .vbe .js .msc" |> split
	files = Dict{String, String}()
	for path in paths
		println(path)
		for file in readdir(joinpath(installdir, path))
			#make sure exe > others
			(name, ext) = splitext(file)
			if ext == ".exe"
				files[name] = joinpath(path, file)
			end
			if ! haskey(files, name) && ext in exts
				files[name] = joinpath(path, file)
			end
		end
	end

	for (name, path) in files
		battxt = replace(battemplate, "__exec__"=>"call \"%~dp0\\..\\$path\" %*")
		open(joinpath(installdir,"scripts",name*".bat"), "w") do f
			write(f, battxt)
		end
	end

	#Custom one for atom, since atom can't be next to julia.bat (why???)
	open(joinpath(installdir,"scripts","atom.bat"), "w") do f
		(name, path) = ("atom", files["atom"])

		battxt = replace(battemplate, "__exec__"=> """

			::for some reason juno hates (!!!) being next to julia.bat
			set "curdir=%~dp0"
			set "curdir=%curdir:~0,-1%"
			if /i "%cd%" EQU "%curdir%" cd ..\\atom

			call \"%~dp0\\..\\$path\" %*
			""")

		write(f, battxt)
	end

	open(joinpath(installdir, "scripts", "noshell.vbs"), "w") do f
		quadstr = "\"\"\"\""
		write(f, """
		If WScript.Arguments.Count >= 1 Then
		    ReDim arr(WScript.Arguments.Count-1)
		    For i = 0 To WScript.Arguments.Count-1
		        Arg = WScript.Arguments(i)
		        If InStr(Arg, " ") > 0 Then Arg = $quadstr & Arg & $quadstr
		      arr(i) = Arg
		    Next

		    RunCmd = Join(arr)
		    CreateObject("Wscript.Shell").Run RunCmd, 0, True
		End If
		""")
	end

	open(joinpath(installdir,"julia.bat"),"w") do f
		write(f, raw"""
		@echo off
		call %~dp0\scripts\julia.bat %*
		exit /b %errorlevel%
		"""
		)
	end

	open(joinpath(installdir,"IJulia-Lab.bat"),"w") do f
		write(f, raw"""
		@echo off
		call %~dp0\scripts\julia.bat -e "using IJulia; jupyterlab()"
		exit /b %errorlevel%
		"""
		)
	end

	open(joinpath(installdir,"IJulia-Notebook.bat"),"w") do f
		write(f, raw"""
		@echo off
		call %~dp0\scripts\julia.bat -e "using IJulia; notebook()"
		exit /b %errorlevel%
		"""
		)
	end

	open(joinpath(installdir,"atom.bat"),"w") do f
		write(f, raw"""
		@echo off

		::for some reason juno hates (!!!) being next to julia.bat
		set "curdir=%~dp0"
		set "curdir=%curdir:~0,-1%"
		if /i "%cd%" EQU "%curdir%" cd atom

		start "" "%~dp0\scripts\noshell.vbs" "%~dp0\scripts\atom.bat" %*
		exit /b %errorlevel%
		"""
		)
	end

end


if runroutine == "MAKE-BASHES"
    mkpath(joinpath(installdir, "scripts"))
    mkpath(joinpath(installdir, "bin"))
    
    
    bash_template = """
    #--------------------------------------------------
    # I might be a symlink, so here is my actual location
    #--------------------------------------------------
    #From https://stackoverflow.com/a/246128
    SOURCE="\${BASH_SOURCE[0]}"
    while [ -h "\$SOURCE" ]; do # resolve \$SOURCE until no longer a symlink
      DIR="\$( cd -P "\$( dirname "\$SOURCE" )" && pwd )"
      SOURCE="\$(readlink "\$SOURCE")"
      # if SOURCE was a relative symlink, we need to resolve it relative to the
      # path where the symlink file was located
      [[ \$SOURCE != /* ]] && SOURCE="\$DIR/\$SOURCE" 
    done
    DIR="\$( cd -P "\$( dirname "\$SOURCE" )" && pwd )"
    
    #--------------------------------------------------
    # Setup the environment variables and paths for Juliawin
    #--------------------------------------------------
    __environmentcode__
    
    #--------------------------------------------------
    # Finally, run this binary please
    #--------------------------------------------------
    __execution__
    exit \$?
    """


	paths = raw"""
		julia/bin
		atom
		atom/resources/app/apm/bin
		""" |> split
    
    
    paths_bashed = join(
        ["""PATH=\$DIR/path:\$PATH""" for path in paths], "\n"
    )
    
    
    bash_environment = """
    #--------------------------------------------------
    # Base directory
    #--------------------------------------------------
    SOURCE="\${BASH_SOURCE[0]}"
    DIR="\$( cd -P "\$( dirname "\$SOURCE" )" && pwd )"

    #--------------------------------------------------
    # Add to Path
    #--------------------------------------------------    
    $paths_bashed
    
    #--------------------------------------------------
    # Add env. variables
    #--------------------------------------------------       
    JULIA_DEPOT_PATH=\$DIR+'/../.julia'
    ATOM_HOME=\$DIR+'/../.atom'    
    """
    
    open(joinpath(installdir,"scripts","juliawin-environment"), "w") do f
		write(f, bash_environment)
	end


    #Collect all executables
	files = Dict{String, String}()
	for path in paths
		for file in readdir(joinpath(installdir, path))
    		absfile = joinpath(installdir, path, file)
			if endswith(absfile, ".so") || endswith(absfile, ".o")
    			continue
    		end
    		
			#test if file is executable with ls
			if occursin("x", split(read(`ls -l "$absfile"`, String))[1])
               files[file] = joinpath(path, file)
            end
		end
	end

    
    #Make all shadow executables
	for (name, file) in files
    	println(file)
		bash_txt = replace(bash_template, 
    		"__execution__"=>
    		""""\$DIR/../$file" "\$@" """
		)
		
		bash_txt = replace(bash_txt, 
    		"__environmentcode__"=>". \$DIR/juliawin-environment"
		)
		
		bash_txt = bash_txt * "\necho \$DIR"
		
		absout = joinpath(installdir, "scripts", name)
		open(absout, "w") do f
			write(f, bash_txt)
		end
		run(`chmod +x "$absout"`)
	end
	
    #List of hand-picked custom executables
	open(joinpath(installdir, "bin", "julia"),"w") do f
        bash_txt = replace(replace(
                                bash_template,
                                "__execution__"=>
                                """"\$DIR/../scripts/julia" "\$@" """),
                           "__environmentcode__"=>"")
        write(f, bash_txt)
        run(`chmod +x "$(joinpath(installdir,"bin","julia"))"`)
	end


	open(joinpath(installdir,"bin","atom"),"w") do f
        bash_txt = replace(replace(
                                bash_template,
                                "__execution__"=>
                                """"\$DIR/../scripts/atom" "\$@" """),
                           "__environmentcode__"=>"")
        write(f, bash_txt)
        run(`chmod +x "$(joinpath(installdir,"bin","atom"))"`)
    end
    
    
	open(joinpath(installdir,"bin","IJulia-Lab"),"w") do f
        bash_txt = replace(replace(
                                bash_template,
                                "__execution__"=>
                                """"\$DIR/../scripts/julia" -e "using IJulia; jupyterlab()" """),
                           "__environmentcode__"=>"")
        write(f, bash_txt)
        run(`chmod +x "$(joinpath(installdir,"bin","IJulia-Lab"))"`)
	end


	open(joinpath(installdir,"bin","IJulia-Notebook"),"w") do f
        bash_txt = replace(replace(
                                bash_template,
                                "__execution__"=>
                                """"\$DIR/../scripts/julia" -e "using IJulia; notebook()" """),
                           "__environmentcode__"=>"")
        write(f, bash_txt)
        run(`chmod +x "$(joinpath(installdir,"bin","IJulia-Notebook"))"`)
	end



end