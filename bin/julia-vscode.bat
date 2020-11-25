@echo off
SETLOCAL
call %~dp0\juliawin-environment.bat

call :EXPAND-FULLPATH execpath "%~dp0..\packages\vscode-x6*" ""
call "%execpath%\Code.exe" --user-data-dir="%~dp0..\userdata\.vscode" --extensions-dir="%~dp0..\userdata\.vscode\extensions" %*


exit /b %errorlevel%


goto :EOF

:: ***********************************************
:: Expand a asterix path to a full path
:: ***********************************************
:EXPAND-FULLPATH

    ::basename with asterix expansion
    set "_basename_="
    for /f "tokens=*" %%F in ('dir /b "%~2" 2^> nul') do set "_basename_=%%F"

    ::If asterix expansion failed, return ""
    if "%_basename_%" NEQ "" goto :continueexpand
        set "%~1="
        goto :EOF
    :continueexpand

    ::If success, return "path\expandable\with\asterix\optional\second\part"
    set "_path_=%~dp2%_basename_%"
    if "%~3" NEQ "" set "_path_=%_path_%\%~3"
    set "%~1=%_path_%"

goto :EOF

:: ***********************************************
:: Add a path to window's %PATH% (if exists)
:: ***********************************************
:ADD-TO-PATH

    call :EXPAND-FULLPATH _path_ "%~1" "%~2"
    if "%_path_%" NEQ "" set "PATH=%_path_%;%PATH%"

goto :EOF
