@call "%~dp0\..\internals\scripts\functions.bat" SHOW-JULIA-ASCII
@echo:
@call "%~dp0\..\internals\scripts\bootstrap-juliawin-from-local-directory.bat" %*
@exit /b %errorlevel%
