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

    int results = fputs("__batchscript__", fp);
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

