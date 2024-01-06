

; PasteTo
; Paste the seclted file content to text editor.
; In Everything, select one source code file, then press the corresponding hotkey.
; this script will copy the file content and paste the content to the previous editor.
; Date: 2024-1-6
; Author: Valuex

#Requires AutoHotkey >=2.0
#SingleInstance Ignore  ; only one instance is allowed
if(A_Args.Length>1)
    ExitApp
FileFullPath:=A_Args[1]
SplitPath FileFullPath,,,&FileExt
TxtExt:=FileRead("TxtExtension.txt")
ArrExt:=StrSplit(TxtExt,"`n","`r")
ThisWinID:=WinGetID("A")

loop ArrExt.Length
{
    ThisExt:=Trim(ArrExt[A_Index])
    if (ThisExt="")
        continue
    if (ThisExt=FileExt)
    {
        FileContent:=FileRead(FileFullPath)
        Send "{ALT DOWN}{TAB}{ALT UP}"
        WaitForAltWin(ThisWinID, 5)
        SendStrByPaste(FileContent)
    }
}

WaitForAltWin(CurWinID, iSeconds)
{
    N:=iSeconds*10
    loop N {
        Sleep 100
        AcID:=WinGetID("A")
        if(AcID!=CurWinID)
            return
    }
    MsgBox "The attempt to switch window failed."
}

SendStrByPaste(strContent)
{
    ClipTemp:=ClipboardAll()
    A_Clipboard:=""
    A_Clipboard:=strContent
    if !ClipWait(2)
    {
        MsgBox "The attempt to copy text onto the clipboard failed."
        return
    }
    Send "^v"
    PasteWait()
    Sleep 500
    A_Clipboard:=ClipTemp  
}
PasteWait(timeout:=1000){ ; (not working yet for at least one user on Win10 x64)
    ; https://www.autohotkey.com/boards/viewtopic.php?f=5&t=37209&p=171360#p271287
    start_tick := A_TickCount ; time since last reboot in milliseconds
    while DllCall("user32\GetOpenClipboardWindow", "Ptr") {
        if(A_TickCount - start_tick) > timeout {
            Break
            }
    	Sleep 100
        }
}
