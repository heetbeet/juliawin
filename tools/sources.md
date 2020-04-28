wget on 2020-04-28 https://eternallybored.org/misc/wget/releases/wget-1.20.3-win32.zip

7zip from https://github.com/winpython/winpython/tree/a727a8da6816abd3700e50c8e10860839377fe0f/tools

python.exe ran autopytoexe.exe from https://pypi.org/project/auto-py-to-exe/ on python.py:
import os
import sys
__file__ = os.path.abspath(sys.argv[1])
exec(open(__file__).read())