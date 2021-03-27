:: This procedure wil locate the `sh.exe` that comes bundles with git and store it as %juliwin_sh%
@echo off

call :GET-PATH-TO-GIT-SH juliawin_sh
goto :eof


:: ***************************************************
:: Search the regular Git places for a path to sh.exe
:: **************************************************
:GET-PATH-TO-GIT-SH <path>
    set "%~1="

    :: Is sh in expected juliawin directory?
    if exist "%~dp0..\packages\git\bin\sh.exe" (
        set "%~1=%~dp0..\packages\git\bin\sh.exe"
        goto :eof
    )

    :: Is sh in expected git installation directory?
    if exist "%PROGRAMFILES%\Git\bin\sh.exe" (
        set "%~1=%PROGRAMFILES%\Git\bin\sh.exe"
        goto :eof
    )

    :: Is sh in another expected git installation directory?
    if exist "%PROGRAMFILES(x86)%\Git\bin\sh.exe" (
        set "%~1=%PROGRAMFILES(x86)%\Git\bin\sh.exe"
        goto :eof
    )

    :: Is sh in path and is it part of Git+MinGW?
    FOR /F "tokens=* USEBACKQ" %%I IN (`where sh 2^>nul`) do (
        if exist "%%I\..\..\cmd\git.exe" (
            set "%~1=%%I"
            goto :eof
        )
    )

    :: Is git in path and does it have a sh companion?
    FOR /F "tokens=* USEBACKQ" %%I IN (`where git 2^>nul`) do (
        if exist "%%I\..\..\bin\sh.exe" (
            set "%~1=%%I\..\..\bin\sh.exe"
            goto :eof
        )
    )
goto :eof