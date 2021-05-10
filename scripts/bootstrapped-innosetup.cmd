@echo off
if not exist "%~dp0..\vendor\innosetup\Compil32.exe" (
    call "%~dp0\bootstrapped-julia.cmd" -e "include(raw\"%~dp0\routines.jl\"); install_inno()"
)

call "%~dp0..\vendor\innosetup\Compil32.exe" %*
exit /b %errorlevel%


