@echo off
setlocal EnableDelayedExpansion

set "no-shell=0"
set "icon="
set "output="

if /i "%~1" equ "/no-shell" set "no-shell=1"
if /i "%~2" equ "/no-shell" set "no-shell=1"
if /i "%~3" equ "/no-shell" set "no-shell=1"
if /i "%~4" equ "/no-shell" set "no-shell=1"


if /i "%~1" equ "/icon" set "icon=%~2"
if /i "%~2" equ "/icon" set "icon=%~3"
if /i "%~3" equ "/icon" set "icon=%~4"
if /i "%~4" equ "/icon" set "icon=%~5"


if /i "%~1" equ "/output" set "output=%~2"
if /i "%~2" equ "/output" set "output=%~3"
if /i "%~3" equ "/output" set "output=%~4"
if /i "%~4" equ "/output" set "output=%~5"


set "show-help=0"
if "%~1%~2%~3%~4%~5%~6%~7" equ "" set "show-help=1"
if "%icon%" equ "" set "show-help=1"
if "%output%" equ "" set "show-help=1"
if /i "%~1" equ "/h" set "show-help=1"


if "%show-help%" equ "1" (
  echo Usage: %~n0 [/no-shell] /icon ^<path-to-icon^> /output ^<path-to-output^>
  exit /b 1
)


set "exe=%~dp0\..\artifacts\launchers\create-exe-launcher-template.exe"
set "exe-noshell=%~dp0\..\artifacts\launchers\create-exe-launcher-template-noshell.exe"

if exist "%exe%" if exist "%exe-noshell%" (
   set "compile=0"
)

if "%compile%" neq "0" (
  mkdir "%exe%\.." > nul 2>&1
  call "%~dp0\bootstrapped-tcc.cmd" -w -D_UNICODE  "%~dp0\create-exe-launcher-template.c" -luser32 -lkernel32 -o "%exe%"
  call "%~dp0\bootstrapped-tcc.cmd" -w -D_UNICODE -DNOSHELL "%~dp0\create-exe-launcher-template.c" -luser32 -lkernel32 -mwindows -o "%exe-noshell%"
)

if "%no-shell%" equ "1" (
  echo F | xcopy /s/Y "%exe-noshell%" "%output%" > nul
) else (
  echo F | xcopy /s/Y "%exe%" "%output%" > nul
)

call "%~dp0\bootstrapped-rcedit.cmd" "%output%" --set-icon "%icon%"