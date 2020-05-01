# Julia, with batteries included
Juliawin is a Julia installer for Windows: it includes Julia as well as tools like Atom/Juno, Jupyter and the scientific Python stack. The installer is a single .bat file with a collection of batch and Julia routines to dynamically fetch and installs all content from original sources.

Juliawin sets out to be similar to https://winpython.github.io/ in outcome.

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/220px-Julia_Programming_Language_Logo.svg.png" width="200" />
  <img src="https://avatars2.githubusercontent.com/u/8275281?v=4" width="130" /> 
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/250px-Jupyter_logo.svg.png" width="100" />
</p>

## Instalation

You can save and run the script from this <a href="https://raw.githubusercontent.com/heetbeet/juliawin/master/julia-win-installer.bat" download>link</a> (Github doens't provide the save-as popup unfortunately).

Or you can <kbd>Ctrl</kbd>+<kbd>c</kbd> and <kbd>Ctrl</kbd>+<kbd>v</kbd> and run the following code in any execution window (like <kbd>⊞ Win</kbd>+<kbd>r</kbd> or Command Prompt):
```
%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/master/julia-win-installer.bat','%TEMP%\julia-win-installer.bat')); %systemroot%\system32\cmd.exe /c ""%TEMP%\julia-win-installer.bat" /P""
```

## Outcome

Everything gets installed into a single self-contained directory. The result is completely portable and can be run from an external device:

<p align="center">
 <img src="https://github.com/heetbeet/juliawin/raw/master/images/example-prompt.png"  /> 
</p>  
<p align="center">
<img src="https://github.com/heetbeet/juliawin/raw/master/images/example-usage.png" width="600" /> 
</p>

## Todo's

* Option for users to add/remove Juliawin to Windows path.
* Make argument combinations work (currently only single argument works).
* Make prettier entry executables with icons, rather than .bat files (Automate a NSIS pipeline).
* Add Visual Studio Code to this project.
* Download the list of curated packages from Julia Pro and create an `install-curated-packages.bat` helper for the user.
* Let the installer clean up it's temp directory.
* Add options for offline installation (cache and zip).
* Provide everything as optional (write a buffet menu).
