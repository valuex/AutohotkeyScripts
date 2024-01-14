
GroupAdd "Browser", "ahk_exe chrome.exe"
GroupAdd "Browser", "ahk_exe msedge.exe"

#HotIf WinActive("ahk_group Browser")
^d::
{
    BookmarkDir:="D:\SoftX\MyBookmarks\"
    url := GetUrl()
    if (url)
    {
        IB := InputBox(url, "BookMarker", "w200 h100")
        if IB.Result = "OK"
        {
            BookmarkName:=BookmarkDir . IB.value . ".url"
            IconFileName:=BookmarkDir . "icon\" . IB.value
            if(FileExist(IconFile:=IconFileName . ".ico"))
            {
                IniWrite url, BookmarkName, "InternetShortcut", "URL"
                IniWrite IconFile,  BookmarkName, "InternetShortcut", "IconFile"
                IniWrite 0, BookmarkName, "InternetShortcut", "IconIndex"
                Target:=url
                LinkFile:=BookmarkName
            }
            else
                IniWrite url, BookmarkName, "InternetShortcut", "URL"

        }
    }
}


; Version: 2023.10.05.1
; https://gist.github.com/7cce378c9dfdaf733cb3ca6df345b140

GetUrl() { ; Active Window Only
    static S_OK := 0, TreeScope_Descendants := 4, UIA_ControlTypePropertyId := 30003, UIA_DocumentControlTypeId := 50030, UIA_EditControlTypeId := 50004, UIA_ValueValuePropertyId := 30045
    hWnd := WinGetID("A")
    IUIAutomation := ComObject("{FF48DBA4-60EF-4201-AA87-54103EEF594E}", "{30CBE57D-D9D0-452A-AB13-7AC5AC4825EE}")
    eRoot := ComValue(13, 0)
    HRESULT := ComCall(6, IUIAutomation, "Ptr", hWnd, "Ptr*", eRoot)
    if (HRESULT != S_OK) {
        throw Error("IUIAutomation::ElementFromHandle()", -1, HRESULT)
    }
    winClass := WinGetClass("A")
    ctrlTypeId := (winClass ~= "Chrome" ? UIA_DocumentControlTypeId : UIA_EditControlTypeId)
    value := Buffer(8 + 2 * A_PtrSize, 0)
    NumPut("UShort", 3, value, 0)
    NumPut("Ptr", ctrlTypeId, value, 8)
    condition := ComValue(13, 0)
    if (A_PtrSize = 8) {
        HRESULT := ComCall(23, IUIAutomation, "UInt", UIA_ControlTypePropertyId, "Ptr", value, "Ptr*", condition)
    } else {
        HRESULT := ComCall(23, IUIAutomation, "UInt", UIA_ControlTypePropertyId, "UInt64", NumGet(value, 0, "UInt64"), "UInt64", NumGet(value, 8, "UInt64"), "Ptr*", condition)
    }
    if (HRESULT != S_OK) {
        throw Error("IUIAutomation::CreatePropertyCondition()", -1, HRESULT)
    }
    eFirst := ComValue(13, 0)
    HRESULT := ComCall(5, eRoot, "UInt", TreeScope_Descendants, "Ptr", condition, "Ptr*", eFirst)
    if (HRESULT != S_OK) {
        throw Error("IUIAutomationElement::GetRootElement()", -1, HRESULT)
    }
    propertyValue := Buffer(8 + 2 * A_PtrSize)
    HRESULT := ComCall(10, eFirst, "UInt", UIA_ValueValuePropertyId, "Ptr", propertyValue)
    if (HRESULT != S_OK) {
        throw Error("IUIAutomationElement::GetCurrentPropertyValue()", -1, HRESULT)
    }
    ObjRelease(eFirst.Ptr)
    ObjRelease(eRoot.Ptr)
    try {
        pProperty := NumGet(propertyValue, 8, "Ptr")
        return StrGet(pProperty, "UTF-16")
    }
}
