'''Julia-Win batch installer... 2>NUL
@echo off

REM ===================================================== 
REM This is an automatic install script for Julia
REM First half of the script is written in batch
REM Second half of the script are Python routines called 
REM from batch.
REM
REM The batch part makes sure the environment is set up
REM correctly and that Python 3 is available, while the 
REM heavy lifting is done in Python.
REM =====================================================


SETLOCAL EnableDelayedExpansion

set PATH=c:\windows\system32;c:\windows\


REM ******************************************
REM Let's first get some variables going
REM ******************************************
set "psexe=%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe"

set "juliawintmp=%temp%\juliawin"
mkdir "%juliawintmp%" 2> NUL

set "toolsdir=%juliawintmp%\tools"
mkdir "%toolsdir%" 2> NUL

CALL :READPATHSFROMFILE PATHADDITIONS "%juliawintmp%\paths.txt"
SET "PATH=%PATHADDITIONS%;%PATH%"
set "PATH=%PATH%;%toolsdir%"

set JULIA_DEPOT_PATH=%juliawintmp%\.julia


REM ******************************************
REM Now lets make sure we have Python
REM ******************************************
call :ENSURE_PYTHON_EXISTS


REM ******************************************
REM Lets run our install script
REM ******************************************
REM python %0 HELLO-WORLD
REM echo:> "%juliawintmp%\paths.txt"
python %0 GET-TOOLS
#python %0 GET-JULIA
#python %0 GET-ATOM
#python %0 GET-JULIA-PACKAGES
python %0 MAKE-BINLINKS

CALL :READPATHSFROMFILE PATHADDITIONS "%juliawintmp%\paths.txt"
SET "PATH=%PATHADDITIONS%;%PATH%"

where python

REM Guarded subroutines
GOTO :EOF

REM ***********************************************
REM Routine to make sure we can use python 3
REM ***********************************************
:ENSURE_PYTHON_EXISTS
	python --version >NUL
	if errorlevel 1 goto PYTHON_DOES_NOT_EXIST
	python --version | find " 3." >NUL
	if errorlevel 1 (goto PYTHON_DOES_NOT_EXIST) else (goto :EOF)

	:PYTHON_DOES_NOT_EXIST
	ECHO Python 3 is not available, we will download a mini Python 3
	REM old-style powershell download
	call %psexe% -Command "Invoke-WebRequest 'https://github.com/heetbeet/julia-win/raw/master/tools/python.exe' -OutFile '%toolsdir%\python.exe'"

	python --version  >NUL
	if errorlevel 1 goto PYTHON_STILL_DOES_NOT_EXIST
	python --version | find " 3." >NUL
	if errorlevel 1 (goto PYTHON_STILL_DOES_NOT_EXIST) else (goto :EOF)
	goto :EOF

	:PYTHON_STILL_DOES_NOT_EXIST
	REM new-style powershell download
	call %psexe% -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/heetbeet/julia-win/raw/master/tools/python.exe', '%toolsdir%\python.exe')"	
	goto :EOF


REM ***********************************************
REM Convert relative path to absolute path
REM ***********************************************
:SETFULLPATH
    set %1=%~f2
    GOTO :EOF


REM ***********************************************
REM Initiate a variable as empty string
REM ***********************************************
:INITVAR
    SET %1=
    SET %1>NUL  2>NUL
    GOTO :EOF


REM ***********************************************
REM Read the user-given paths from the file "path"
REM ***********************************************
:READPATHSFROMFILE
    CALL :INITVAR TMPPATH
    for /F "tokens=*" %%A in ('type %2') do ( 
        CALL :SETFULLPATH TMPVAR "%%A"
        CALL SET "TMPPATH=%%TMPPATH%%;%%TMPVAR%%"
    )
    REM Substring to remove the first ";"
    SET %1=%TMPPATH:~1%
    SET TMPPATH=
    SET TMPVAR=
    GOTO :EOF


GOTO :EOF

'''
#******************************************************
# This is the Python part of the script
#
#******************************************************
import os
import sys
import subprocess
import re
import shutil
from urllib import request

juliawintmp = os.environ["juliawintmp"]
toolsdir = os.environ["toolsdir"]
psbin = os.environ["psexe"]

paths = juliawintmp+'/paths.txt'

if os.path.isfile(paths):
	for i in open(paths).read().split('\n'):
		i = i.strip()
		if not i: continue

		if i.lower() not in [i.lower() for i in os.environ["PATH"].split(';')]:
			os.environ["PATH"] += os.pathsep + i

def add_to_paths(pname):
	pname = os.path.abspath(pname)
	if pname not in open(paths, 'r').read().split('\n'):
		open(paths, 'a').write(os.path.abspath(pname)+'\n')

	if pname.lower() not in [i.lower() for i in os.environ["PATH"].split(';')]:
		os.environ["PATH"] += os.pathsep + pname


