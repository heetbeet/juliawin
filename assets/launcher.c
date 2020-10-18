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
    //*******************************************
    //Get commanline string as a whole
    //*******************************************
    TCHAR* cmdArgs = GetCommandLineW();
    TCHAR* cmdPath;
    cmdPath = (TCHAR*) malloc((_tcslen(cmdArgs)+1)*2);
    _tcscpy(cmdPath, cmdArgs);


    //*******************************************
    //Split filepath, filename, and commandline
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
    //Find filename without .exe
    //*******************************************
    TCHAR* cmdName;
    cmdName = (TCHAR*) malloc((_tcslen(cmdPath)+1)*2);
    _tcscpy(cmdName, cmdPath);

    cmdName = &cmdPath[slashLoc==0?0:slashLoc*2+2];
    int fnameend = _tcslen(cmdName);
    if(0 < fnameend-4){
        cmdName[(fnameend-4)*2]   = '\0';
        cmdName[(fnameend-4)*2+1] = '\0';
    }

    //_tprintf(L"%s\n", cmdName);

    //********************************************
    //Bat name to be checked
    //********************************************
    int totlen;

    TCHAR* batFile1  = cmdBaseDir;
    TCHAR* batFile2  = L"\\bin\\";
    TCHAR* batFile3  = cmdName;
    TCHAR* batFile4  = L".bat";

    totlen = (_tcslen(batFile1)+ _tcslen(batFile2)+ _tcslen(batFile3)+ _tcslen(batFile4));

    TCHAR* batFile;
    batFile = (TCHAR*) malloc((totlen+1)*2);
    _tcscpy(batFile, batFile1);
    _tcscat(batFile, batFile2);
    _tcscat(batFile, batFile3);
    _tcscat(batFile, batFile4);

    if(0 != _waccess(batFile, 0)){
        system("powershell -command \"[reflection.assembly]::LoadWithPartialName('System.Windows.Forms')|out-null;[windows.forms.messagebox]::Show('Could not find the launcher .bat in bin directory.', 'Execution error')\" ");
    };

    //_tprintf(L"%s\n", batFile);

    //*******************************************
    //Get into this form: cmd.exe /c ""c:\path\...bat" arg1 arg2 ... "
    //*******************************************
    TCHAR* cmdLine1  = L"cmd.exe /c \"";
    TCHAR* cmdLine2  = L"\"";
    TCHAR* cmdLine3  = batFile;
    TCHAR* cmdLine4  = L"\" "; 
    TCHAR* cmdLine5  = cmdArgs;
    TCHAR* cmdLine6 = L"\"";

    totlen = (_tcslen(cmdLine1)+_tcslen(cmdLine2)+_tcslen(cmdLine3)+_tcslen(cmdLine4)+_tcslen(cmdLine5)+_tcslen(cmdLine6));

    TCHAR* cmdLine;
    cmdLine = (TCHAR*) malloc((totlen+1)*2);

    //Pick vba sequence
    _tcscpy(cmdLine, cmdLine1);
    _tcscat(cmdLine, cmdLine2);
    _tcscat(cmdLine, cmdLine3);
    _tcscat(cmdLine, cmdLine4);
    _tcscat(cmdLine, cmdLine5);
    _tcscat(cmdLine, cmdLine6);

    //_tprintf(L"%s\n", cmdLine);

    //************************************
    //Prepare and run CreateProcessW
    //************************************
    PROCESS_INFORMATION pi;
    STARTUPINFO si;
        
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);

    #ifdef NOSHELL
    CreateProcessW(NULL, cmdLine, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi);
    #else
    CreateProcessW(NULL, cmdLine, NULL, NULL, TRUE, NULL,             NULL, NULL, &si, &pi);
    #endif

    //************************************
    //Return ErrorLevel
    //************************************
    DWORD result = WaitForSingleObject(pi.hProcess,15000);

    if(result == WAIT_TIMEOUT){return -2;} //Timeout error

    DWORD exitCode=0;
    if(!GetExitCodeProcess(pi.hProcess, &exitCode) ){return -1;} //Cannot get exitcode

    return exitCode; //Correct exitcode
}