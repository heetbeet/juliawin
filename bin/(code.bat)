@echo off
setlocal

call "%~dp0\..\internals\scripts\set-juliawin-environment.bat"
call "%juliawin_packages%\vscode\code.exe" --user-data-dir "%juliawin_packages%\vscode\data\user-data" --extensions-dir "%juliawin_packages%\vscode\data\extensions" %*
exit /b %errorlevel%