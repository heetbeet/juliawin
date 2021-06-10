<p align="center"> <img src="https://raw.githubusercontent.com/heetbeet/juliawin/main/internals/assets/juliawin-logo.svg" width="350" /> </p>

# A portable Julia distribution with batteries included
Juliawin includes Julia as well as tools like VSCode, Juno , Pluto, Jupyter and the scientific Python stack bundled with PyCall.

Juliawin sets out to be similar to https://winpython.github.io/ in outcome.

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/220px-Julia_Programming_Language_Logo.svg.png" width="200" /> &nbsp
  <img src="https://avatars2.githubusercontent.com/u/8275281?v=4" width="130" /> &nbsp
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Visual_Studio_Code_1.35_icon.svg/768px-Visual_Studio_Code_1.35_icon.svg.png" height="110" /> &nbsp&nbsp&nbsp
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/250px-Jupyter_logo.svg.png" width="100" />
  <img src="https://julialang.org/assets/infra/pluto_jl.svg" height="100" />
</p>

## Instalation methods

<a href="https://github.com/heetbeet/juliawin/releases"><img src="https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png" height="35" /> Full releases</a>

<a href="https://github.com/heetbeet/juliawin/raw/main/bin/Juliawin%20Bootstrap%20From%20Github.exe"><img src="https://i.redd.it/t4f6ysfremu11.png" height="35" /> Thin installer</a>

<img src="https://miro.medium.com/max/896/1*Fq0GuTM3LZ7S6I_mW1hD9A.png" height="30" />  Commandline:

```
cmd /c "powershell -c "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/heetbeet/juliawin/main/bin/Juliawin Bootstrap From Github.bat','%tmp%\_.bat')" & "%tmp%\_.bat""
```

## Options

During installation, you have the option to choose any of the following packages

 - <img src="https://avatars2.githubusercontent.com/u/8275281?v=4" height="20" /> Juno https://junolab.org/
 - <img src="https://julialang.org/assets/infra/pluto_jl.svg" height="20" /> Pluto https://github.com/fonsp/Pluto.jl
 - <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Visual_Studio_Code_1.35_icon.svg/768px-Visual_Studio_Code_1.35_icon.svg.png" height="20" /> Visual Studio Code https://www.julia-vscode.org/
 - <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/250px-Jupyter_logo.svg.png" width="20" /> Jupyter https://github.com/JuliaLang/IJulia.jl (warning: adds 3Gb Python/Conda dependencies)

## Outcome

Everything gets installed into a single self-contained directory. The result is completely portable and can be run from an external device:

<p align="center">
 <img src="https://github.com/heetbeet/juliawin/raw/main/internals/images/example-prompt.png"  /> 
</p>  
<p align="center">
<img src="https://github.com/heetbeet/juliawin/raw/main/internals/images/example-usage.png" width="600" /> 
</p>

