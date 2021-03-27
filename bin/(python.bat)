@echo off
setlocal

call "%~dp0\activate-juliawin-environment.bat"
call "%juliawin_packages%\conda\Scripts\activate.bat"

"%juliawin_packages%\conda\python.exe" %*
exit /b %errorlevel%