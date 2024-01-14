
/*
TC_Minimum_Mode() 
fucntion: hide TC's title bar, menu bar, button bar, etc
agruments: path of WinCMD.ini
return: none
*/

TC_Minimum_Mode(WinCMD_ini)
{
    ; 1-toggle caption
    ; https://learn.microsoft.com/en-us/windows/win32/winmsg/window-styles
    ; 0x00C00000 WS_CAPTION
    ; Style & 0x00C00000 is great than 0, caption exists
    TC_Class:="ahk_class TTOTAL_CMD"
    Style := WinGetStyle(TC_Class)
    if(Style & 0x00C00000) 
        WinSetStyle("-0xC00000", TC_Class)    ;hide caption

    ; 2- toggle meanu bar
    ; user_command to hide menu https://www.ghisler.ch/board/viewtopic.php?t=72307
    ; define those contents in <usercmd.ini>
    /*
    [em_hidemenu]
    cmd=OPENLANGUAGEFILE 
    param="%|commander_path|\Language\0.mnu"
    [em_showmenu]
    cmd=OPENLANGUAGEFILE 
    param="%|commander_path|\Language\Wcmd_chn.mnu"
    */

    menuName:=IniRead(WinCMD_ini,"Configuration","Mainmenu")
    if(InStr(menuName,"Wcmd_chn"))  ; use translated menu, then hide it
        TC_SendUserCommand("em_hidemenu")

    ;3- toggle other objects by using TC internal command
    Check2Hide("ButtonBar", 2901)               ;cm_VisButtonBar=2901;Hide button bar
    Check2Hide("DriveBar1", 2902)               ;cm_VisButtonBar=2902;hide drive button bars
    Check2Hide("DriveBar2", 2903)               ;cm_VisTwoDriveButtons=2903;hide two drive bars
    Check2Hide("ButtonBarVertical", 2944)       ;cm_VisButtonBar2=2944;Hide vertical button bar
    Check2Hide("DirectoryTabs", 2916)           ;hide folder tabs
    Check2Hide("DriveCombo", 2906)              ;cm_VisDriveCombo=2906; hide drive combobox
    Check2Hide("CurDir", 2907)                  ;Hide current directory
    Check2Hide("TabHeader", 2908)               ;Hide tab header (sorting)
    Check2Hide("CmdLine", 2910)                 ;Hide Command line
    Check2Hide("KeyButtons", 2911)              ;cm_VisKeyButtons=2911; hide function key buttons

    ; Check2Hide("DriveBarFlat", 2904)      ; cm_VisFlatDriveButtons=2904;Buttons: Flat/normal mode
    ; Check2Hide("InterfaceFlat", 2905)     ; cm_VisFlatInterface=2905;Interface: Flat/normal mode
    ; Check2Hide("BreadCrumbBar", 2911)     ; cm_VisBreadCrumbs=2926;Show/hide Breadcrumb bar
    ; Check2Hide("StatusBar", 2909)         ;cm_VisStatusBar=2909;Show/hide status bar


    Check2Hide(Item, em_code)
    {
        ItemShown:=IniRead(WinCMD_ini,"Layout",Item)
        if(ItemShown)
            SendMessage(1075, em_code, 0, , TC_Class) 
    }
}

TC_FocusOnLeftFile(FileFullPath)
{
    SplitPath FileFullPath,,&DirPath
    TC_SetLeftPath(DirPath) 
    AcSide:=TC_GetActiveSide()
    If(AcSide:="R")
        SendMessage(0x433,4001,0,,"ahk_class TTOTAL_CMD") ;cm_FocusLeft=4001;Focus on left file list
    TC_OpenAndSelect(FileFullPath)
    WinActivate("ahk_class TTOTAL_CMD")
}
TC_FocusOnRightFile(FileFullPath)
{
    SplitPath FileFullPath,,&DirPath
    TC_SetRightPath(DirPath) 
    AcSide:=TC_GetActiveSide()
    If(AcSide:="L")
        SendMessage(0x433,4002,0,,"ahk_class TTOTAL_CMD") ;cm_FocusLeft=4002;Focus on right file list
    TC_OpenAndSelect(FileFullPath)
    WinActivate("ahk_class TTOTAL_CMD")
}
/*
TC_SetLeftPath(inpath) | TC_SetRightPath(inpath)
fucntion: set path in TC's left / right side
agruments: directory path
return: none
*/

