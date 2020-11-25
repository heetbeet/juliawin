@echo off
SETLOCAL

call "%~dp0\set-juliawin-environment.bat"
call "%juliawin_packages%\atom\atom.exe" %*
exit /b %errorlevel%
