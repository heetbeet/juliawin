import sys

if sys.argv[1] == "--version" or sys.argv[1] == "-V":
  print("Python 3.7.4")

elif sys.argv[1] == "-c":
  exec(sys.argv[2])
  
else:
  import os
  __file__ = os.path.abspath(sys.argv[1])
  sys.argv = sys.argv[1:]
  exec(open(__file__).read())