@echo off
pushd "%~dp0"

call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\IJulia-lab.ico      /output ..\IJulia-lab.exe
call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\IJulia-notebook.ico /output ..\IJulia-notebook.exe
call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\julia.ico           /output ..\julia.exe
call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\julia-vscode.ico    /output ..\julia-vscode.exe
call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\juliawin-prompt.ico /output ..\juliawin-prompt.exe
call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\juno.ico            /output ..\juno.exe
call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\pluto.ico           /output ..\pluto.exe
call "%~dp0\create-exe-launcher.cmd" /icon ..\artifacts\icons\python.ico          /output ..\python.exe

popd