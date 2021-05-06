@echo off
if not exist "%~dp0..\vendor\tcc\tcc.exe" (
    "%~dp0\bootstrapped-julia.cmd" -e "include(raw\"%~dp0\routines.jl\"); install_tcc()"
)

"%~dp0..\vendor\tcc\tcc.exe" %*