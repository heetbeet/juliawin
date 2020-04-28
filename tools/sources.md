## wget.exe

Downloaded from https://eternallybored.org/misc/wget/releases/wget-1.20.3-win32.zip on 2020-04-28

## 7z.dll / 7z.exe
Used the same version as WinPython.

Downloaded from https://github.com/winpython/winpython/tree/a727a8da6816abd3700e50c8e10860839377fe0f/tools

## python.exe
Mini Python 3.7.4 executable for small scripts.

Made by running autopytoexe.exe on a file called `python.py`, with content:
```
import os
import sys
__file__ = os.path.abspath(sys.argv[1])
exec(open(__file__).read())
```

source: https://pypi.org/project/auto-py-to-exe/