def get_download_link(hosturl, regex, prefix="", notcontain=None, takemax=False):
	url = hosturl

	from urllib.request import Request, urlopen
	req = Request(url, headers={'User-Agent': 'Mozilla/5.0'})
	page = urlopen(req, timeout=15).read().decode('utf-8')
	page = '\n'.join(page.split('>'))
	page = '\n'.join(page.split('<'))

	regex = re.compile(".*("+regex+").*")
	dlurls = regex.findall(page)

	if notcontain:
		dlurls = [i for i in dlurls if not notcontain in i]

	if takemax:
		dlurl =	prefix+max(dlurls)
	else:
		dlurl =	prefix+max(dlurls[0])

	fname = dlurl.strip('/').split('/')[-1]

	return dlurl, fname


def download_file_pshell(dlurl, dest):
	subprocess.call([
		psbin,
		"-Command",
		f"Invoke-WebRequest '{dlurl}' -OutFile '{dest}'"
	])

	if not os.path.exists(dest):
		subprocess.call([
			psbin,
			"-Command",
			f"(New-Object Net.WebClient).DownloadFile('{dlurl}', '{dest}')"
		])


def download_file(dlurl, dest):
	subprocess.call(f'"wget" "{dlurl}" -O "{dest}"', shell=True)


def extract_file(archive, destdir):
	subprocess.call([
		"7z",
		"x",
		"-y",
		f"-o{destdir}",
		archive
		])

def flatextract_file(archive, destdir, force=True):
	if force:
		rmtree(destdir)

	extract_file(archive, destdir)

	if len(os.listdir(destdir)) == 1:
		deepdir = destdir+'/'+os.listdir(destdir)[0]
		if os.path.isdir(deepdir):
			move_tree(deepdir, destdir)

def uniextract_file(archive, destdir):
	for dirname, dirs, files in os.walk(juliawintmp+"\\uniextract"):
		for file in files:
			if file == "UniExtract.exe":
				uextbin = dirname+"\\"+file
				break
	
	subprocess.call([
		uextbin,
		archive,
		destdir
	])

def rmtree(dirname):
	if os.path.isdir(dirname):
		shutil.rmtree(dirname)

def move_tree(source, dest):
	source = os.path.abspath(source)
	dest = os.path.abspath(dest)

	os.makedirs(dest, exist_ok=True)

	for ndir, dirs, files in os.walk(source):
		for d in dirs:
			absd = os.path.abspath(ndir+"/"+d)
			os.makedirs(dest + '/' + absd[len(source):], exist_ok=True)

		for f in files:
			absf = os.path.abspath(ndir+"/"+f)
			os.rename(absf, dest + '/' + absf[len(source):])
	shutil.rmtree(source)


if sys.argv[1] == "HELLO-WORLD":
	print("Hello World")

if sys.argv[1] == "GET-TOOLS":
	
	if not shutil.which("wget"):
		download_file_pshell("https://github.com/heetbeet/julia-win/raw/master/tools/wget.exe", toolsdir+"/wget.exe")

	if not shutil.which("7z"):
		download_file("https://github.com/heetbeet/julia-win/raw/master/tools/7z.exe", toolsdir+"/7z.exe")
		download_file("https://github.com/heetbeet/julia-win/raw/master/tools/7z.dll", toolsdir+"/7z.dll")

	add_to_paths(toolsdir)

if sys.argv[1] == "GET-UNIEXTRACT":

	url, fname = get_download_link("https://github.com/Bioruebe/UniExtract2/releases/",
		                            r"Bioruebe/UniExtract2/releases/download/v.*/Uni.*.zip",
		                            prefix="https://github.com/")
	
	download_file(url, juliawintmp+"\\"+fname)
	extract_file(juliawintmp+"\\"+fname, juliawintmp+"\\uniextract")


if sys.argv[1] == "GET-JULIA":

	url, fname = get_download_link(
		"https://julialang.org/downloads/",
		r"https.*bin/winnt/x64/.*win64.exe",
		takemax=True)

	download_file(url, juliawintmp+"\\"+fname)

	jhome = os.path.abspath(juliawintmp+"\\julia")
	
	rmtree(jhome)

	os.makedirs(jhome, exist_ok=True)

	subprocess.call([
		juliawintmp+"\\"+fname,
		"/SP-",
		"/VERYSILENT",
		f"/DIR={jhome}"
	])

	add_to_paths(juliawintmp+"\\julia\\bin")
	
