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
    // Find filename without .exe
    // *******************************************
    TCHAR* cmdName;
    cmdName = (TCHAR*) malloc((_tcslen(cmdPath)+1)*2);
    cmdName[0] = '\0';
    cmdName[1] = '\0';

    _tcscpy(cmdName, cmdPath);

    cmdName = &cmdPath[slashLoc==0?0:slashLoc*2+2];
    int fnameend = _tcslen(cmdName);
    
    // if we run as path\program.exe then we need to truncate the .exe part
    if(0 < fnameend-4 &&  cmdName[(fnameend-4)*2] == '.' && 
                         (cmdName[(fnameend-3)*2] == 'e' || cmdName[(fnameend-3)*2] == 'E') &&
                         (cmdName[(fnameend-2)*2] == 'x' || cmdName[(fnameend-2)*2] == 'X') &&
                         (cmdName[(fnameend-1)*2] == 'e' || cmdName[(fnameend-1)*2] == 'E') ){
        cmdName[(fnameend-4)*2]   = '\0';
        cmdName[(fnameend-4)*2+1] = '\0';
    }

    //_tprintf(cmdName);
    //_tprintf(L"\n");

    // ********************************************
    // Bat name to be checked
    // ********************************************
    int totlen;

    TCHAR* batFile1  = cmdBaseDir;
    TCHAR* batFile2  = L"\\bin\\";     //First look in bin
    TCHAR* batFile3  = L"\\scripts\\"; //then in scripts
    TCHAR* batFile4  = L"\\";          //then in same dir
    TCHAR* batFile5  = cmdName;
    TCHAR* batFile6  = L".cmd";        //Try cmd, "", ".sh"
    TCHAR* batFile7  = L"";
    TCHAR* batFile8  = L".sh";

    totlen = (_tcslen(batFile1)+_tcslen(batFile2)+_tcslen(batFile3)+_tcslen(batFile4)+_tcslen(batFile5)+_tcslen(batFile6)+_tcslen(batFile7)+_tcslen(batFile8));

    TCHAR* batFile;
    batFile = (TCHAR*) malloc((totlen+1)*2);
    batFile[0] = '\0';
    batFile[1] = '\0';

    bool is_bash = false;
    for(int i=0; i<3; i++){
        for(int j=0; j<3; j++){
            _tcscpy(batFile, batFile1);
            if     (i==0){_tcscat(batFile, batFile2);}
            else if(i==1){_tcscat(batFile, batFile3);}
            else if(i==2){_tcscat(batFile, batFile4);}

            //if the directory doesn't exist, break early
            if(0 != _waccess(batFile, 0)){ break;}

            _tcscat(batFile, batFile5);

            if     (j==0){_tcscat(batFile, batFile6);}
            //else if(j==1){_tcscat(batFile, batFile7);}
            else if(j==2){_tcscat(batFile, batFile8);}
        
            //test if c:\path\to\cmdName.ext exists
            if(0 == _waccess(batFile, 0)){
                if(j==1 || j ==2){ is_bash = true; }

                goto breakout_launcher;
            }
        }
    }
    system("powershell -command \"[reflection.assembly]::LoadWithPartialName('System.Windows.Forms')|out-null;[windows.forms.messagebox]::Show('Could not find .cmd or .sh with the same filename in bin, scripts, or . directory.', 'Execution error')\" ");
    exit(-1);
    breakout_launcher:;

    //_tprintf(batFile);
    //_tprintf(L"\n");


    // ******************************************
    // Do we have a bash path anywhere in ...\vendor\git\bin\bash.exe
    // ******************************************
    TCHAR* bashPath;
    TCHAR* subBashPath  = L"\\vendor\\git\\bin\\bash.exe";

    bool windowsmode; 

    if(!is_bash){
      goto breakout_bash;  
    } 

    // Test if we are in windows mode or in MinGW/CygWin mode 
    // This is quite elaborately designed:
    //     Returns 1 if uname/grep are available, but not running MinGW/CygWin
    //     Returns 255 if uname and grep are not available
    //     Returns 0 if running from MinGW/CygWin
    
    windowsmode = system("cmd.exe /c \"uname -s 2>nul | grep -e MINGW -e CYGWIN > nul 2>&1\"");
    if(!windowsmode) {
        _tcscpy(bashPath, L"bash.exe");
        goto breakout_bash;
    }
    
    bashPath[0] = '\0';
    bashPath[1] = '\0';
    bashPath = (TCHAR*) malloc((_tcslen(cmdBaseDir)+_tcslen(subBashPath)+3)*2);

    _tcscpy(bashPath, cmdBaseDir);
    _tcscat(bashPath, L"\\");
    totlen = _tcslen(bashPath);

    //128 is maximum number of possible sub-folders
    for(int i=0; i<500; i++){

        slashLoc = -1;
        for(int j=_tcslen(bashPath)-1; j>=0; j--){
          TCHAR c = *(TCHAR *)(&bashPath[j*2]);
          if(c == L'\\' || c == L'//'){
            slashLoc=j;
            break;
          }
        }

        if(slashLoc == -1){
            goto err_bash;
        }

        
        bashPath[2*slashLoc] = '\0';
        bashPath[2*slashLoc+1] = '\0';  

        _tcscat(bashPath, subBashPath);
        
        if(0 == _waccess(bashPath, 0)){
            goto breakout_bash;
        }

        //truncate back and then add \..
        bashPath[2*slashLoc] = '\0';
        bashPath[2*slashLoc+1] = '\0';
    }

    err_bash:;
    system("powershell -command \"[reflection.assembly]::LoadWithPartialName('System.Windows.Forms')|out-null;[windows.forms.messagebox]::Show('Cannot find ...\\vendor\\git\\bin\\bash.exe in any parent directory.', 'Execution error')\" ");
    exit(-1);
    breakout_bash:;


    // *******************************************
    // Get into this form: cmd.exe /c ""c:\path\...bat" arg1 arg2 ... "
    // *******************************************
    //TCHAR* cmdLine?  = L"bash.exe ";

    TCHAR* cmdLine1  = L"cmd.exe /c \"";
    
    TCHAR* cmdLine2  = L"\"";
    TCHAR* cmdLine3  = bashPath;
    TCHAR* cmdLine4  = L"\" ";

    TCHAR* cmdLine5  = L"\"";
    TCHAR* cmdLine6  = batFile;
    TCHAR* cmdLine7  = L"\" "; 
    
    TCHAR* cmdLine8  = cmdArgs;
    
    TCHAR* cmdLine9 = L"\"";

    totlen = (_tcslen(cmdLine1)+_tcslen(cmdLine2)+_tcslen(cmdLine3)+_tcslen(cmdLine4)+_tcslen(cmdLine5)+_tcslen(cmdLine6)+_tcslen(cmdLine7)+_tcslen(cmdLine8)+_tcslen(cmdLine9));

    TCHAR* cmdLine;
    cmdLine = (TCHAR*) malloc((totlen+3)*2);
    cmdLine[0] = '\0';
    cmdLine[1] = '\0';

    //Pick correct cmd sequence sequence
    _tcscat(cmdLine, cmdLine1);
    
    if(is_bash){
        _tcscat(cmdLine, cmdLine2);
        _tcscat(cmdLine, cmdLine3);
        _tcscat(cmdLine, cmdLine4);
    }

    _tcscat(cmdLine, cmdLine5);
    _tcscat(cmdLine, cmdLine6);
    _tcscat(cmdLine, cmdLine7);

    _tcscat(cmdLine, cmdLine8);
    
    _tcscat(cmdLine, cmdLine7);
    
    //_tprintf(cmdLine);
    //_tprintf(L"\n");

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

