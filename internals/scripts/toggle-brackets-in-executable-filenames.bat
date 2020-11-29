@echo off
setlocal

call "%~dp0set-juliawin-environment.bat"

if exist "%juliawin_home%\(julia.exe)" call :REMOVE-BRACKETS-FROM-EXECUTABLES
else if exist "%juliawin_home%\julia.exe" call :ADD-BRACKETS-TO-EXECUTABLES

goto :eof


:: ***************************************
:: Add brackets to all juliawin executables
:: ***************************************
:ADD-BRACKETS-TO-EXECUTABLES
	for /r %%i in ("%juliawin_home%") do call :ADD-BRACKET %%i
	for /r %%i in ("%juliawin_home%\bin") do call :ADD-BRACKET %%i
goto :eof


:: ***************************************
:: Remove brackets from all juliawin executables
:: ***************************************
:REMOVE-BRACKETS-FROM-EXECUTABLES
	for /r %%i in ("%juliawin_home%") do call :REMOVE-BRACKET %%i
	for /r %%i in ("%juliawin_home%\bin") do call :REMOVE-BRACKET %%i
goto :eof


:: ***************************************
:: Sourrounds a filename in brackets to remove executability
:: ***************************************
:ADD-BRACKET <path>
	if /i "%~x1" equ ".bat" goto :doadd
	if /i "%~x1" equ ".exe" goto :doadd
	goto :eof

	:doadd
		move "%~1" "%~dp1\(%~nx1)"

goto :eof


:: ***************************************
:: Remove sourrounding brackets to allow executability
:: ***************************************
:REMOVE-BRACKET <path>
	if /i "%~x1" equ ".bat)" goto :doremove
	if /i "%~x1" equ ".exe)" goto :doremove
	goto :eof

	:doremove
		set "filename=%~nx1"
		set "filename=%filename:~1,-1%"
		move "%~1" "%~dp1\%filename%"
	
goto :eof

