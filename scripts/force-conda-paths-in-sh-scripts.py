"""
Replace the hardcoded links in conda's activate shell scripts to ensure relative paths
"""

from pathlib import Path
import subprocess
import re
import sys
import subprocess

condadir = Path(__file__).resolve().parent.parent.joinpath('vendor', 'conda')

condadir_realpath = subprocess.check_output(["realpath", str(condadir)]).decode('utf-8').strip()
if condadir_realpath[-1:] == '/':
    condadir_realpath[:-1]


#********************************
# profile.d
#********************************
with condadir.joinpath("etc", "profile.d", "conda.sh").open() as f:
    txt = f.read()

txt_out = []
for i in txt.split('\n'):
    if i.startswith('export CONDA_EXE='):
        txt_out.append(f'export CONDA_EXE="$(realpath "{condadir_realpath}/Scripts/conda.exe")"')
    elif i.startswith('export CONDA_PYTHON_EXE='):
        txt_out.append(f'export CONDA_PYTHON_EXE="$(realpath "{condadir_realpath}/python.exe")"')
    else:
        txt_out.append(i)
txt_out = '\n'.join(txt_out)
    
with condadir.joinpath("etc", "profile.d", "conda.sh").open("w") as f:
    f.write(txt_out)


#********************************
# Scripts
#********************************
txt_out = []
for i in txt.split('\n'):
    if i.startswith('export CONDA_EXE='):
        txt_out.append(f'export CONDA_EXE="$(realpath "{condadir_realpath}/Scripts/conda.exe")"')
    elif i.startswith('export CONDA_PYTHON_EXE='):
        txt_out.append(f'export CONDA_PYTHON_EXE="$(realpath "{condadir_realpath}/python.exe")"')
    else:
        txt_out.append(i)
txt_out = '\n'.join(txt_out)
    
with condadir.joinpath("Scripts", "activate").open("w") as f:
    f.write(txt_out)