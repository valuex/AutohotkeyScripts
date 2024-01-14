#Requires Autohotkey 2.0

#Include .\lib\Class_SQLiteDB.ahk
#Include .\lib\TC_AHK_Lib.ahk

global db_file, db_here
global ExePath_7Z := IniRead("SQLiteDB.ini", "Main", "7z")
global ExePath_7ZG := IniRead("SQLiteDB.ini", "Main", "7zg")
global ArrFullPath := Array()
Exist_7z := FileExist(ExePath_7Z)
Exist_7zg := FileExist(ExePath_7ZG)
if (!ExePath_7Z or !ExePath_7ZG)
{
    MsgBox "No 7z or 7zg file found`nset in SQLiteDB.ini"
    return
}

db_file := IniRead("SQLiteDB.ini", "Main", "db_file")
db_here := A_ScriptDir . "\DownloadHistory.db"
if (!FileExist(db_file))
{
    MsgBox "No History sqlite databse file found`nset in SQLiteDB.ini"
    return
}

MyGui := Gui("+AlwaysOnTop +ToolWindow")
MyGui.SetFont("s14", "Verdana")
CurrentHwnd := MyGui.Hwnd
LVS_SHOWSELALWAYS := 8 ; Seems to have the opposite effect with Explorer theme, at least on Windows 11.
LV_BGColor := Format(' Background{:x}', DllCall("GetSysColor", "int", 15, "int"))  ; background color of listview item when get selected by up & down arrow
LV := MyGui.Add("ListView", "r20 w700 -Multi -Hdr " LVS_SHOWSELALWAYS LV_BGColor, ["FileFullPath"])
OnMessage(WM_KEYDOWN := 0x100, KeyDown)
OnMessage(WM_ACTIVATE := 0x0006, LoseFocus2Close)
#HotIf WinActive("ahk_exe chrome.exe")
!d::
{
    GetDownloadInfo()
    ListDownloadFiles()
    MyGui.Show("Center")
    WinWaitActive("ahk_id " . CurrentHwnd)
    IME_To_EN(CurrentHwnd)

}
return

