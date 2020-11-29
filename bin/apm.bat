@echo off
setlocal

call "%~dp0\..\internals\scripts\set-juliawin-environment.bat"
call "%juliawin_packages%\atom\resources\cli\apm.cmd" %*
exit /b %errorlevel%
