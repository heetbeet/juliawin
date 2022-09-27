@echo off

call "%~dp0\activate-juliawin-environment.bat"
goto #_undefined_# 2>NUL || title %~n0 & call "%~dp0\execute-with-juliawin-sh.bat" "%juliawin_packages%\julia\bin\juliaup.exe" %*