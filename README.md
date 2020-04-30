# Juliawin: batteries included
Juliawin is an Julia installer for Windows, which includes Julia with some extra goodies like Atom/Juno, Jupyter and the scientific stack Python stack. The installer is a set of routines to fetch and install all content from the original sources.

Juliawin sets out to be similar to https://winpython.github.io/ in outcome.

<p float="left">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/220px-Julia_Programming_Language_Logo.svg.png" width="200" />
  <img src="https://avatars2.githubusercontent.com/u/8275281?v=4" width="130" /> 
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/250px-Jupyter_logo.svg.png" width="100" />
</p>

## Instalation

Or you can download and run the script from this [link](https://raw.githubusercontent.com/heetbeet/julia-win/master/julia-win-installer.bat).

Or you can <kbd>Ctrl</kbd>+<kbd>c</kbd> and <kbd>Ctrl</kbd>+<kbd>v</kbd> the following code in any execution window, like <kbd>⊞ Win</kbd>+<kbd>r</kbd>:
```
%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/julia-win/master/julia-win-installer.bat','%TEMP%\juliawin-installer.bat')); %systemroot%\system32\cmd.exe /c ""%TEMP%\juliawin-installer.bat" /P""
```

## Outcome

Everything gets installed into a single self-contained directory. The result is completely portable and can be run from a external device:

![prompt](https://github.com/heetbeet/julia-win/raw/master/images/example-prompt.png)


## Future work

* Make prettier entry executables than .bat files (Use an automatic NSIS pipeline to produce .exe's with icons).
* Installer should clean up it's temp directory.
* Download the list of curated packages from Julia Pro and create an `install-curated-packages.bat` helper for the user.
* Added options for offline installation.