; https://www.ghisler.ch/board/viewtopic.php?p=277574#256573
/*
The complete syntax is in fact : 
<Left>`r<Right>\0                       ; eg:  D:\xxx\   `r  E:\xxx\  \0
<Source>`r<Target>\0S                   ; eg:  D:\xxx\   `r  E:\xxx\  \0
<Left>`r<Right>\0T open in new Tab      ; eg:  D:\xxx\   `r  E:\xxx\  \0T
*/
TC_SetLeftPath(DirPath) 
{
    ; DirPath should be ended with \
    newPath:=DirPath . "`r"
    TC_SetPath(newPath) 
}
TC_SetRightPath(DirPath)
{
    ; DirPath should be ended with \
    newPath:="`r" . DirPath . "\0"
    TC_SetPath(newPath) 
}
TC_SetPath(userCommand) 
{
    ; https://www.autohotkey.com/boards/viewtopic.php?p=538463&sid=4471e03917209854441ac07ebdc70901#p538463
    static dwData := 17475  ;;Ord("C") +256*Ord("D")
    static WM_COPYDATA := 0x4A
    cbData := Buffer(StrPut(userCommand, 'CP0'))
    StrPut(userCommand, cbData, 'CP0')
    COPYDATASTRUCT := Buffer(A_PtrSize * 3)
    NumPut('Ptr', dwData, 'Ptr', cbData.size, 'Ptr', cbData.ptr, COPYDATASTRUCT)
    MsgResult:=SendMessage( WM_COPYDATA,, COPYDATASTRUCT,, 'ahk_class TTOTAL_CMD')
    return MsgResult
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

/*
TC_OpenAndSelect()
fucntion: open TC, navigate to the dir and get the file selected
agruments: file full path
return: none
*/

TC_OpenAndSelect(FilePath)
{
    SavedClip:=ClipboardAll()
    A_Clipboard:=""
    A_Clipboard:=Trim(FilePath)
    Sleep 300
    Critical
    SendMessage(0x433,2033,0,,"ahk_class TTOTAL_CMD")   ; cm_LoadSelectionFromClip=2033;Read file selection from clipboard
    ToolTip A_Clipboard . "-1"
    SendMessage(0x433,2049,0,,"ahk_class TTOTAL_CMD")   ; cm_GoToFirstEntry=2049;Place cursor on first folder or file
    SendMessage(0x433,2053,0,,"ahk_class TTOTAL_CMD")   ; cm_GoToNextSelected=2053;Go to next selected file
    SendMessage(0x433,524,0,,"ahk_class TTOTAL_CMD")    ; cm_ClearAll=524;Unselect all (files+folders)
    A_Clipboard:=SavedClip
    SavedClip:=""
}



/*
TC_GetActiveSide()
fucntion: get the active side of TC
return: L or R
*/

TC_GetActiveSide()
{
    ;https://wincmd.ru/forum/viewtopic.php?p=110848&sid=0dfde01723b39e508e96d62c00a7a9b5
    If WinExist("ahk_class TTOTAL_CMD") ;&& WinActive("ahk_class TTOTAL_CMD")
    {
        OnMessage(0x4a, TC_Receive_WM_COPYDATA)  ; 0x4a is WM_COPYDATA
        TC_Send_WM_COPYDATA(cmd:="A")
        return retVal
    }
    else
        return "TC does NOT exist"
}

TC_Send_WM_COPYDATA(cmd){
    
    Critical
    if(!RegExMatch(cmd, "^(A|[LRST][PCIN]?)$"))
        return
    static dwData:=Ord("G") + 256 * Ord("W")
    static WM_COPYDATA := 0x4A
    cbData := Buffer(StrPut(cmd, 'CP0'))
    StrPut(cmd, cbData, 'CP0')
    CopyDataStruct:=Buffer(A_PtrSize * 3)
    NumPut('Ptr', dwData, 'Ptr', cbData.size, 'Ptr', cbData.ptr, COPYDATASTRUCT)
    MsgResult:=SendMessage(WM_COPYDATA, A_ScriptHwnd, CopyDataStruct, , "ahk_class TTOTAL_CMD")
    return MsgResult
}

TC_Receive_WM_COPYDATA(wParam, lParam, msg, hwnd)
{
  global retVal
  PtrPos:=NumGet(lParam + A_PtrSize * 2,0,"Ptr")
  retVal:=StrGet(PtrPos)
  return 1
}
