@echo off
cd "%~dp0"
tcc -D_UNICODE -DNOSHELL launcher.c -luser32 -lkernel32 -mwindows -o launcher-noshell.exe
tcc -D_UNICODE  launcher.c -luser32 -lkernel32 -o launcher.exe
