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
    if(0 < fnameend-4 && cmdName[(fnameend-4)*2] == '.'){
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
    TCHAR* batFile4  = L"\\src\\";     //then in src
    TCHAR* batFile5  = L"\\";          //then in same dir
    TCHAR* batFile6  = cmdName;
    TCHAR* batFile7  = L".bat";        //Try bat, cmd, vbs, ps1
    TCHAR* batFile8  = L".cmd";
    TCHAR* batFile9  = L".vbs";
    TCHAR* batFile10 = L".ps1";
    TCHAR* batFile11 = L".py";

    totlen = (_tcslen(batFile1)+_tcslen(batFile2)+_tcslen(batFile3)+_tcslen(batFile4)+_tcslen(batFile5)+_tcslen(batFile6)+_tcslen(batFile7)+_tcslen(batFile8)+_tcslen(batFile9)+_tcslen(batFile10)+_tcslen(batFile11));

    TCHAR* batFile;
    batFile = (TCHAR*) malloc((totlen+1)*2);
    batFile[0] = '\0';
    batFile[1] = '\0';

    bool is_powershell = false;
    bool is_python = false;
    for(int i=0; i<4; i++){
        for(int j=0; j<5; j++){
            _tcscpy(batFile, batFile1);
            if     (i==0){_tcscat(batFile, batFile2);}
            else if(i==1){_tcscat(batFile, batFile3);}
            else if(i==2){_tcscat(batFile, batFile4);}
            else if(i==3){_tcscat(batFile, batFile5);}

            //if the directory doesn't exist, break early
            if(0 != _waccess(batFile, 0)){ break;}

            _tcscat(batFile, batFile6);
            if     (j==0){_tcscat(batFile, batFile7);}
            else if(j==1){_tcscat(batFile, batFile8);}
            else if(j==2){_tcscat(batFile, batFile9);}
            else if(j==3){_tcscat(batFile, batFile10);}
            else if(j==4){_tcscat(batFile, batFile11);}
        
            //test if c:\path\to\cmdName.ext exists
            if(0 == _waccess(batFile, 0)){
                if(j==3){
                    is_powershell = true;
                }else if(j==4){
                    is_python = true;
                }
                goto breakout_launcher;
            }
        }
    }
    system("powershell -command \"[reflection.assembly]::LoadWithPartialName('System.Windows.Forms')|out-null;[windows.forms.messagebox]::Show('Could not find .bat, .cmd, .vbs, .ps1 or .py with the same filename in bin, scripts, src, or . directory.', 'Execution error')\" ");
    exit(-1);
    breakout_launcher:;

    //_tprintf(batFile);
    //_tprintf(L"\n");


    // ******************************************
    // Do we have a Python path anywhere in ...\bin\python\python.exe
    // ******************************************
    TCHAR* pythonPath;
    if(!is_python){
        goto breakout_python;
    }else{
        // add 500 for safety (windows paths cap at 260)
        pythonPath = (TCHAR*) malloc((500+1)*2);
        pythonPath[0] = '\0';
        pythonPath[1] = '\0';

        _tcscpy(pythonPath, cmdBaseDir);
        totlen = _tcslen(pythonPath);

        //128 is maximum number of possible sub-folders
        for(int i=0; i<128; i++){
            _tcscat(pythonPath, L"\\bin\\python\\python.exe");

            if(0 == _waccess(pythonPath, 0)){
                goto breakout_python;
            }

            //truncate back and then add \..
            pythonPath[totlen*2+1] = '\0';
            pythonPath[totlen*2+2] = '\0';
            _tcscat(pythonPath, L"\\..");
            totlen+=3;
        }
    }
    system("powershell -command \"[reflection.assembly]::LoadWithPartialName('System.Windows.Forms')|out-null;[windows.forms.messagebox]::Show('Cannot find *\\bin\\python\\python.exe in any parent directory.', 'Execution error')\" ");
    exit(-1);
    breakout_python:;


    // *******************************************
    // Get into this form: cmd.exe /c ""c:\path\...bat" arg1 arg2 ... "
    // *******************************************
    //TCHAR* cmdLine?  = L"python.exe ";
    TCHAR* cmdLine1  = L"powershell.exe -executionpolicy bypass ";
    TCHAR* cmdLine2  = L"cmd.exe /c \"";
    TCHAR* cmdLine3  = L"\"";
    TCHAR* cmdLine4  = batFile;
    TCHAR* cmdLine5  = L"\" "; 
    TCHAR* cmdLine6  = cmdArgs;
    TCHAR* cmdLine7 = L"\"";

    totlen = (_tcslen(cmdLine1)+_tcslen(cmdLine2)+_tcslen(cmdLine3)+_tcslen(cmdLine4)+_tcslen(cmdLine5)+_tcslen(cmdLine6)+_tcslen(cmdLine7));
    if(is_python){ totlen+=_tcslen(pythonPath); }

    TCHAR* cmdLine;
    cmdLine = (TCHAR*) malloc((totlen+1)*2);
    cmdLine[0] = '\0';
    cmdLine[1] = '\0';

    //Pick correct cmd sequence sequence
    if(is_powershell){
        _tcscpy(cmdLine, cmdLine1);
    }else if(is_python){
        // we have enough leeway length for characters `"" `
        _tcscat(cmdLine, L"\"");
        _tcscat(cmdLine,pythonPath);
        _tcscat(cmdLine, L"\" ");
    }else{
        _tcscat(cmdLine, cmdLine2);
    }
    _tcscat(cmdLine, cmdLine3);
    _tcscat(cmdLine, cmdLine4);
    _tcscat(cmdLine, cmdLine5);
    _tcscat(cmdLine, cmdLine6);
    if(is_powershell || is_python){
    }else{
        _tcscat(cmdLine, cmdLine7);
    }
    
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