GetDownloadInfo()
{
    ; global ArrFullPath
    if (FileExist(db_here))
        FileDelete(db_here)
    FileCopy db_file, db_here
    DB := SQLiteDB()
    DB.OpenDB(db_here)
    sql_cmd := 'SELECT current_path FROM downloads WHERE current_path!="" ORDER BY end_time DESC;'
    results := IndexDb(DB, sql_cmd)
    If !DB.CloseDB()
        MsgBox("Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, "SQLite Error", 16)
    IndexResults := StrSplit(results, '`n')
    loop IndexResults.Length
    {
        ThisFile := Trim(IndexResults[A_Index])
        if (FileExist(ThisFile))
        {
            ArrFullPath.Push(ThisFile)
        }
        if (ArrFullPath.Length = 20)
            break
    }
    IndexDb(DB, sql_cmd)
    {
        ; global DB
        If !DB.Query(sql_cmd, &query_result)
        {
            MsgBox("SQLite QUERY Error`n`nMessage: " . DB.ErrorMsg . "`nCode: " . DB.ErrorCode . "`nFile: " . db_file . "`nQuery: " . sql_cmd)
            return 0
        }

        search_result := ''
        Loop
        {
            result := query_result.Next(&row)
            If !result
            {
                MsgBox("SQLite NEXT Error`n`nMessage: " . DB.ErrorMsg . "`nCode: " . DB.ErrorCode)
                return 0
            }
            If result = -1
            {
                Break
            }
            Loop query_result.ColumnCount
            {
                search_result .= row[A_Index] . A_Tab
            }
            search_result .= '`n'
        }
        query_result.Free()
        search_result := SubStr(search_result, 1, StrLen(search_result) - 1) ; remove last `n
        return search_result
    }
}


ListDownloadFiles()
{
    global LV
    CountNumber := LV.GetCount()
    if (CountNumber >= 1)
    {
        LV.Delete
        try
            Success := IL_Destroy(ImageListID)
    }
    FileNum := ArrFullPath.Length
    ImageListID := IL_Create(FileNum)
    LV.SetImageList(ImageListID)

    loop FileNum
    {
        ThisFileFullPath := Trim(ArrFullPath[A_Index])

        if ( not FileExist(ThisFileFullPath))
            continue
        SplitPath ThisFileFullPath, , , &ThisFileExt
        ThisFileExt := Trim(ThisFileExt)
        IconFile := IconForFile(ThisFileExt)
        IL_Add(ImageListID, IconFile)
        LV.Add("Icon" . A_Index, ThisFileFullPath)
    }
    LV.Modify("1", "Select Focus")
}
IME_To_EN(hwnd)
{    
    ; https://www.cnblogs.com/yf-zhao/p/16018481.html
    ; hWnd := CurrentHwnd ;winGetID("A") ;
    ; result := SendMessage(
    ;     0x283, ; Message : WM_IME_CONTROL
    ;     0x001, ; wParam : IMC_GETCONVERSIONMODE
    ;     0,     ; lParam ： (NoArgs)
    ;     ,      ; Control ： (Window)
    ;            ; Retrieves the default window handle to the IME class.
    ;     "ahk_id " DllCall("imm32\ImmGetDefaultIMEWnd", "Uint", hWnd, "Uint")
    ; )
    ; if(result!=0)
    ; {
        WinWaitActive("ahk_id " . CurrentHwnd)
        send "{Shift}"
    ; }

}
IconForFile(FileExt)
{
    if (FileExt = "exe")
    {
        return A_ScriptDir . "\icon\exe.ico"
    }
    else if (FileExt = "")
        return A_ScriptDir . "\icon\NoExt.ico"
    else
    {
        iconFile := A_ScriptDir . "\icon\" . FileExt . ".ico"
        if (FileExist(iconFile))
            return iconFile
        else
            return A_ScriptDir . "\icon\General.ico"
    }
}
KeyDown(wParam, lParam, nmsg, Hwnd)
{
    static VK_ESC := 0x1B
    static VK_Enter := 0x0D
    static VK_S := 0x53

    gc := GuiCtrlFromHwnd(Hwnd)

    if (wParam = VK_ESC)
    {
        WinClose("ahk_id " . CurrentHwnd)
    }
    else if (wParam = VK_S)
    {
        FileUnderCursor := GetUnderCursor()
        SplitPath FileUnderCursor, , , &ThisFileExt
        if (ThisFileExt!="" and InStr("zip|rar|7z", ThisFileExt))
        {
            SmartUnzip(FileUnderCursor)
            MyGui.Hide
        }
        else
        {
            MyGui.Hide
            TC_FocusOnLeftFile(FileUnderCursor)
            Send "{WheelDown 4}"
        }
    }
    else if (gc is Gui.ListView and wParam = VK_Enter)
    {
        ; press Enter in the ListView to activate corresponding window
        FileFullPath := GetUnderCursor()
        WinClose()
        Run FileFullPath
        return true
    }

    GetUnderCursor()
    {
        global LV
        RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
        Loop
        {
            RowNumber := LV.GetNext(RowNumber, "F")  ; Resume the search at the row after that found by the previous iteration.
            if not RowNumber  ; The above returned zero, so there are no more selected rows.
                break
            FileFullPath := LV.GetText(RowNumber, 1)
        }
        return FileFullPath
    }

}
LoseFocus2Close(wParam, lParam, nmsg, hwnd)
{
    if( hwnd && !wParam)
    {
        MyGui.Hide
        try
        {
            WinClose("ahk_id " . hwnd)
        }
    }
    return true
}
Str_LastCharPos(InputStr, InChar)
{
    return InStr(InputStr, InChar, 1, -1)
}


SmartUnzip(FileFullPath)
{

    SmartUnzip_MultiFileIndicator := 0
    SmartUnzip_HasFolderIndicator := 0
    SmartUnzip_Level1FolderName :=
        SmartUnzip_FolderNameA :=
        SmartUnzip_FolderNameB :=
        ZipFileList := A_Temp . "\smartunzip_" . A_Now . ".txt"
    global ExePath_7Z
    global ExePath_7ZG
    SplitPath FileFullPath, , &ZipFileDir, , &ZipFileName
    If (InStr(ExePath_7Z, " ") and SubStr(ExePath_7Z, 1, 1) != chr(34))
        ExePath_7Z := chr(34) . ExePath_7Z . chr(34)
    qutoed_ZipFileList := chr(34) . ZipFileList . chr(34)
    quoted_FileFullPath := chr(34) . FileFullPath . chr(34)
    run_cmd := ExePath_7Z . " l " . quoted_FileFullPath . " > " . qutoed_ZipFileList
    quoted_run_cmd := chr(34) . run_cmd . chr(34)

    run_cmd := A_ComSpec . " /c " . quoted_run_cmd
    ExitCode := RunWait(run_cmd)
    ;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    IsFirstRowOfFileList := 0
    IsLastRowOfFileList := 0
    nFolder := 0
    nFile := 0
    loop read ZipFileList
    {
        If (RegExMatch(A_LoopReadLine, "^(\-{4}.*\-)$"))  ; look for line starts with ---- and ends with -
        {

            If (IsFirstRowOfFileList = 0)
            {
                IsFirstRowOfFileList := 1
                Continue
            }
            Else
            {
                IsLastRowOfFileList := 1
                Break
            }
        }
        if (IsFirstRowOfFileList = 0)	; has not found the starting line, contiune
        {
            Continue
        }

        If (instr(A_LoopReadLine, "\"))   ; skip the line which is not the first level
        {
            Continue
        }
        If (instr(A_LoopReadLine, "D...."))
        {
            nFolder := nFolder + 1
            SmartUnzip_FolderNameA := SubStr(A_LoopReadLine, 54)
            ; StringMid,,A_LoopReadLine,54,InStr(A_loopreadline,"\")-54
        }
        Else If (instr(A_LoopReadLine, "....A"))
        {
            nFile := nFile + 1
        }
    }
    ;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ; TargetFolder: the foler would be Unzipped to
    If (nFile = 1 && nFolder = 0)   ;Only ONE single file in Levle1 of the Achrive file
    {
        run_cmd := ExePath_7ZG . " x " . chr(34) . FileFullPath . chr(34) . " -o" . chr(34) . ZipFileDir . chr(34)
        RunWait run_cmd    ;user can choose write or rename using 7z if there is any confiliction
        ; MsgBox ZipFileDir . "-1"
        TC_SetLeftPath(ZipFileDir)
    }
    Else If (nFile = 0 && nFolder = 1)   ;Only ONE single folder in Level1 of the Achrive file
    {
        If (FileExist(ZipFileDir . "\" . SmartUnzip_FolderNameA))   ;if TargetFolder exists, create new folder named as TargetFolder (n)
        {
            Loop
            {
                SmartUnZip_NewFolderName := ZipFileDir . "\" . SmartUnzip_FolderNameA . " (" . A_Index . ")"
                If !FileExist(SmartUnZip_NewFolderName)
                {
                    dbq_name := chr(34) . SmartUnZip_NewFolderName . chr(34)
                    run_cmd := ExePath_7ZG . " x " . chr(34) . FileFullPath . chr(34) . " -o" . dbq_name
                    RunWait run_cmd
                    ; MsgBox dbq_name . "-2"
                    TC_SetLeftPath(SmartUnZip_NewFolderName)
                    break
                }
            }
        }
        Else  ; if TargetFolder does NOT exist, directly unzip
        {
            dbq_name := chr(34) . ZipFileDir . chr(34)
            run_cmd := ExePath_7ZG . " x " . chr(34) . FileFullPath . chr(34) . " -o" . dbq_name
            RunWait run_cmd
            ; MsgBox dbq_name . "-3"
            TC_SetLeftPath(ZipFileDir)

        }
    }
    Else  ;at least one folder and one file in Level1 of the Achrive file
    {
        If (FileExist(ZipFileDir . "\" . ZipFileName))  ; if TargetFolder  exists , create new folder named as TargetFolder (n)
        {
            Loop
            {
                SmartUnZip_NewFolderName := ZipFileDir . "\" . ZipFileName . " (" . A_Index . ")"
                If !FileExist(SmartUnZip_NewFolderName)
                {
                    dbq_name := chr(34) . SmartUnZip_NewFolderName . chr(34)
                    run_cmd := ExePath_7ZG . " x " . chr(34) . FileFullPath . chr(34) . " -o" . dbq_name
                    ; MsgBox run_cmd
                    RunWait run_cmd
                    ; MsgBox dbq_name . "-4"
                    TC_SetLeftPath(SmartUnZip_NewFolderName)

                    break
                }
            }
        }
        Else ; if TargetFolder does NOT exist, directly unzip
        {
            dbq_name := chr(34) . ZipFileDir . "\" . ZipFileName . chr(34)
            run_cmd := ExePath_7ZG . " x " . chr(34) . FileFullPath . chr(34) . " -o" . dbq_name
            RunWait run_cmd
            ; MsgBox dbq_name . "-5"
            TC_SetLeftPath(ZipFileDir . "\" . ZipFileName)
            ; break
        }
    }
    Return
}
