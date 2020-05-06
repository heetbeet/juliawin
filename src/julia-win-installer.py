from __future__ import print_function
print("""
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Run with "/h" for help
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Unofficial installer for Juliawin
 _/ |\__'_|_|_|\__'_|  |
|__/                   |
""")

import os
import sys
import shutil
import subprocess
import tarfile
FNULL = open(os.devnull, 'w')
import tempfile


#input for python 2
try: raw_input
except: raw_input=input

#%%
#printing for errors
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


#%%
def download_file(url, filelocation):
    """
    Download a file using wget or curl.
    """
    filelocation = os.path.abspath(filelocation)
    try:
        subprocess.call(['wget', '--help'], 
                        stdout=FNULL, 
                        stderr=subprocess.STDOUT)
        iswget = True
    except:
        iswget = False
        

    if iswget:      
       subprocess.call(["wget", 
                        url, 
                        "-O", 
                        os.path.abspath(filelocation)])
    else:
        subprocess.call(["curl", "-g", "-L", "-f", "-o", 
                         os.path.abspath(filelocation),
                         url])
        
    
#%%
def move_tree(source, dest):
    '''
    Move a tree from source to destination
    '''
    source = os.path.abspath(source)
    dest = os.path.abspath(dest)

    try:
        os.makedirs(dest)
    except: 
        pass

    for ndir, dirs, files in os.walk(source):
        for d in dirs:
            absd = os.path.abspath(ndir+"/"+d)
            try:
                os.makedirs(dest + '/' + absd[len(source):])
            except:
                pass

        for f in files:
            absf = os.path.abspath(ndir+"/"+f)
            os.rename(absf, dest + '/' + absf[len(source):])
    shutil.rmtree(source)
    
    
#%%
def unnest_dir(dirname):
    r'''
    de-nesting single direcotry paths:
        From:
        (destdir)--(nestdir)--(dira)
                           \__(dirb)
        To:
        (destdir)--(dira)
                \__(dirb)
    '''
    
    if len(os.listdir(dirname)) == 1:
        deepdir = dirname+'/'+os.listdir(dirname)[0]
        if os.path.isdir(dirname):
            move_tree(deepdir, dirname)
            return True
        
    return False
    

#%%
def rmtree(dirname):
    '''
    Rmtree with exist_ok=True
    '''
    if os.path.isdir(dirname):
        shutil.rmtree(dirname)


#%%
def rmpath(pathname):
    '''
    Like rmtree, but file/tree agnostic
    '''
    rmtree(pathname)
    try:
        os.remove(pathname)
    except:
        pass
    
    
#%%
def cppath(srce, dest):
    '''
    File/tree agnostic copy
    '''
    dest = os.path.abspath(dest)
    try:
        os.makedirs(os.path.dirname(dest))
    except:
        pass
    
    if os.path.isdir(srce):
        shutil.copytree(srce, dest)
    else:
        shutil.copy(srce, dest)


#%%        
def untar(fname, output):
    try:
        os.makedirs(output)
    except:
        pass
    
    if fname.lower().endswith("tar.gz"):
        tar = tarfile.open(fname, "r:gz")
        tar.extractall(path=output)
        tar.close()
    elif fname.lower().endswith("tar"):
        tar = tarfile.open(fname, "r:")
        tar.extractall(path=output)
        tar.close()
    else:
        raise ValueError("Cannot extract filetype "+fname)


#%% Parse the arguments
args = {}
for i, arg1 in enumerate(sys.argv[1:]):
    if i == len(sys.argv[1:])-1:
        arg2 = ''
    else:
        arg2 = sys.argv[1:][i+1]
        
    tst1 =  arg1.replace('/','-')[:1] 
    tst2 =  arg2.replace('/','-')[:1] 
    
    if tst1 == '-' and (tst2 == '-' or tst2 == ''):
        args[arg1[1:].lower()] = True
    elif tst1 == '-':
        args[arg1[1:].lower()] = arg2
        
        
