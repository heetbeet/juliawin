import os
import sys

thisdir = os.path.dirname(os.path.abspath(__file__))

#Fill the template with actual code
template = open(f"{thisdir}/bat-python-julia-template.txt").read()

bat = open(f"{thisdir}/julia-win-installer.bat").read()
julia = open(f"{thisdir}/julia-win-installer.jl").read()
python = open(f"{thisdir}/julia-win-installer.py").read()

output = (template.replace("__bat__", bat)
                  .replace("__julia__", julia)
                  .replace("__python__", python))

#Cheating: replace juliafile and pythonfile to have bat file extension
output = (output.replace("juliafile=%~dp0%~n0.jl", "juliafile=%~dp0%~n0.bat")
				.replace("juliafile=%~dp0%~n0.py", "juliafile=%~dp0%~n0.bat"))

#Write the full script to the output
open(f"{thisdir}/../julia-win-installer.bat", "w").write(output)