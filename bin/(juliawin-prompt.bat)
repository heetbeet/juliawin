@echo off
call "%~dp0\activate-juliawin-environment.bat"

:: Activate Conda if installed
if exist "%juliawin_packages%\conda\Scripts\activate.bat" (
    call "%juliawin_packages%\conda\Scripts\activate.bat"
)

:: If not parameters provided, open prompts, otherwise `run` the arguments directly
if "%~1%~2%~3%~4%~5%~6%~7%~8%~9" equ "" ( 
    if "%juliawin_sh%" neq "" (
        call "%juliawin_sh%"
    ) else (
        call cmd 
    )
) else (

    REM note that without "call", any exit will quit the whole chain
    "%~dp0\execute-with-juliawin-sh.bat" %*
)

exit /b %errorlevel%
