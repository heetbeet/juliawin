'''Julia-Win batch installer... 2>NUL
@echo off

REM setlocal enabledelayedexpansion

REM https://stackoverflow.com/a/20476904/1490584
set "psexe=%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe"

set "juliawintmp=%temp%\juliawin"
mkdir "%juliawintmp%" 2> NUL

set "tmpwinpy=%juliawintmp%\winpython.exe"
set "tmpwinpydir=%juliawintmp%\winpython"
mkdir "%tmpwinpydir%"  2> NUL

REM We will need these tools, so might as well collect them now
set "winpyurl=https://github.com/winpython/winpython/releases/download/2.3.20200319/Winpython64-3.8.2.0dot.exe"
set "zip7dllurl=https://raw.githubusercontent.com/winpython/winpython/master/tools/7z.dll"
set "zip7exeurl=https://raw.githubusercontent.com/winpython/winpython/master/tools/7z.exe"
set "zip7dll=%juliawintmp%\7z.dll"
set "zip7exe=%juliawintmp%\7z.exe"


Echo ************************************************************
Echo First Download Python in order to run rest of the setup
Echo From: %winpyurl%
Echo To: %tmpwinpy%
Echo:
Echo This may take a while...
REM %psexe% -Command "(New-Object Net.WebClient).DownloadFile('%winpyurl%', '%tmpwinpy%')"
REM %psexe% -Command "(New-Object Net.WebClient).DownloadFile('%zip7dllurl%', '%zip7dll%')"
REM %psexe% -Command "(New-Object Net.WebClient).DownloadFile('%zip7exeurl%', '%zip7exe%')"

REM REM psexe -Command "Invoke-WebRequest http://www.example.com/package.zip -OutFile package.zip"

Echo ************************************************************
Echo Extract python into temp directory
REM call %zip7exe% x -y -o"%tmpwinpydir%" "%tmpwinpy%"

for /f "delims=" %%a in ('dir /b /ad "%tmpwinpydir%\*" ') do set "winpyhome=%tmpwinpydir%\%%a"
set "py=%winpyhome%\scripts\python.bat"
set "pip=%winpyhome%\scripts\pip.bat"

Echo ************************************************************
Echo Download wget
REM call "%py%" %0 GET-WGET
set "wget=%juliawintmp%\wget\wget.exe"

REM call "%py%" %0 GET-UNIEXTRACT
REM call "%py%" %0 GET-JULIA
call "%py%" %0 GET-ATOM

GOTO :EOF
'''
#******************************************************
#Here are python routines to be called from this script
#******************************************************
import os
import sys
import subprocess
import re
import shutil
from urllib import request

juliawintmp = os.environ['juliawintmp']

def get_download_link(hosturl, regex, prefix="", notcontain=None):
	url = hosturl
	page = request.urlopen(url).read().decode('utf-8')

	regex = re.compile(".*("+regex+").*")
	dlurls = regex.findall(page)
	if notcontain:
		dlurls = [i for i in dlurls if not notcontain in i]

	dlurl =	prefix+dlurls[0]

	fname = dlurl.strip('/').split('/')[-1]

	return dlurl, fname


def download_file_pshell(dlurl, dest):
	psbin = os.environ["psexe"]
	subprocess.call([
		psbin,
		"-Command",
		f"(New-Object Net.WebClient).DownloadFile('{dlurl}', '{dest}')"
	])


def download_file(dlurl, dest):
	wgetbin = os.environ["wget"]
	subprocess.call(f'"{wgetbin}" "{dlurl}" -O "{dest}"', shell=True)


def extract_file(archive, destdir):
	zip7bin = os.environ["zip7exe"]
	subprocess.call([
		zip7bin,
		"x",
		"-y",
		f"-o{destdir}",
		archive
		])

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


if sys.argv[1] == "GET-WGET":
	url, fname = get_download_link("https://eternallybored.org/misc/wget/",
		                           r"releases/wget-.*-win32.zip", 
		                           prefix="https://eternallybored.org/misc/wget/")

	fpath = juliawintmp+"\\"+fname

	download_file_pshell(url, fpath)
	extract_file(fpath, f"{os.environ['juliawintmp']}\wget")
	

if sys.argv[1] == "GET-UNIEXTRACT":

	url, fname = get_download_link("https://github.com/Bioruebe/UniExtract2/releases/",
		                            r"Bioruebe/UniExtract2/releases/download/v.*/Uni.*.zip",
		                            prefix="https://github.com/")
	
	download_file(url, juliawintmp+"\\"+fname)
	extract_file(juliawintmp+"\\"+fname, juliawintmp+"\\uniextract")


if sys.argv[1] == "GET-JULIA":
	jhome = juliawintmp+"\\juliatmp"
	jsub = juliawintmp+"\\juliatmp\\julia"

	url, fname = get_download_link(
		"https://julialang.org/downloads/",
		r"https.*/bin/.*/x64/.*/julia-.*-win64.exe")

	download_file(url, juliawintmp+"\\"+fname)

	if os.path.isdir(jhome):
		shutil.rmtree(jhome)
	extract_file(juliawintmp+"\\"+fname, jhome)

	if os.path.isdir(jsub):	
		shutil.rmtree(jsub)
	extract_file(juliawintmp+"\\juliatmp\\julia-installer.exe", jsub)

	#Move content of directory that starts with "$" one level up
	for p in os.listdir(jsub):
		absp = os.path.abspath(jsub+"\\"+p)

		if os.path.isdir(absp) and p.startswith("$"):
			for ndir, dirs, files in os.walk(absp):
				for d in dirs:
					absd = os.path.abspath(ndir+"/"+d)
					os.makedirs(jsub + '/' + absd[len(absp):], exist_ok=True)

				for f in files:
					absf = os.path.abspath(ndir+"/"+f)
					os.rename(absf, jsub + '/' + absf[len(absp):])

			shutil.rmtree(absp)


if sys.argv[1] == "GET-ATOM":
	url, fname = get_download_link("https://github.com/atom/atom/releases/",
		                            r"atom/atom/releases/download/v.*/.*x64.*win.*.zip",
		                            prefix="https://github.com/",
		                            notcontain="-beta")

	download_file(url, juliawintmp+"\\"+fname)
	extract_file(juliawintmp+"\\"+fname, juliawintmp+"\\atom")


