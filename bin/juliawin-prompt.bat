@echo off

call "%~dp0\activate-juliawin-environment.bat"

:: Activate Conda if installed
if exist "%juliawin_packages%\conda\Scripts\activate.bat" (
    call "%juliawin_packages%\conda\Scripts\activate.bat"
)

:: If not parameters provided, open prompts, otherwise `run` the arguments directly
if "%~1%~2%~3%~4%~5%~6%~7%~8%~9" equ "" (
    goto #_undefined_# 2>NUL || title %~n0 & call cmd
) else (
    goto #_undefined_# 2>NUL || title %~n0 & call %*
)
