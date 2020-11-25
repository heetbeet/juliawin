@echo off
SETLOCAL

call "%~dp0\set-juliawin-environment.bat"
call "%juliawin_packages%\curl\bin\curl.exe" %*
exit /b %errorlevel%
