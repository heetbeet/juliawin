@echo off
if not exist "%~dp0..\vendor\innounp\innounp.exe" (
    call "%~dp0\bootstrapped-julia.cmd" -e "include(raw\"%~dp0\routines.jl\"); install_innounp()"
)

call "%~dp0..\vendor\innounp\innounp.exe" %*
exit /b %errorlevel%