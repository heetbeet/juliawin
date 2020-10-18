powershell.exe -c "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/refactor/src/julia-win-installer.bat', '%tmp%\julia-win-installer.bat')"
powershell.exe -c "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/refactor/src/functions.bat', '%tmp%\functions.bat')"
"%tmp%\julia-win-installer.bat"