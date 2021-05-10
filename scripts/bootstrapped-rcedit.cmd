@echo off
if not exist "%~dp0..\vendor\rcedit\rcedit.exe" (
    call "%~dp0\bootstrapped-julia.cmd" -e "include(raw\"%~dp0\routines.jl\"); install_rcedit()"
)

call "%~dp0..\vendor\rcedit\rcedit.exe" %*
exit /b %errorlevel%