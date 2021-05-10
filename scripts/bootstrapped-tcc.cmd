@echo off
if not exist "%~dp0..\vendor\tcc\tcc.exe" (
    call "%~dp0\bootstrapped-julia.cmd" -e "include(raw\"%~dp0\routines.jl\"); install_tcc()"
)

call "%~dp0..\vendor\tcc\tcc.exe" %*
exit /b %errorlevel%