//#define NOSHELL

#define _WIN32_WINNT 0x0500
#include <windows.h>
#include <stdbool.h>
#include <tchar.h>

#ifdef NOSHELL
    int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
#else
    int main( int argc, char ** argv ) 
#endif
{
    // *******************************************
    //Get a direct path to the current running exe
    // *******************************************
    int size = 125;
    TCHAR* cmdPath = (TCHAR*)malloc(1);

    // read until GetModuleFileNameW writes less than its cap (of size)
    do {
        size *= 2;
        free(cmdPath);
        cmdPath = (TCHAR*)malloc(size*2);

        // If , then it's
    } while (GetModuleFileNameW(NULL, cmdPath, size) == size);


    // *******************************************
    // Get commandline string as a whole
    // *******************************************
    TCHAR* cmdArgs = GetCommandLineW();

    // *******************************************
    // Remove argument 0 from the commandline string
    // http://www.windowsinspired.com/how-a-windows-programs-splits-its-command-line-into-individual-arguments/
    // *******************************************
    bool inQuote = false;
    bool isArgs = false;
    int j = 0;

    for(int i=0; i<_tcslen(cmdArgs)+1; i++){
      //must be easier way to index unicode string
      TCHAR c = *(TCHAR *)(&cmdArgs[i*2]);
      
      if(c == L'"'){inQuote = !inQuote;}
      if(c == L' ' && !inQuote){ isArgs = true;}

      //do for both unicode bits
      cmdArgs[j*2  ] = cmdArgs[i*2  ];
      cmdArgs[j*2+1] = cmdArgs[i*2+1];

      //sync j with i after filepath
      if(isArgs){ j++; }
    }


    // *******************************************
    // Find basedir of cmdPath
    // *******************************************
    TCHAR* cmdBaseDir;
    cmdBaseDir = (TCHAR*) malloc((_tcslen(cmdPath)+1)*2);
    cmdBaseDir[0] = '\0';
    cmdBaseDir[1] = '\0';

    _tcscpy(cmdBaseDir, cmdPath);


    int nrOfSlashed = 0;
    int slashLoc = 0;
    for(int i=0; i<_tcslen(cmdBaseDir); i++){
      //must be easier way to index unicode string
      TCHAR c = *(TCHAR *)(&cmdBaseDir[i*2]);
      if(c == L'\\' || c == L'//'){
        nrOfSlashed+=1;
        slashLoc=i;
      }
    }

    if(nrOfSlashed==0){
      _tcscpy(cmdBaseDir, L".");
    }else{
      cmdBaseDir[2*slashLoc] = '\0';
      cmdBaseDir[2*slashLoc+1] = '\0';  
    }


    // *******************************************
    // Get the OS temp location
    // *******************************************
    size = 128;
    TCHAR* tmpPath = (TCHAR*)malloc(1);

    // read until GetModuleFileNameW writes less than its cap (of size)
    do {
        size *= 2;
        free(tmpPath);
        tmpPath = (TCHAR*)malloc(size*2);

        // If , then it's
    } while (GetTempPathW(size, tmpPath) == size);

    TCHAR* batFileName = L"\\inject_bat_wrapper.bat";

    TCHAR* wrapperOutput = (TCHAR*)malloc((_tcslen(tmpPath)+_tcslen(batFileName)+1)*2);
    wrapperOutput[0] = '\0';
    wrapperOutput[1] = '\0';
    _tcscat(wrapperOutput, tmpPath);
    _tcscat(wrapperOutput, batFileName);
    


    FILE *fp;
    fp = _wfopen(wrapperOutput, L"w");

    int results = fputs("@echo off\nSETLOCAL EnableDelayedExpansion\n\n:: ***************************************\n:: With this script Juliawin can bootstrap itself from absolute nothing, but for all\n:: this to work, we can unfortunately not use any external function or scripts yet.\n::\n:: Also, we have no control where this script will come from or the line-endings that the supplier will use.\n:: Github is notorious for replacing windows line endings with unix line endings. Batch is notorious for\n:: breaking gotos and labels when running with unix line endings. This made this script really\n:: difficult to write, since we may not use any goto! Goto considered harmful for a whole different reason.\n:: See https://serverfault.com/questions/429594\n:: ***************************************\n\n\necho                _\necho    _       _ _(_)_     ^|  Documentation: https://docs.julialang.org\necho   (_)     ^| (_) (_)    ^|\necho    _ _   _^| ^|_  __ _   ^|  Run with \"/h\" for help\necho   ^| ^| ^| ^| ^| ^| ^|/ _` ^|  ^|\necho   ^| ^| ^|_^| ^| ^| ^| (_^| ^|  ^|  Unofficial installer for Juliawin\necho  _/ ^|\\__'_^|_^|_^|\\__'_^|  ^|\necho ^|__/                   ^|\necho:\n\nif /i \"%1\" equ \"/help\" (\n    echo Script to download and run the Juliawin installer directly from Github\n    echo:\n    echo Usage:\n    echo   bootstrap-juliawin-from-github [options]\n    echo Options:\n    echo   /h, /help           Print these options\n    echo   /dir ^<folder^>       Set installation directory\n    echo   /force              Overwrite destination without prompting\n    echo   /use-nightly-build  For developer previews and not intended for normal use\n    exit /b 0\n)\n\nset \"force=0\"\nif /i \"%1\" equ \"/force\" set \"force=1\"\nif /i \"%2\" equ \"/force\" set \"force=1\"\nif /i \"%3\" equ \"/force\" set \"force=1\"\nif /i \"%4\" equ \"/force\" set \"force=1\"\n\nset \"use-nightly-build=0\"\nif /i \"%1\" equ \"/use-nightly-build\" set \"use-nightly-build=1\"\nif /i \"%2\" equ \"/use-nightly-build\" set \"use-nightly-build=1\"\nif /i \"%3\" equ \"/use-nightly-build\" set \"use-nightly-build=1\"\nif /i \"%4\" equ \"/use-nightly-build\" set \"use-nightly-build=1\"\n\nset \"custom-directory=0\"\nset \"install-directory=%userprofile%\\Juliawin\"\nif /i \"%1\" equ \"/dir\" set \"install-directory=%~2\" & set \"custom-directory=1\"\nif /i \"%2\" equ \"/dir\" set \"install-directory=%~3\" & set \"custom-directory=1\"\nif /i \"%3\" equ \"/dir\" set \"install-directory=%~4\" & set \"custom-directory=1\"\n\n\n:: ***************************************\n:: Download the master zip directly from github\n:: ***************************************\n:: This is the most general legacy powershell download command. It should be available on any powershell\necho () Download juliawin from github to temp\nset \"juliawinzip=%temp%\\juliawin-%random%%random%.zip\"\ncall powershell -Command \"(New-Object Net.WebClient).DownloadFile('https://github.com/heetbeet/juliawin/archive/main.zip', '%juliawinzip%')\"\n\n\n:: ***************************************\n:: Unzip the master zip into a temporary directory\n:: ***************************************\n:: https://stackoverflow.com/questions/21704041/creating-batch-script-to-unzip-a-file-without-additional-zip-tools\necho () Unzip juliawin to temp\nset \"juliawintemp=%temp%\\juliawin-%random%%random%\"\nmkdir \"%juliawintemp%\" 2>NUL\n\nset \"vbs=%temp%\\_%random%%random%.vbs\"\n\nset vbs_quoted=\"%vbs%\"\n> \"%vbs%\"  echo set objShell = CreateObject(\"Shell.Application\")\n>>\"%vbs%\"  echo set FilesInZip=objShell.NameSpace(\"%juliawinzip%\").items\n>>\"%vbs%\"  echo objShell.NameSpace(\"%juliawintemp%\").CopyHere(FilesInZip)\n\ncscript //nologo \"%vbs%\"\ndel \"%vbs%\" /f /q > nul 2>&1\n\n\n:: ***************************************\n:: Set destination directory\n:: ***************************************\nset \"vbs=%temp%\\_%random%%random%.vbs\"\nset \"bat=%vbs%.bat\"\n\n:: Wow, this is so difficult without a goto...\necho:\necho   [Y]es: choose the default installation directory\necho   [N]o: cancel the installation\necho   [D]irectory: choose my own directory\necho:\nif \"%force%\" equ \"0\" if \"%custom-directory%\" equ \"0\" (\n    for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (\n        if /i \"!defaultinstall!\" neq \"Y\" if /i \"!defaultinstall!\" neq \"N\"  if /i \"!defaultinstall!\" neq \"D\" (\n            set /P defaultinstall=\"Install to %install-directory% [Y/N/D]? \"\n        )\n    )\n)\nif /i \"%defaultinstall%\" EQU \"N\" exit /b -1\n\n> \"%vbs%\" echo set shell=WScript.CreateObject(\"Shell.Application\")\n>>\"%vbs%\" echo set f=shell.BrowseForFolder(0,\"Select Juliwin install directory\",0,\"\")\n>>\"%vbs%\" echo if typename(f)=\"Nothing\" Then\n>>\"%vbs%\" echo    wscript.echo \"set __returnval__=\"\n>>\"%vbs%\" echo    WScript.Quit(1)\n>>\"%vbs%\" echo end if\n>>\"%vbs%\" echo set fs=f.Items():set fi=fs.Item()\n>>\"%vbs%\" echo p=fi.Path:wscript.echo \"set __returnval__=\" ^& p\n\nif /i \"%defaultinstall%\" equ \"D\" (\n    call cscript //nologo \"%vbs%\" > \"%bat%\"\n    call \"%bat%\"\n)\ndel \"%vbs%\" /f /q > nul 2>&1\ndel \"%bat%\" /f /q > nul 2>&1\n\nif /i \"%defaultinstall%\" equ \"D\" (\n    if \"%__returnval__%\" equ \"\" (\n        echo ^(^) Invalid or no directory provided, please restart installer.\n        pause\n        exit /b -1\n    ) else (\n        set \"install-directory=%__returnval__%\"\n    )\n)\n\n\n:: ***************************************\n:: Copy to destination directory\n:: ***************************************\n\n:: Does the destination directory exist?\nif \"%force%\" equ \"0\" (\n    for /F %%i in ('dir /b /a \"%install-directory%\\*\" 2^> nul') do (\n        for %%a in (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1) do (\n            if /i \"!overwrite!\" neq \"Y\" if /i \"!overwrite!\" neq \"N\"  (\n                set /P overwrite=\"Destination is not empty. Overwrite [Y/N]? \"\n            )\n        )\n    )\n)\nif /i \"%overwrite%\" equ \"N\" (\n    echo ^(^) Installation cancelled\n    pause\n    exit /b -1\n)\n\ndel \"%install-directory%\\packages\\julia\" /f /q /s > nul 2>&1\nrobocopy \"%juliawintemp%\\juliawin-main\" \"%install-directory%\" /s /e /mov > nul 2>&1\ndel \"%juliawinzip%\" /f /q > nul 2>&1\n\n\n:: ***************************************\n:: Run the newly acquired local julia bootstrapper\n:: ***************************************\nset \"args=\"\nif \"%force%\" equ \"1\" set \"args=/force\"\nif \"%use-nightly-build%\" equ \"1\" set \"args=%args% /use-nightly-build\"\n\ncall \"%install-directory%\\internals\\scripts\\bootstrap-juliawin-from-local-directory.bat\" %args%\n", fp);
    fclose(fp);

    
    // *******************************************
    // Get into this form: cmd.exe /c ""c:\path\...bat" arg1 arg2 ... "
    // *******************************************
    //TCHAR* cmdLine1  = L"";
    TCHAR* cmdLine2  = L"cmd.exe /c \"";
    TCHAR* cmdLine3  = L"\"";
    //TCHAR* cmdLine4  = L"";
    TCHAR* cmdLine5  = L"\" "; 
    TCHAR* cmdLine6  = cmdArgs;
    TCHAR* cmdLine7 = L"\"";

    int totlen = (_tcslen(cmdLine2)+_tcslen(cmdLine3)+_tcslen(wrapperOutput)+_tcslen(cmdLine5)+_tcslen(cmdLine6)+_tcslen(cmdLine7));

    TCHAR* cmdLine;
    cmdLine = (TCHAR*) malloc((totlen+1)*2);
    cmdLine[0] = '\0';
    cmdLine[1] = '\0';

    _tcscat(cmdLine, cmdLine2);
    _tcscat(cmdLine, cmdLine3);
    _tcscat(cmdLine, wrapperOutput);
    _tcscat(cmdLine, cmdLine5);
    _tcscat(cmdLine, cmdLine6);
    _tcscat(cmdLine, cmdLine7);
    

    // ************************************
    // Prepare and run CreateProcessW
    // ************************************
    PROCESS_INFORMATION pi;
    STARTUPINFO si;
        
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);

    #ifdef NOSHELL
        CreateProcessW(NULL, cmdLine, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi);
    #else
        CreateProcessW(NULL, cmdLine, NULL, NULL, TRUE, NULL,             NULL, NULL, &si, &pi);
    #endif

    // ************************************
    // Return ErrorLevel
    // ************************************
    DWORD result = WaitForSingleObject(pi.hProcess, INFINITE);

    if(result == WAIT_TIMEOUT){return -2;} //Timeout error

    DWORD exitCode=0;
    if(!GetExitCodeProcess(pi.hProcess, &exitCode) ){return -1;} //Cannot get exitcode

    return exitCode; //Correct exitcode
}

