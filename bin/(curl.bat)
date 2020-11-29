@echo off
SETLOCAL

call "%~dp0\..\internals\scripts\set-juliawin-environment.bat"
call "%juliawin_packages%\curl\bin\curl.exe" %*
exit /b %errorlevel%
