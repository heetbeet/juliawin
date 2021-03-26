@echo off
setlocal

call "%~dp0..\..\bin\activate-juliawin-environment.bat"

if exist "%juliawin_home%\(julia.exe)" (
    call :REMOVE-BRACKETS-FROM-EXECUTABLES
) else if exist "%juliawin_home%\julia.exe" (
    call :ADD-BRACKETS-TO-EXECUTABLES
)


:: Some executables must remain active
move "%juliawin_home%\(Juliawin Setup.exe)" "%juliawin_home%\Juliawin Setup.exe" > nul 2>&1
move "%juliawin_home%\bin\(Juliawin Setup.bat)" "%juliawin_home%\bin\Juliawin Setup.bat" > nul 2>&1
move "%juliawin_home%\bin\(activate-juliawin-environment.bat)" "%juliawin_home%\bin\activate-juliawin-environment.bat" > nul 2>&1
move "%juliawin_home%\bin\(activate-juliawin-portability.bat)" "%juliawin_home%\bin\activate-juliawin-portability.bat" > nul 2>&1
move "%juliawin_home%\bin\(activate-juliawin-sh-path.bat)" "%juliawin_home%\bin\activate-juliawin-sh-path.bat" > nul 2>&1
move "%juliawin_home%\bin\(execute-with-juliawin-sh.bat)" "%juliawin_home%\bin\execute-with-juliawin-sh.bat" > nul 2>&1
move "%juliawin_home%\bin\(Juliawin Bootstrap From Github.bat)" "%juliawin_home%\bin\Juliawin Bootstrap From Github.bat" > nul 2>&1
move "%juliawin_home%\bin\(Juliawin Bootstrap From Github.exe)" "%juliawin_home%\bin\Juliawin Bootstrap From Github.exe" > nul 2>&1

goto :eof


:: ***************************************
:: Add brackets to all juliawin executables
:: ***************************************
:ADD-BRACKETS-TO-EXECUTABLES
	for /f "delims=" %%i in ('dir /b /a-d-h-s "%juliawin_home%"') do call :ADD-BRACKET "%juliawin_home%\%%i"
	for /f "delims=" %%i in ('dir /b /a-d-h-s "%juliawin_home%\bin"') do call :ADD-BRACKET "%juliawin_home%\bin\%%i"
goto :eof


:: ***************************************
:: Remove brackets from all juliawin executables
:: ***************************************
:REMOVE-BRACKETS-FROM-EXECUTABLES
	for /f "delims=" %%i in ('dir /b /a-d-h-s "%juliawin_home%"') do call :REMOVE-BRACKET "%juliawin_home%\%%i"
	for /f "delims=" %%i in ('dir /b /a-d-h-s "%juliawin_home%\bin"') do call :REMOVE-BRACKET "%juliawin_home%\bin\%%i"
goto :eof


:: ***************************************
:: Sourrounds a filename in brackets to remove executability
:: ***************************************
:ADD-BRACKET <path>
	if /i "%~x1" equ ".bat" goto :doadd
	if /i "%~x1" equ ".exe" goto :doadd
	goto :eof

	:doadd
		move "%~1" "%~dp1\(%~nx1)" > nul

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
		move "%~1" "%~dp1\%filename%" > nul
	
goto :eof

