@echo off

goto #_undefined_# 2>NUL || title %~n0 & call "%~dp0\..\packages\7z\bin\7z.exe" %*