#define _WIN32_WINNT 0x0500
#include <windows.h>
#include <stdbool.h>
#include <tchar.h>

int main( int argc, char ** argv ) {
    //*******************************************
    //Hardcoded parameters to be replaced by Julia
    //*******************************************
    TCHAR* exec = L"__exec__";
    TCHAR* argparams = L"__argparams__";
    bool noShell = true;


    //*******************************************
    //Hide window if we are in noShell mode
    //*******************************************
    //https://stackoverflow.com/a/30243650/1490584
    HWND hWnd = GetConsoleWindow();
    if(noShell){ ShowWindow( hWnd, SW_HIDE ); }


    //*******************************************
    //Get commanline string as a whole
    //*******************************************
    TCHAR* cmdArgs = GetCommandLineW();
    TCHAR* cmdPath;
    cmdPath = (TCHAR*) malloc((_tcslen(cmdArgs)+1)*2);
    _tcscpy(cmdPath, cmdArgs);


    //*******************************************
    //Split filepath and commandline
    //*******************************************
    bool inQuote = false;
    bool isArgs = false;
    int j = 0;

    for(int i=0; i<_tcslen(cmdArgs)+1; i++){
      //must be easier way to index unicode string
      TCHAR c = *(TCHAR *)(&cmdArgs[i*2]);
      
      if(c == L'"'){inQuote = !inQuote;}
      if(c == L' ' && !inQuote){ isArgs = true;}

      if(isArgs){
        cmdPath[i*2]   = '\0';
        cmdPath[i*2+1] = '\0';
      }

      //do for both unicode bits
      cmdArgs[j*2  ] = cmdArgs[i*2  ];
      cmdArgs[j*2+1] = cmdArgs[i*2+1];

      //sync j with i after filepath
      if(isArgs){ j++; }
    }


    //*******************************************
    //Remove quotes around filepath
    //*******************************************
    if(*(TCHAR *)(&cmdPath[0]) == L'"'){
      cmdPath = &cmdPath[2];
    }
    int cmdPathEnd = _tcslen(cmdPath);
    if(*(TCHAR *)(&cmdPath[(cmdPathEnd-1)*2]) == L'"'){
      cmdPath[(cmdPathEnd-1)*2]='\0';
      cmdPath[(cmdPathEnd-1)*2+1]='\0';
    }


    //*******************************************
    //Find basedir of cmdPath
    //*******************************************
    TCHAR* cmdBaseDir;
    cmdBaseDir = (TCHAR*) malloc((_tcslen(cmdPath)+1)*2);
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


    //*******************************************
    //Get into this form: cmd.exe /c ""c:\path\...bat" arg1 arg2 ... "
    //*******************************************
    TCHAR* cmdLine1  = L"cmd.exe /c \"";
    TCHAR* cmdLine2  = L"\"";
    TCHAR* cmdLine3  = cmdBaseDir;
    TCHAR* cmdLine4  = L"\\bin\\";
    TCHAR* cmdLine5  = exec;
    TCHAR* cmdLine6  = L".bat\" ";
    TCHAR* cmdLine7  = argparams;
    TCHAR* cmdLine8  = L" ";
    TCHAR* cmdLine9  = cmdArgs;
    TCHAR* cmdLine10 = L"\"";

    int totlen = (_tcslen(cmdLine1)+ _tcslen(cmdLine2)+ _tcslen(cmdLine3)+ _tcslen(cmdLine4)+
                  _tcslen(cmdLine5)+ _tcslen(cmdLine6)+ _tcslen(cmdLine7)+ _tcslen(cmdLine8)+
                  _tcslen(cmdLine9));

    TCHAR* cmdLine;
    cmdLine = (TCHAR*) malloc((totlen+1)*2);

    //Pick vba sequence
    _tcscpy(cmdLine, cmdLine1);
    _tcscat(cmdLine, cmdLine2);
    _tcscat(cmdLine, cmdLine3);
    _tcscat(cmdLine, cmdLine4);
    _tcscat(cmdLine, cmdLine5);
    _tcscat(cmdLine, cmdLine6);
    _tcscat(cmdLine, cmdLine7);
    _tcscat(cmdLine, cmdLine8);
    _tcscat(cmdLine, cmdLine9);
    _tcscat(cmdLine, cmdLine10);

    //_tprintf(L"%s\n", cmdLine);

    //************************************
    //Prepare and run CreateProcessW
    //************************************
    PROCESS_INFORMATION pi;
    STARTUPINFO si;
        
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);

    int bResult = CreateProcessW(NULL,
      cmdLine, NULL, NULL, TRUE, NULL, NULL, NULL, &si, &pi);

    //************************************
    //Return ErrorLevel
    //************************************
    DWORD result = WaitForSingleObject(pi.hProcess,15000);

    if(noShell){ ShowWindow( hWnd, SW_SHOW); }

    if(result == WAIT_TIMEOUT){return -2;} //Timeout error

    DWORD exitCode=0;
    if(!GetExitCodeProcess(pi.hProcess, &exitCode) ){return -1;} //Cannot get exitcode

    return exitCode; //Correct exitcode
}