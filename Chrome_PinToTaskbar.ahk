#Requires  AutoHotkey >=2.0
#Include  D:\SoftX\AHK_Scripts_V2\UIA-v2-main\Lib\UIA.ahk
StartTime := A_TickCount
npEl := UIA.ElementFromHandle("ahk_exe chrome.exe")
; Find the first Document or Edit control (in Notepad there is only one). The type of the edit area depends on your Windows version, in newer ones it's usually Document type.
btnSetting := npEl.FindElement([{Type:"MenuItem",Name:"Chrome"}]) 

btnSetting.Click() 
menuSave := npEl.FindElement([{Type:"MenuItem",Name:"保存并分享(S)"}]) 
menuSave.Click() 
menuItemCreatShortcut := npEl.FindElement([{Type:"MenuItem",Name:"创建快捷方式(S)…"}]) 
menuItemCreatShortcut.Click() 
; wait for the appreance of create shortcut window
loop 20
{
    try
        btnCreatShortcut := npEl.FindElement([{Type:"Button",Name:"创建"}]) 
    catch as e 
        Sleep 100
}
btnCreatShortcut.Click() 
/*
process the notification window
1- wait for the appearence by FindWindowEx
*/
loop 40
{
    hwnd := DllCall("FindWindowEx", "ptr", 0, "ptr", 0, "str", "Windows.UI.Core.CoreWindow", "str", "新通知")
    if(hwnd)
        break
    Sleep 100
}
;2- click the OK button
loop 40
{
    try
    {
        npEl := UIA.ElementFromHandle(hwnd)
        btnCreatShortcut := npEl.FindElement([{Type:"Button",Name:"是"}])
        btnCreatShortcut.Click()
    }
    catch as e 
        Sleep 100
}
ControlSend("{Enter}",,hwnd) ; an extra click is needed
ElapsedTime := A_TickCount - StartTime ; it takes about 3 seconds
