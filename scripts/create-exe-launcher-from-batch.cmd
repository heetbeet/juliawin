@echo off
setlocal EnableDelayedExpansion

set "input="
set "icon="
set "output="

if /i "%~1" equ "/input" set "input=%~2"
if /i "%~2" equ "/input" set "input=%~3"
if /i "%~3" equ "/input" set "input=%~4"
if /i "%~4" equ "/input" set "input=%~5"
if /i "%~5" equ "/input" set "input=%~6"
if /i "%~6" equ "/input" set "input=%~7"


if /i "%~1" equ "/icon" set "icon=%~2"
if /i "%~2" equ "/icon" set "icon=%~3"
if /i "%~3" equ "/icon" set "icon=%~4"
if /i "%~4" equ "/icon" set "icon=%~5"
if /i "%~5" equ "/icon" set "icon=%~6"
if /i "%~6" equ "/icon" set "icon=%~7"


if /i "%~1" equ "/output" set "output=%~2"
if /i "%~2" equ "/output" set "output=%~3"
if /i "%~3" equ "/output" set "output=%~4"
if /i "%~4" equ "/output" set "output=%~5"
if /i "%~5" equ "/output" set "output=%~6"
if /i "%~6" equ "/output" set "output=%~7"

set "show-help=0"
if "%~1%~2%~3%~4%~5%~6%~7" equ "" set "show-help=1"
if "%input%" equ "" set "show-help=1"
if "%output%" equ "" set "show-help=1"
if /i "%~1" equ "/h" set "show-help=1"


if "%show-help%" equ "1" (
  echo Usage: %~n0 /input ^<path-to-batch-file^> [/icon ^<path-to-icon^>] /output ^<path-to-output^>
  exit /b 1
)


::***************************************************************
:: This is really ugly, but I was too lazy to code this in Julia
::**************************************************************

:: First sanitise the input batch file, then inject it into the template
::batchscript = batchscript.replace("\\", "\\\\")
::batchscript = batchscript.replace("\n", r"\n")
::batchscript = batchscript.replace('"',  r'\"')

echo F | xcopy /s/Y "%input%" "%output%.c" > nul
PowerShell -Command "[regex]::Replace([string]::Join(\"`n\", (Get-Content '%output%.c')), '\\', '\\\', 'Singleline')" > "%output%"
PowerShell -Command "[regex]::Replace([string]::Join(\"`n\", (Get-Content '%output%')), \"`n\", '\r\n', 'Singleline')" > "%output%.c"
PowerShell -Command "[regex]::Replace([string]::Join(\"`n\", (Get-Content '%output%.c')), '\"', '\\\"', 'Singleline')" > "%output%"
PowerShell -Command "[regex]::Replace([string]::Join(\"`n\", (Get-Content '%~dp0\create-exe-launcher-from-batch-template.c')), '__batchscript__', (Get-Content '%output%'), 'Singleline')" > "%output%.c"

call "%~dp0\bootstrapped-tcc.cmd" -w -D_UNICODE  "%output%.c" -luser32 -lkernel32 -o "%output%"

if "%icon%" neq "" (
    call "%~dp0\bootstrapped-rcedit.cmd" "%output%" --set-icon "%icon%"
)

powershell -Command "Remove-Item -Path '%output%.c' -Force"
