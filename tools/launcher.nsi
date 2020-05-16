;================================================================
!addincludedir ""
!define COMMAND __command__
!define PARAMETERS __parameters__
!define WORKDIR ""
;!define Icon ""
!define OutFile __outfile__
;================================================================
# Standard NSIS plugins
!include "WordFunc.nsh"
!include "FileFunc.nsh"
SilentInstall silent
AutoCloseWindow true
ShowInstDetails nevershow
RequestExecutionLevel user
Section ""
Call Execute
SectionEnd
Function Execute
;Set working Directory ===========================
StrCmp ${WORKDIR} "" 0 workdir
System::Call "kernel32::GetCurrentDirectory(i ${NSIS_MAX_STRLEN}, t .r0)"
SetOutPath $0
Goto end_workdir
workdir:
SetOutPath "${WORKDIR}"
end_workdir:
;Get Command line parameters =====================
${GetParameters} $R1
StrCmp "${PARAMETERS}" "" end_param 0
StrCpy $R1 "${PARAMETERS} $R1"
end_param:
;===== Execution =================================
Exec '"${COMMAND}" $R1'
FunctionEnd