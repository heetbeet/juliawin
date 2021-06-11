@echo off
setlocal

:: Read first line of file and sanitize it for testing
set plutoheader=xxx
if exist "%~1" (
    set /p plutoheader=<"%~1"
)
set plutoheader=%plutoheader:&=%
set plutoheader=%plutoheader:"=%

:: Dispatch to the correct program
if "%plutoheader%" equ "### A Pluto.jl notebook ###" (
    call "%~dp0\pluto.bat" %*
) else (
    call "%~dp0\julia.bat" %*
)
exit /b %errorlevel%