@echo off
SETLOCAL

call "%~dp0\set-juliawin-environment.bat"
call "%juliawin_packages%\vscode\bin\code.cmd" %*
exit /b %errorlevel%
