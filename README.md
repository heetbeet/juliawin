# Julia on Windows with batteries included
Juliawin is a Julia installer for Windows: it includes Julia as well as tools like Atom/Juno, Jupyter and the scientific Python stack. The installer is a single .bat file with a collection of batch and Julia routines to dynamically fetch and install all content from the original sources.

Juliawin sets out to be similar to https://winpython.github.io/ in outcome.

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/220px-Julia_Programming_Language_Logo.svg.png" width="200" />
  <img src="https://avatars2.githubusercontent.com/u/8275281?v=4" width="130" /> 
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/250px-Jupyter_logo.svg.png" width="100" />
</p>

## Instalation

1. You can right-click, <a href="https://raw.githubusercontent.com/heetbeet/juliawin/master/julia-win-installer.bat">`Save Link As`</a>, and run the script.

2. Or you can <kbd>Ctrl</kbd>+<kbd>c</kbd> and <kbd>Ctrl</kbd>+<kbd>v</kbd> and run the following command in <kbd>Ctrl</kbd>+<kbd>r</kbd> or Command Prompt:
```
powershell.exe -c "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/master/julia-win-installer.bat','%tmp%\jl.bat'); "%tmp%\jl.bat" /P"
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

* 32-bit support
* Linux equivalent script (and pretend Juliawin refers to: Julia for the win!)
* Add/remove Juliawin to Windows path (maybe add `register-juliawin-distribution.bat` and `unregister-juliawin-distribution.bat` to scripts)
* Installer/options for curated Julia Pro packages (maybe add `install-curated-packages.bat` to scripts)
* Offline installation support and pinned versions (cache, zip and ship)
* Make all addition (like IDE/packages/environments) optional with a buffet menu
