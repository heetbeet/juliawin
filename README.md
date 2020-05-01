# Julia, with batteries included
Juliawin is a Julia installer for Windows: it includes Julia as well as extra dev-tools like Atom/Juno, Jupyter and the scientific Python stack. The installer is a collection of routines that fetches and installs all content from the original sources. It starts off in plain batch with Julia bootstrapped later in the process.

Juliawin sets out to be similar to https://winpython.github.io/ in outcome.

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/220px-Julia_Programming_Language_Logo.svg.png" width="200" />
  <img src="https://avatars2.githubusercontent.com/u/8275281?v=4" width="130" /> 
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/250px-Jupyter_logo.svg.png" width="100" />
</p>

## Instalation

Or you can download and run the script from this <a href="https://raw.githubusercontent.com/heetbeet/julia-win/master/julia-win-installer.bat" download>link</a>.

Or you can <kbd>Ctrl</kbd>+<kbd>c</kbd> and <kbd>Ctrl</kbd>+<kbd>v</kbd> the following code in any execution window, like <kbd>⊞ Win</kbd>+<kbd>r</kbd>:
```
%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/julia-win/master/julia-win-installer.bat','%TEMP%\juliawin-installer.bat')); %systemroot%\system32\cmd.exe /c ""%TEMP%\juliawin-installer.bat" /P""
```

## Outcome

Everything gets installed into a single self-contained directory. The result is completely portable and can be run from a external device:

<p align="center">
 <img src="https://github.com/heetbeet/julia-win/raw/master/images/example-prompt.png"  /> 
</p>  
<p align="center">
<img src="https://github.com/heetbeet/julia-win/raw/master/images/example-usage.png" width="600" /> 
</p>

## Todo's

* Option for users to add/remove Juliawin to Windows path.
* Make argument combinations work (currently only single argument works).
* Make prettier entry executables with icons, rather than .bat files (Automate a NSIS pipeline).
* Let the installer clean up it's temp directory.
* Download the list of curated packages from Julia Pro and create an `install-curated-packages.bat` helper for the user.
* Add options for offline installation (cache and zip).
