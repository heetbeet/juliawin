# Julia on Windows with batteries included
Juliawin is a Julia installer for Windows: it includes Julia as well as tools like Atom/Juno, Jupyter and the scientific Python stack. The installer is a single .bat file with a collection of batch and Julia routines to dynamically fetch and install all content from the original sources.

Juliawin sets out to be similar to https://winpython.github.io/ in outcome.

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/220px-Julia_Programming_Language_Logo.svg.png" width="200" /> &nbsp
  <img src="https://avatars2.githubusercontent.com/u/8275281?v=4" width="130" /> &nbsp
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Visual_Studio_Code_1.35_icon.svg/768px-Visual_Studio_Code_1.35_icon.svg.png" height="110" /> &nbsp&nbsp&nbsp
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/250px-Jupyter_logo.svg.png" width="100" />
  <img src="https://julialang.org/assets/infra/pluto_jl.svg" height="100" />
</p>

## Instalation

1. You can download and run the `juliawin-bootstrap.bat` file,

2. Or you can <kbd>Ctrl</kbd>+<kbd>c</kbd> and <kbd>Ctrl</kbd>+<kbd>v</kbd> the following command in <kbd>Ctrl</kbd>+<kbd>r</kbd> or Command Prompt:
```
cmd /c "powershell -c "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/master/juliawin-bootstrap.bat','%tmp%\jl.bat');" & "%tmp%\jl.bat""
```

## Options

During installation, you have the option to choose any of the following packages

 - [ ] Juno https://junolab.org/
 - [ ] Pluto https://github.com/fonsp/Pluto.jl
 - [ ] Visual Studio Code https://www.julia-vscode.org/
 - [ ] Jupyter notebooks https://github.com/JuliaLang/IJulia.jl (note, this adds ~2Gb Anaconda dependancies)

## Outcome

Everything gets installed into a single self-contained directory. The result is completely portable and can be run from an external device:

<p align="center">
 <img src="https://github.com/heetbeet/juliawin/raw/master/images/example-prompt.png"  /> 
</p>  
<p align="center">
<img src="https://github.com/heetbeet/juliawin/raw/master/images/example-usage.png" width="600" /> 
</p>

