; forward WM_COPYDATA from VBA to TC
; used together with TC_VBA_SendData.vbs

#Requires AutoHotkey >=2.0
Persistent
; global retVal:=""
MyGui:=Gui()
MyGui.Title := "TC-VBA-Interposer"
MyGui.Show("hide w500 h200")
TC_Interposer()
return
TC_Interposer()
{    ;https://wincmd.ru/forum/viewtopic.php?p=110848&sid=0dfde01723b39e508e96d62c00a7a9b5
        OnMessage(0x4a, TC_Receive_WM_COPYDATA)  ; 0x4a is WM_COPYDATA          
}

TC_Receive_WM_COPYDATA(wParam, lParam, msg, hwnd)
{  
    PtrPos:=NumGet(lParam + A_PtrSize * 2,0,"Ptr")
    retVal:=StrGet(PtrPos)
    if(retVal)
    {
        If WinExist("ahk_class TTOTAL_CMD") ;&& WinActive("ahk_class TTOTAL_CMD")
            TC_SendUserCommand(retVal) 
        else
            MsgBox "TC does NOT exist"
    }     
}

/*
TC_SendUserCommand()
fucntion: send user defined command in the usercmd.ini to TC
agruments: command name <em_xxxx> in usercmd.ini
return: none
*/

TC_SendUserCommand(userCommand) 
{
    ; https://www.autohotkey.com/boards/viewtopic.php?p=538463&sid=4471e03917209854441ac07ebdc70901#p538463
    static dwData := 19781  ;Ord("E") +256*Ord("M")
    static WM_COPYDATA := 0x4A
    cbData := Buffer(StrPut(userCommand, 'CP0'))
    StrPut(userCommand, cbData, 'CP0')
    COPYDATASTRUCT := Buffer(A_PtrSize * 3)
    NumPut('Ptr', dwData, 'Ptr', cbData.size, 'Ptr', cbData.ptr, COPYDATASTRUCT)
    MsgResult:=SendMessage( WM_COPYDATA,, COPYDATASTRUCT,, 'ahk_class TTOTAL_CMD')
    return MsgResult
}
