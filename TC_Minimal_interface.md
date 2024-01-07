This is the new version of minimum TC interface  
no caption, no menu bar, no button bar  
only two panels!  
![image](https://github.com/valuex/AutohotkeyScripts/assets/3627812/42faa132-acd0-4f57-b05c-a484ae0165e7)



``` autohotkey
; 1-toggle caption
Style := WinGetStyle("ahk_class TTOTAL_CMD")
; https://learn.microsoft.com/en-us/windows/win32/winmsg/window-styles
; 0x00C00000 WS_CAPTION
; Style & 0x00C00000 is 0, there is no caption
if(Style & 0x00C00000) 
    WinSetStyle("-0xC00000", "ahk_class TTOTAL_CMD")    ;hide caption
else
    WinSetStyle("+0xC00000", "ahk_class TTOTAL_CMD")    ; show caption

; 2- toggle meanu bar by user-defined command
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
WinCMD_ini:="D:\SoftX\TotalCommander11\WinCMD.ini"
menuName:=IniRead(WinCMD_ini,"Configuration","Mainmenu")
if(InStr(menuName,"Wcmd_chn"))
    SendTCUserCommand("em_hidemenu")
else
    SendTCUserCommand("em_showmenu")
;3- toggle other objects by using TC internal command
SendMessage(1075, 2907, 0, , "ahk_class TTOTAL_CMD") ;Show/hide current directory
SendMessage(1075, 2916, 0, , "ahk_class TTOTAL_CMD") ;Show/hide folder tabs
SendMessage(1075, 2908, 0, , "ahk_class TTOTAL_CMD") ;;Show/hide tab header (sorting)
SendMessage(1075, 2909, 0, , "ahk_class TTOTAL_CMD") ;Show/hide status bar
SendMessage(1075, 2901, 0, , "ahk_class TTOTAL_CMD") ;cm_VisButtonBar=2901;Show/hide button bar
SendMessage(1075, 2944, 0, , "ahk_class TTOTAL_CMD") ;cm_VisButtonBar2=2944;Show/hide vertical button bar


SendTCUserCommand(userCommand) 
{
    ; https://www.autohotkey.com/boards/viewtopic.php?p=538463&sid=4471e03917209854441ac07ebdc70901#p538463
    static EM := 19781
    static WM_COPYDATA := 0x4A
    ansiBuf := Buffer(StrPut(userCommand, 'CP0'))
    StrPut(userCommand, ansiBuf, 'CP0')
    COPYDATASTRUCT := Buffer(A_PtrSize * 3)
    NumPut('Ptr', EM, 'Ptr', ansiBuf.size, 'Ptr', ansiBuf.ptr, COPYDATASTRUCT)
    MsgResult:=SendMessage( WM_COPYDATA,, COPYDATASTRUCT,, 'ahk_class TTOTAL_CMD')
    return MsgResult
}
```