#%% Print help menu
if 'h' in args:
    print("The setup program accepts the following command line parameters:")
    print("")
    print("-HELP, -H")
    print("   Show this information and exit")
    print("/Y")
    print("   Yes to all")
    print('/DIR "\path\to\Dirname"')
    print("   Overwrite the default with custom directory")
    print("/RMDIR")
    print("   Clear the install directory (if not empty)")
    exit(0)
    

#%% Set up the environment
installdir = "~/Juliawin"
juliatemp = os.path.join(tempfile.gettempdir(), "juliawin")
try:
    os.makedirs(juliatemp)
except: #FileExistsError not in python 2
    pass

try: __file__
except: __file__ = os.getcwd()+'/julia-win-installer.bat'
open(juliatemp+'/thisfile.txt', 'w').write(os.path.abspath(__file__))


#%% choose a directory
if "dir" in args:
    installdir = args["dir"]
    
if not "y" in args and not "dir" in args:
    print("""
      [Y]es: continue
      [N]o: cancel the operation
      [D]irectory: choose my own directory
    """)
    
    ynd = "xxx"
    if "y" in args:
        ynd = "y"
    while ynd.lower() not in "ynd":
        
        ynd = raw_input("Install Juliawin in "+installdir+" [Y/N/D]? ")
            
        if ynd.lower() == "n":
            exit(-1)
            
        if ynd.lower() == "d":
            installdir = raw_input("Please enter custom directory: ")
            if installdir == "":
                ynd = "xxx"
    
    
#%% make sure directory is valid
installdir = os.path.abspath(os.path.expanduser(installdir))
if "rmdir" in args:
    shutil.rmtree(installdir)
     
try:
    os.makedirs(installdir)
except: #FileExistsError not in python 2
    pass
    
if not "rmdir" in args:
    #test if write-readable
    try:
        with open(installdir+"/thisisatestfiledeleteme", 'w') as f: pass
        os.remove(installdir+"/thisisatestfiledeleteme")
    except:
        eprint("Error, can't read/write to "+installdir)
        exit(1)
        
    if len(os.listdir(installdir)) > 0:
        eprint("Error, the install directory is not empty.")
        exit(1)


#%% write location of this script to tempdirectory
open(juliatemp+'/installdir.txt', 'w').write(installdir)


#%% Setup path environment
os.environ["PATH"] = os.pathsep.join([
    installdir+'/julia/bin',
    installdir+'/julia/libexec',
    installdir+'/atom',
    installdir+'/atom/resources/cli',
    installdir+'/atom/resources/app/apm/bin',
    os.environ["PATH"]
])
    
os.environ["JULIA_DEPOT_PATH"] = installdir+'/.julia'
os.environ["ATOM_HOME"] = installdir+'/.atom'

    
#%% Download lates julia linux
print("() Configuring the download source")
download_file("https://julialang.org/downloads",
              juliatemp+'/julialang_org_downloads')


#yes: https://julialang-s3.julialang.org/bin/linux/x64/1.4/julia-1.4.1-linux-x86_64.tar.gz
#no:  https://julialang-s3.julialang.org/bin/linux/aarch64/1.0/julia-1.0.5-linux-aarch64.tar.gz
dlurl = None
for i in open(juliatemp+'/julialang_org_downloads').read().split('"'):
    if (i.startswith('http') and '/bin/linux/' in i and "x86" in i and i.endswith('64.tar.gz')):
        dlurl = i
    
fname = juliatemp+'/'+dlurl.split('/')[-1]

print("() Download "+dlurl+" to ")
print("() "+fname)
download_file(dlurl, fname)

untar(fname, installdir+"/julia")
unnest_dir(installdir+"/julia")

#%%Install the Julia scripts
if os.path.isfile(os.path.splitext(__file__)[0]+'.jl'):
    juliafile = os.path.splitext(__file__)[0]+'.jl'
else:
    juliafile = __file__


subprocess.call(["julia", "--color=yes", "-e", "Base.banner()"])

subprocess.call(["julia", juliafile, "INSTALL-ATOM"])

subprocess.call(["julia", juliafile, "INSTALL-JUNO"])

subprocess.call(["julia", juliafile, "INSTALL-JUPYTER"])

subprocess.call(["julia", juliafile, "MAKE-BASHES"])
