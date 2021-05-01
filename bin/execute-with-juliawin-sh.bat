@goto :batch-script > /dev/null 2>&1 # > nul

# ****************************************************************************
# Usage: execute-with-juliawin-sh program arg1 arg2 arg3...
#
# This is a Polyglot script that is interperated differently by sh/bash and bat
# We use this to activate the juliawin environment and then run the given
# program with its commandline arguments under a mingw sh environment.
# ****************************************************************************


# ****************************************************************************
# Over here is the sh/bash part of the script (invoked via batch part)
# ****************************************************************************
"$@"
exit $?


:: ****************************************************************************
:: Over here is the bat/cmd boilerplate part of the script
:: ****************************************************************************
:batch-script
@echo off
setlocal

call "%~dp0\activate-juliawin-environment.bat"

:: If we are already in posix environment, just run directly
if "%MSYSTEM%" equ "" goto :not-already-in-mingw

    call %*
    exit /b %errorlevel%

:: If we have access to sh.exe, invoke program under bash
:not-already-in-mingw
if "%juliawin_sh%" equ "" goto :cannot-find-bash

	call "%juliawin_sh%" "%~dp0%~n0.bat" %*
	exit /b %errorlevel%

:: Else run under windows cmd as fallback
:cannot-find-bash

	echo Git Bash not in `packages\git`, `%%programfiles%%\git`, or `git.exe`
	echo You can install Git from git-scm.com for Julia posix access

	call %*
	exit /b %errorlevel%
