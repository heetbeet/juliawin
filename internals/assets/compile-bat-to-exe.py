import subprocess
import os
import sys

thisdir = os.path.dirname(os.path.abspath(__file__))
os.chdir(thisdir)

if len(sys.argv) <= 1:
	print("Usage:", __file__, " <path of batch file>")

batchscript = open(sys.argv[1]).read()
batchscript = batchscript.replace("\\", "\\\\")
batchscript = batchscript.replace("\n", r"\n")
batchscript = batchscript.replace('"',  r'\"')

cscript = open("bat-to-exe.c").read().replace("__batchscript__", batchscript)

with open("bat-to-exe-temp.c", 'w') as fw:
	fw.write(cscript)

name = os.path.basename(sys.argv[1])
name = os.path.splitext(name)[0]

subprocess.call(f'tcc -D_UNICODE bat-to-exe-temp.c -luser32 -lkernel32 -o "{name}.exe"', shell=True)
