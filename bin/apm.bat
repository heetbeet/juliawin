@echo off
SETLOCAL

call "%~dp0\set-juliawin-environment.bat"
call "%juliawin_packages%\atom\resources\cli\apm.cmd" %*
exit /b %errorlevel%
