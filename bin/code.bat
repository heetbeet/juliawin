@echo off
SETLOCAL

call "%~dp0\set-juliawin-environment.bat"
call "%juliawin_packages%\vscode\code.exe" --user-data-dir "%juliawin_packages%\vscode\data\user-data" --extensions-dir "%juliawin_packages%\vscode\data\extensions" %*
exit /b %errorlevel%