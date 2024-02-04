' send WM_COPYDATA to TC_VBA_Interposer.ahk

Option Explicit

Private Declare PtrSafe Function FindWindow Lib "USER32" Alias "FindWindowA" (ByVal lpClassName As String, ByVal lpWindowName As String) As Long
Private Declare PtrSafe Function SendMessage Lib "USER32" Alias "SendMessageA" (ByVal hWnd As LongPtr, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As LongPtr
Private Declare PtrSafe Function GetWindowTextLength Lib "USER32" Alias "GetWindowTextLengthA" (ByVal hWnd As Long) As Long
Private Declare PtrSafe Function GetWindowText Lib "USER32" Alias "GetWindowTextA" (ByVal hWnd As Long, ByVal lpString As String, ByVal cch As Long) As Long
Private Declare PtrSafe Function GetWindow Lib "USER32" (ByVal hWnd As Long, ByVal wCmd As Long) As Long
Private Declare PtrSafe Function IsWindowVisible Lib "USER32" (ByVal hWnd As Long) As Boolean
Public Declare PtrSafe Function GetParent Lib "user32.dll" (ByVal hWnd As LongPtr) As LongPtr
Public Declare PtrSafe Function GetWindowThreadProcessId Lib "USER32" (ByVal hWnd As LongPtr, lpdwProcessId As Long) As Long

Public Type CopyDataStruct
    dwData As LongPtr
    cbData As Long
    lpData As LongPtr
End Type
Private Const WM_COPYDATA = &H4A
Private Const GW_HWNDNEXT = 2
Function GetHiddenWinHwndByTitle(strWinTitle) As Long
    Dim lhWndP As Long
    If GetHandleFromPartialCaption(lhWndP, strWinTitle) = True Then
        GetHiddenWinHwndByTitle = lhWndP
    Else
        GetHiddenWinHwndByTitle = 0
    End If
End Function


Sub TC_SendUserCMD()
    Dim UserCMD As String
    UserCMD = "em_focusfile"
    
    Dim cds As CopyDataStruct, result As LongPtr
    Dim hwndAHKInterposer As Long
    Dim wParam As Long
    wParam = 0
    hwndAHKInterposer = GetHiddenWinHwndByTitle("TC-VBA-Interposer")
    'Debug.Print hwndAHKInterposer
    If (hwndAHKInterposer > 0) Then
        cds.dwData = Asc("E") + 256 * Asc("M")
        cds.cbData = Len(UserCMD) * 2 + 2  'The size, in bytes
        cds.lpData = StrPtr(UserCMD)
        result = SendMessage(hwndAHKInterposer, WM_COPYDATA, wParam, cds)
        Debug.Print hwndAHKInterposer
    End If
End Sub



Private Function GetHandleFromPartialCaption(ByRef lWnd As Long, ByVal sCaption As String) As Boolean
    'https://copyprogramming.com/howto/how-to-locate-the-window-using-findwindow-function-in-windowapi-using-vba
    Dim lhWndP As Long
    Dim sStr As String
    GetHandleFromPartialCaption = False
    lhWndP = FindWindow(vbNullString, vbNullString) 'PARENT WINDOW
    Do While lhWndP <> 0
        sStr = String(GetWindowTextLength(lhWndP) + 1, Chr$(0))
        GetWindowText lhWndP, sStr, Len(sStr)
        sStr = Left$(sStr, Len(sStr) - 1)
        If InStr(1, sStr, sCaption) > 0 Then
            GetHandleFromPartialCaption = True
            lWnd = lhWndP
            Debug.Print sStr
            Exit Do
        End If
        lhWndP = GetWindow(lhWndP, GW_HWNDNEXT)
    Loop
End Function

Function WndFromPID(ByVal Xpid As LongPtr) As LongPtr
    'https://stackoverflow.com/questions/7807150/how-can-i-get-a-handle-to-a-window-of-executed-process-in-vba
    Dim Nhwnd As LongPtr, Npid As Long, Nthread_id As Long
    ' Get the first window handle.
    Nhwnd = FindWindow(vbNullString, vbNullString)  ' NOT (ByVal 0&, ByVal 0& ) !
    ' Loop until we find the target or we run out of windows
    Do While Nhwnd <> 0
        ' See if this window has a parent. If not, it is a top-level window
        If GetParent(Nhwnd) = 0 Then
            ' This is a top-level window. See if it has the target instance handle
            Nthread_id = GetWindowThreadProcessId(Nhwnd, Npid)
            If Npid = Xpid Then
                WndFromPID = Nhwnd      ' This is the target
                Exit Do
            End If
        End If
        Nhwnd = GetWindow(Nhwnd, 2)     ' Examine the next window [2 = GW_HWNDNEXT]
    Loop
End Function