if sys.argv[1] == "GET-ATOM":
	url, fname = get_download_link("https://github.com/atom/atom/releases/",
		                            r"atom/atom/releases/download/v.*/.*x64.*win.*.zip",
		                            prefix="https://github.com/",
		                            notcontain="-beta")

	download_file(url, juliawintmp+"\\"+fname)

	rmtree(juliawintmp+"\\atom")
	extract_file(juliawintmp+"\\"+fname, juliawintmp+"\\atom")
	deepdir = juliawintmp+"\\atom\\"+os.listdir(juliawintmp+"\\atom")[0]
	move_tree(deepdir, juliawintmp+"\\atom")

	os.makedirs(juliawintmp+"\\.atom", exist_ok=True)

	add_to_paths(juliawintmp+"\\atom")
	add_to_paths(juliawintmp+"\\atom\\resources\\cli")


if sys.argv[1] == "GET-WINPYTHON":
	url, fname = get_download_link("https://github.com/winpython/winpython/releases",
		                            r"winpython/winpython/releases/download/.*/Winpython64-3.*dot.exe",
		                            prefix="https://github.com/")
	download_file(url, juliawintmp+"\\"+fname)
	winpydir = juliawintmp+"\\Winpython64-3"
	flatextract_file(juliawintmp+"\\"+fname, juliawintmp+"\\Winpython64-3")

	pypath = [i for i in os.listdir(winpydir) if i.startswith("python-") and os.path.isdir(winpydir+'/'+i)][0]
	add_to_paths(winpydir+"\\"+pypath)
	add_to_paths(winpydir+"\\"+pypath+"\\scripts")

	#Move toolkit path to end, otherwise we pich up wrong python
	if os.path.exists(toolsdir+"\\python.exe"):
		pathsorder = '\n'.join(([i for i in open(paths).read().split('\n') 
			                     if os.path.abspath(toolsdir).lower() != i.strip().lower()]+[toolsdir]))
		open(paths, 'w').write(pathsorder)


if sys.argv[1] == "GET-JULIA-PACKAGES":

	from urllib.request import Request, urlopen
	req = Request("https://juliacomputing.com/products/juliapro.html", headers={'User-Agent': 'Mozilla/5.0'})
	page = urlopen(req, timeout=10).read().decode('utf-8')
	regex = re.compile(".*(http.*//github.com/.*.jl).*")
	dlurls = regex.findall(page)
	
	print("The following packages get's suggested by Julia Pro, let's try installing them:")
	for i in dlurls:
		print(" ->", i.split('/')[-1])

	def add_pkg(pkgname):
	    subprocess.call(["julia",  "-e", f'using Pkg; Pkg.add("{pkgname}")'])

	#pacnames = [i.split('/')[-1].split('.jl')[0] for i in dlurls]
	#for nr, packname in enumerate(pacnames):
	#	print("\n\n+============================+")
	#	print(f"    Trying {pacname} {nr+1}/{len(dlurls)} ")
	#	print( "+============================+\n")
	#	
	#	add_pkg(pacname)

	outfile = (juliawintmp+"/juliapackages.txt").replace('\\','/')
	print(outfile)
	subprocess.call([
		 "julia", 
		 "-e",
		 rf'using Pkg; f=open("{outfile}", "w"); write(f, join([i[2].name for i in Pkg.dependencies()], ";")); close(f)'
		])

if sys.argv[1] == "MAKE-BINLINKS":
	juliawintmp = os.path.abspath(juliawintmp)
	pathslist = [os.path.abspath(i) for i in open(paths, 'r').read().split('\n') if i.strip()]
	pathslist = [i for i in pathslist if i.lower() != os.path.abspath(toolsdir).lower()]

	pathvar = '\n'.join([rf"set 'PATH=%~dp0{i[len(juliawintmp):]};%PATH%'" for i in pathslist])

	template = rf'''@echo off
set "JULIA_DEPOT_PATH=%~dp0\.julia"
{pathvar}

__binpath__ %*
'''

	exes = []
	for p in pathslist:
		p = p.strip()
		if not p: continue
		if not os.path.isdir(p): continue

		pabs = os.path.abspath(p)

		exes = exes+[os.path.abspath(p+'/'+i)[len(juliawintmp):] for i in os.listdir(p) if 
		[True for j in  ".COM .EXE .BAT .CMD .VBS .VBE .WSF .WSH .MSC".split() if i.upper().endswith(j)]]


	fnames = {os.path.basename(j).lower() for j in exes}
	for i in exes:
		fname = os.path.basename(i)
		fprog = os.path.splitext(fname)[0]
		if not fname.lower().endswith('.exe') and fprog.lower()+".exe" in fnames:
			#rather wait for exe
			continue

		open(juliawintmp + '/' + os.path.splitext(fname)[0]+'.bat', 'w'
		).write(template.replace("__binpath__", rf"%~dp0{i}"))
