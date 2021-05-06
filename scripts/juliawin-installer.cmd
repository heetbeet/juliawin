@echo off
SETLOCAL EnableDelayedExpansion

:: ***************************************

:: ***************************************

if /i "%1" equ "/help" set "dohelp=1"
if /i "%1" equ "/h" set "dohelp=1"
if "%dohelp%" equ "1" (
    echo Script to download and run the Juliawin installer directly from Github
    echo:
    echo Usage:
    echo   "juliawin-installer.cmd" [options]
    echo Options:
    echo   /h, /help           Print these options
    echo   /skip-questions     Skip question prompt and banner
    exit /b 0
)


if /i "%1" neq "/skip-questions" if /i "%2" neq "/skip-questions" if /i "%3" neq "/skip-questions" if /i "%4" neq "/skip-questions" if /i "%5" neq "/skip-questions"  goto :skip-questions

echo  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^_^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
echo  ^ ^ ^ ^ ^_^ ^ ^ ^ ^ ^ ^ ^_^ ^_^(^_^)^_^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^_^ ^ ^ ^ ^ ^ ^ ^ ^|^ ^J^u^l^i^a^w^i^n^ ^c^o^m^m^a^n^d^l^i^n^e^ ^i^n^s^t^a^l^l^e^r
echo  ^ ^ ^ ^|^ ^|^ ^ ^ ^ ^ ^|^ ^(^_^)^ ^(^_^)^ ^ ^ ^ ^ ^ ^ ^ ^ ^(^_^)^ ^ ^ ^ ^ ^ ^ ^|^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
echo  ^ ^ ^ ^|^ ^|^_^ ^ ^ ^_^|^ ^|^_^ ^ ^_^_^ ^_^ ^_^_^ ^ ^ ^_^_^ ^_^ ^_^ ^_^_^ ^ ^ ^|^ ^G^i^t^H^u^b^.^c^o^m^/^h^e^e^t^b^e^e^t^/^j^u^l^i^a^w^i^n^ ^ 
echo  ^ ^ ^ ^|^ ^|^ ^|^ ^|^ ^|^ ^|^ ^|^/^ ^_^`^ ^|^'^/^ ^_^ ^\^'^|^ ^|^ ^'^_^ ^\^ ^ ^|^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
echo  ^ ^_^_^/^ ^|^ ^|^_^|^ ^|^ ^|^ ^|^ ^(^_^|^ ^|^ ^\^/^ ^\^/^ ^|^ ^|^ ^|^ ^|^ ^|^ ^|^ ^R^u^n^ ^w^i^t^h^ ^"^/^h^"^ ^f^o^r^ ^h^e^l^p^ ^ ^ ^ ^ ^ ^ ^ 
echo  ^|^_^_^_^/^ ^\^_^_^'^_^|^_^|^_^|^\^_^_^'^_^|^\^_^_^/^\^_^/^|^_^|^_^|^ ^|^_^|^ ^|^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
echo:


:: ***************************************
:: Ask questions about what to install
:: ***************************************
set "answer=R"
for %%r in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
    if /i "!answer!" equ "R" (
        set "answer="
        for %%x in (VSCode Juno Pluto PyCall Jupyter) do (
            if /i "!answer!" neq "R" (
                set "answer="
                for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (
                    if /i "!answer!" neq "Y"  if /i "!answer!" neq "N" if /i "!answer!" neq "R" (
                        echo Install %%x...
                        set /P answer="Yes, No, Reset questions [Y/N/R]? " || set answer=xxxx
                    )
                )
                echo:
                if /i "!answer!" equ "y" set "juliawin_install_%%x=1"
                if /i "!answer!" equ "n" set "juliawin_install_%%x=0"
            )
        )
    )
)

:skip-questions