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
    cmdPath[0] = '\0';
    cmdPath[1] = '\0';

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


    //*******************************************
    //Find filename without .exe
    //*******************************************
    TCHAR* cmdName;
    cmdName = (TCHAR*) malloc((_tcslen(cmdPath)+1)*2);
    cmdName[0] = '\0';
    cmdName[1] = '\0';

    _tcscpy(cmdName, cmdPath);

    cmdName = &cmdPath[slashLoc==0?0:slashLoc*2+2];
    int fnameend = _tcslen(cmdName);
    
    // if we run as path\program.exe then we need to truncate the .exe part
    if(0 < fnameend-4 && cmdName[(fnameend-4)*2] == '.'){
        cmdName[(fnameend-4)*2]   = '\0';
        cmdName[(fnameend-4)*2+1] = '\0';
    }

    //_tprintf(cmdName);
    //_tprintf(L"\n");

    //********************************************
    //Bat name to be checked
    //********************************************
    int totlen;

    TCHAR* batFile1  = cmdBaseDir;
    TCHAR* batFile2  = L"\\bin\\";     //First look in bin
    TCHAR* batFile3  = L"\\scripts\\"; //then in scripts
    TCHAR* batFile4  = L"\\src\\";     //then in src
    TCHAR* batFile5  = L"\\";          //then in same dir
    TCHAR* batFile6  = cmdName;
    TCHAR* batFile7  = L".bat";        //Try bat, cmd, vbs, ps1
    TCHAR* batFile8  = L".cmd";
    TCHAR* batFile9  = L".vbs";
    TCHAR* batFile10 = L".ps1";

    totlen = (_tcslen(batFile1)+_tcslen(batFile2)+_tcslen(batFile3)+_tcslen(batFile4)+_tcslen(batFile5)+_tcslen(batFile6)+_tcslen(batFile7)+_tcslen(batFile8)+_tcslen(batFile9)+_tcslen(batFile10));

    TCHAR* batFile;
    batFile = (TCHAR*) malloc((totlen+1)*2);
    batFile[0] = '\0';
    batFile[1] = '\0';

    bool is_powershell = false;
    for(int i=0; i<4; i++){
        for(int j=0; j<4; j++){
            _tcscpy(batFile, batFile1);
            if     (i==0){_tcscat(batFile, batFile2);}
            else if(i==1){_tcscat(batFile, batFile3);}
            else if(i==2){_tcscat(batFile, batFile4);}
            else if(i==3){_tcscat(batFile, batFile5);}
            _tcscat(batFile, batFile6);
            if     (j==0){_tcscat(batFile, batFile7);}
            else if(j==1){_tcscat(batFile, batFile8);}
            else if(j==2){_tcscat(batFile, batFile9);}
            else if(j==3){_tcscat(batFile, batFile10);}
        
            //test if c:\path\to\cmdName.ext exists
            if(0 == _waccess(batFile, 0)){
                if(j==3){
                    is_powershell = true;
                }
                goto breakout;
            }
        }
    }
    system("powershell -command \"[reflection.assembly]::LoadWithPartialName('System.Windows.Forms')|out-null;[windows.forms.messagebox]::Show('Could not find the launcher .bat in bin directory.', 'Execution error')\" ");
    breakout:;

    //_tprintf(batFile);
    //_tprintf(L"\n");

    //*******************************************
    //Get into this form: cmd.exe /c ""c:\path\...bat" arg1 arg2 ... "
    //*******************************************
    TCHAR* cmdLine1  = L"powershell.exe -executionpolicy bypass ";
    TCHAR* cmdLine2  = L"cmd.exe /c \"";
    TCHAR* cmdLine3  = L"\"";
    TCHAR* cmdLine4  = batFile;
    TCHAR* cmdLine5  = L"\" "; 
    TCHAR* cmdLine6  = cmdArgs;
    TCHAR* cmdLine7 = L"\"";

    totlen = (_tcslen(cmdLine1)+_tcslen(cmdLine2)+_tcslen(cmdLine3)+_tcslen(cmdLine4)+_tcslen(cmdLine5)+_tcslen(cmdLine6)+_tcslen(cmdLine7));

    TCHAR* cmdLine;
    cmdLine = (TCHAR*) malloc((totlen+1)*2);
    cmdLine[0] = '\0';
    cmdLine[1] = '\0';

    //Pick vba sequence
    if(is_powershell){
        _tcscpy(cmdLine, cmdLine1);
    }else{
        _tcscat(cmdLine, cmdLine2);
    }
    _tcscat(cmdLine, cmdLine3);
    _tcscat(cmdLine, cmdLine4);
    _tcscat(cmdLine, cmdLine5);
    _tcscat(cmdLine, cmdLine6);
    if(!is_powershell){
        _tcscat(cmdLine, cmdLine7);
    }
    
    //_tprintf(cmdLine);
    //_tprintf(L"\n");

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
