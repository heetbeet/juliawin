:: This procedure wil try to relocate Juliawin if the directory path has changed
:: Note! This batch file is dependant on activate-juliawin-environment.bat already been run
:: and its variables already added to the environmental variables list

@echo off
setlocal ENABLEDELAYEDEXPANSION

set "txt-save=%juliawin_userdata%\last-seen-path.txt"

set "last-seen-juliawin_home="
if exist "%txt-save%" (
    set /p last-seen-juliawin_home=<"%txt-save%"
)

set "build-errlevel=0"

set "jlp_fwd_slash=%juliawin_packages:\=/%"

if "%juliawin_home%" neq "%last-seen-juliawin_home%" (

    REM Rewrite qt configurations
    if exist "%juliawin_packages%\conda\qt.conf" (
        echo [Paths]>                                             "%juliawin_packages%\conda\qt.conf"
        echo Prefix = %jlp_fwd_slash%/conda/Library>>             "%juliawin_packages%\conda\qt.conf"
        echo Binaries = %jlp_fwd_slash%/conda/Library/bin>>       "%juliawin_packages%\conda\qt.conf"
        echo Libraries = %jlp_fwd_slash%/conda/Library/lib>>      "%juliawin_packages%\conda\qt.conf"
        echo Headers = %jlp_fwd_slash%/conda/Library/include/qt>> "%juliawin_packages%\conda\qt.conf"
        echo TargetSpec = win32-msvc>>                            "%juliawin_packages%\conda\qt.conf"
        echo HostSpec = win32-msvc>>                              "%juliawin_packages%\conda\qt.conf"
    )


    REM Delete compiled packages
    call %functions% DELETE-DIRECTORY "%juliawin_userdata%\.julia\compiled"  > nul 2>&1
    call %functions% DELETE-DIRECTORY "%juliawin_userdata%\.julia\conda"  > nul 2>&1
    call del "%juliawin_userdata%\.julia\prefs\IJulia" /f /q > nul 2>&1

    if exist "%juliawin_userdata%\.julia\packages\IJulia" (
        REM IJulia builds both Conda and IJulia

        start "" "%juliawin_splash%"
        call "%juliawin_packages%\julia\bin\julia.exe" -e "using Pkg; Pkg.build(\"PyCall\"); Pkg.build(\"IJulia\")"
        set "build-errlevel=!errorlevel!"

    ) else if exist "%juliawin_userdata%\.julia\packages\Conda" (
        REM Building Conda only

        start "" "%juliawin_splash%"
        call "%juliawin_packages%\julia\bin\julia.exe" -e "using Pkg; Pkg.build(\"PyCall\"); Pkg.build(\"Conda\");"
        set "build-errlevel=!errorlevel!"
    )
)

:: If no error doing IJulia+Conda or Conda compilation, only then update saved path
if "%build-errlevel%" equ "0" (
    echo %juliawin_home%>"%txt-save%"
) else (
    echo Error recompiling!
)