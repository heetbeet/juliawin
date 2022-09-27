# Force libgit2 to download packages in stead of downloading tarballs
ENV["PYTHON"] = ""


# Force installation of packages
for _ in true
    function lazy_add(pkgsym)
        # TODO: false positives from `]activate ...` and `]add PackageName`
        if !(isdir(joinpath(@__DIR__, "..", "packages", String(pkgsym))))
            @eval using Pkg
            Pkg.add(String(pkgsym))
        end
    end

    lazy_add(:Revise)
    lazy_add(:OhMyREPL)
    lazy_add(:HTTP) # Used by Pluto.exe
end


# Force installation and inclusion of packages at REPL
Base.atreplinit() do _
    function add_and_use(pkgsym)
        try
            @eval using $pkgsym
            return true
        catch e
            @eval using Pkg
            Pkg.add(String(pkgsym))
            @eval using $pkgsym
        end
    end

    add_and_use(:Revise)
    #add_and_use(:OhMyREPL)
end
