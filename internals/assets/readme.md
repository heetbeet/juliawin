## To create the launcher exe's

tcc.exe -D_UNICODE -DNOSHELL launcher.c -luser32 -lkernel32 -mwindows -o launcher-noshell.exe

tcc.exe -D_UNICODE  launcher.c -luser32 -lkernel32 -o launcher.exe

## To create icon files

https://onlineconvertfree.com/convert-format/svg-to-ico/
