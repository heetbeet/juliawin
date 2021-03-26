@echo off
setlocal

call "%~dp0\activate-juliawin-environment.bat"
"%~dp0\execute-with-juliawin-sh.bat" "%juliawin_packages%\vscode\bin\code.cmd" --user-data-dir "%juliawin_userdata%\.vscode\data\user-data" --extensions-dir "%juliawin_userdata%\.vscode\extensions" %*
exit /b %errorlevel%
