@echo off
setlocal

call "%~dp0\activate-juliawin-environment.bat"
"%~dp0\execute-with-juliawin-sh.bat" "%juliawin_packages%\julia\bin\julia.exe" %*
exit /b %errorlevel%