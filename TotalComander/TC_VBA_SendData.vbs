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


Sub TC_SendUserCMD(strPath)
    Dim UserCMD As String
    Dim AcWorkbookName As String
    AcWorkbookName = ActiveWorkbook.Name
    
    UserCMD = "em_SelectFile " & strPath & "|" & AcWorkbookName
    
    Dim cds As CopyDataStruct, result As LongPtr
    Static hwndAHKInterposer As Long
    Dim wParam As Long
    wParam = 0
    If (hwndAHKInterposer > 0) Then
        hwndAHKInterposer = hwndAHKInterposer
    Else
        hwndAHKInterposer = GetHiddenWinHwndByTitle("TC-VBA-Interposer")
        Debug.Print 1
    End If
    'Debug.Print hwndAHKInterposer
    If (hwndAHKInterposer > 0) Then
        cds.dwData = Asc("E") + 256 * Asc("M")
        cds.cbData = Len(UserCMD) * 2 + 2  'The size, in bytes
        cds.lpData = StrPtr(UserCMD)
        result = SendMessage(hwndAHKInterposer, WM_COPYDATA, wParam, cds)
        'Debug.Print hwndAHKInterposer
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

