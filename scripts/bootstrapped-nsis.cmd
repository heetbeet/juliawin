@echo off
if not exist "%~dp0..\vendor\nsis\App\NSIS\NSIS.exe" (
    call "%~dp0\bootstrapped-julia.cmd" -e "include(raw\"%~dp0\routines.jl\"); install_tcc()"
)

call "%~dp0..\vendor\nsis\App\NSIS\NSIS.exe" %*
exit /b %errorlevel%