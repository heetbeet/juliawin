@echo off

set "batfile=%~dp0bin\%~n0.bat"
if exist "%batfile%" ( goto :filefound )

    powershell -command "[reflection.assembly]::LoadWithPartialName('System.Windows.Forms')|out-null;[windows.forms.messagebox]::Show('Could not execute: %batfile%', 'Execution error')"
    EXIT /B -1

:filefound

call "%batfile%" %*
EXIT /B %errorlevel%