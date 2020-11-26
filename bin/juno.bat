@echo off
SETLOCAL

call "%~dp0\atom.bat" %*
exit /b %errorlevel%
