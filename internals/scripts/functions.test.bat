@echo off
setlocal

:: From here on forth we can use the bundles frunctions from our repo
set searchpaths=.;includes;..\includes;tools\deploy-scripts\includes;..\tools\deploy-scripts\includes
for %%a in ("%searchpaths:;=" "%") do (
    if exist "%~dp0%%~a\functions.bat" set func="%~dp0%%~a\functions.bat"
)

echo *** Start tests ***

call %func% ARG-PARSER /a a /b /c c1 c2
call %func% TEST-OUTCOME "%ARG_A% %ARG_B% %ARG_C% %ARG_C_1% %ARG_C_2%" "a 1 c1 c1 c2" "Argument parsing"


call %func% NO-TRAILING-SLASH result "c:\hello\"
call %func% TEST-OUTCOME "%result%" "c:\hello"



call %func% EXPAND-ASTERIX result "%~dp0\functions.t*"
call %func% FULL-PATH result2 "%~dp0\functions.test.bat"
call %func% TEST-OUTCOME "%result%" "%result2%" "Expand via asterix in name"


call %func% EXPAND-ASTERIX result "%~dp0\test\*"
call %func% TEST-OUTCOME "%result%" "" "Expand via asterix in name"


call %func% EXEC result err "echo hello world"
call %func% TEST-OUTCOME "%result%" "hello world" "Exec"
call %func% TEST-OUTCOME "%err%" "0" "Exec"


set "pathsave=%PATH%"
call %func% ADD-TO-PATH "%~dp0"
set "pathsave2=%PATH%"
call %func% TEST-OUTCOME "%~dp0;%pathsave%" "%pathsave2%"


::call %func% BOOTSTRAP-CURL "%TEMP%\curltemp"


call %func% REGISTER-DOWNLOAD-METHOD result
call %func% TEST-OUTCOME "%result%" "curl"

:: call %func% LOCAL-TIME result
:: echo %result%
:: call %func% LOCAL-DATE result
:: echo %result%
:: call %func% TIME-STAMP result
:: echo %result%

:: call %func% BROWSE-FOR-FOLDER return
:: echo %return%


call %func% TO-UPPER result hEllO
call %func% TEST-OUTCOME "%result%" "HELLO"


::call %func% EDIT-FILE-IN-NOTEPAD "%temp%\hello.txt"

::echo echo hello > "%temp%\echohello.bat"
::call %func% GET-SETTINGS-VIA-BAT-FILE "%temp%\echohello.bat"

set "tmpextract=%temp%\temp-%random%%random%"
call %func% EXTRACT-ZIP-WINDOWS "%~dp0\test.zip" "%tmpextract%"
if not exist "%tmpextract%\test.txt" (
	call %func% TEST-OUTCOME "" "Error in EXTRACT-ZIP-WINDOWS"
)

echo *** Complete tests ***
