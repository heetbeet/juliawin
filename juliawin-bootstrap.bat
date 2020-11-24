@echo off
mkdir "%temp%\juliawin\src" > nul 2>&1
powershell.exe -c "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/master/src/julia-win-installer.bat', '%temp%\juliawin\src\julia-win-installer.bat')"
powershell.exe -c "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/master/src/functions.bat', '%temp%\juliawin\src\functions.bat')"
call "%temp%\juliawin\src\julia-win-installer.bat"