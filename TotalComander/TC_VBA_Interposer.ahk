#Requires AutoHotkey >=2.0
#Include  C:\Users\wei_x\Desktop\Chrome_Download\lib\TC_AHK_Lib.ahk
Persistent
; global retVal:=""
MyGui:=Gui()
MyGui.Title := "TC-VBA-Interposer"
MyGui.Show("hide w500 h200")
TC_Interposer()
return
TC_Interposer()
{    ;https://wincmd.ru/forum/viewtopic.php?p=110848&sid=0dfde01723b39e508e96d62c00a7a9b5
        OnMessage(0x4a, TC_Receive_WM_COPYDATA1)  ; 0x4a is WM_COPYDATA          
}

TC_Receive_WM_COPYDATA1(wParam, lParam, msg, hwnd)
{  
    PtrPos:=NumGet(lParam + A_PtrSize * 2,0,"Ptr")
    retVal:=StrGet(PtrPos)
    if(retVal)
    {
        ;winTitle:=WinGetTitle("ahk_id " . hwnd)
        ; winTitle:=WinGetProcessName("ahk_id " . hwnd)
        ; MsgBox winTitle

        If WinExist("ahk_class TTOTAL_CMD") ;&& WinActive("ahk_class TTOTAL_CMD")
            ForwardCMD(retVal) 
        else
            MsgBox "TC does NOT exist"
    }     
}

ForwardCMD(strCMD)
{
    if(InStr(strCMD,"em_SelectFile")=1)
    {
        NewCMD:=SubStr(strCMD,StrLen("em_SelectFile")+1)
        NewCMD:=Trim(NewCMD)
        NewCMDArr:=StrSplit(NewCMD, "|")
        FilePath:=NewCMDArr[1]
        if(FileExist(FilePath))
        {
            TC_FocusOnLeftFile(FilePath)
            WinActivate(NewCMDArr[2])
        }
    }
}
