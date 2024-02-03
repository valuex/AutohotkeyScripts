; TC_Open
; Open file or folder with Total Commander
; 1. if a folder already open in one of TC's tabs, activate the corresponding tab; else, open a new tab
; 2. if the input file's directory open in one of TC's tabs, activate the corresponding tab, select the input file; else, open a new tab and select the file 
; 3. for special folders, like Control, My Computer, it will be open use explorer.exe
; Author: Valuex
; 2024/2/3
#Requires AutoHotkey >=2.0
#Include C:\Users\wei_x\Desktop\Chrome_Download\lib\TC_AHK_Lib.ahk

fpath:=""
loop A_Args.Length
{
    fpath:=fpath . A_Args[A_Index] . " "
}
fpath:=Trim(fpath)  ; remove the last space
SpecialFolder := RegExMatch(fpath, "::\{.*\}")  ; ::{26EE0668-A00A-44D7-9371-BEB064C98683}  control
DiskDrive:=RegExMatch(fpath, '([A-Z]:)\"',&DrivePath) ; drive 
if (SpecialFolder)
    Run "explorer.exe " . fpath   ; for special folders, open it with default explorer
else if (DiskDrive)
{
    fpath:=DrivePath[1] . "\"
    TC_Open(fpath)
}
else
{
    TC_Open(fpath)
}
return

TC_Open(InputPath)
{
    TC_Path:=IsScriptInTCDir()
    InPutType:=IsInputFileOrFolder(InputPath)  ; 0- not exist;1 - Folder; 2- File
    IsTC_Active:=AOR("ahk_class TTOTAL_CMD",TC_Path) 

    if(!TC_Path or !InPutType or !IsTC_Active) 
        return

    TC_OpenTabsFile:=A_ScriptDir . "\User\SAVETABS2.tab"
    ReOutput(TC_OpenTabsFile)
    ; get open tabs number in active panel
    AcTabs:=IniRead(TC_OpenTabsFile,"activetabs")
    AcTabNum:=IniRead(TC_OpenTabsFile,"activetabs","activetab")
    AcTabKeyName:=String(AcTabNum) . "_path"
    AcTabPath:=IniRead(TC_OpenTabsFile,"activetabs",AcTabKeyName)
    iTabExist:=false
    if(InPutType=1)  ; input is folder
    {
        iAcTab:=IsFolderInActiveTab(AcTabPath,InputPath,AcTabNum)
        if(iAcTab)
            iTab:=iAcTab
        else
            iTab:=IsFolderOpenInTabs(AcTabs,InputPath)  
   
        if(iTab)
        {
            xsTCCommand:=5200+iTab  ; in TotalCMD.inc, left tab id starts from 5201
            SendMessage(1075, xsTCCommand, 0, , "ahk_class TTOTAL_CMD")
        }
        else
        {
            TC_LeftNewTab(InputPath)
        }
    }
    else  ; input is file
    {
        SplitPath InputPath, , &dir
        iAcTab:=IsFolderInActiveTab(AcTabPath,dir,AcTabNum)
        if(iAcTab)
            iTab:=iAcTab
        else
            iTab:=IsFolderOpenInTabs(AcTabs,dir)    
        if(iTab)
        {
            xsTCCommand:=5201+iTab-1  ; in TotalCMD.inc, left tab id starts from 5201
            SendMessage(1075, xsTCCommand, 0, , "ahk_class TTOTAL_CMD") ; go to tab
            TC_OpenAndSelect(InputPath)
        }
        else
        {
            TC_FocusOnLeftFile(InputPath)
        }
    }
    AOR(WinTitle,WinExe)
    {
        if(WinExist(WinTitle))
        {
            WinActivate(WinTitle)
            WinA:=WinWaitClass("TTOTAL_CMD")
            return WinA ? true: false
        }
        else
        {
            Run WinExe
            WinWaitActive(WinTitle,,5)
            WinA:=WinWaitClass("TTOTAL_CMD")
            return WinA ? true: false
        }
    }
    WinWaitClass(WinClass)
    {
        loop(100)
        {
            aClass:=WinGetClass("A")
            if(StrCompare(aClass,WinClass)=0)
                return true
            else
                Sleep(100)
        }
        return false
    }
    IsInputFileOrFolder(FilePattern)
    {
      AttributeString := FileExist(FilePattern)
      if(InStr(AttributeString,"D"))
        return 1 ;"Folder"
      else if(AttributeString) 
        return 2 ;"File"
      else
        return 0 ;AttributeString: empty means no file exsits
    }
    IsScriptInTCDir()
    {
        ; check whether this script in the same directory as Total Commander main program
        TC64:=A_ScriptDir . "\Totalcmd64.exe"
        TC32:=A_ScriptDir . "\Totalcmd.exe"
        if A_Is64bitOS AND FileExist(TC64)
            TC:=DoubleQuote(TC64)
        else if   FileExist(TC32)
            TC:=DoubleQuote(TC32)
        else
        {
            MsgBox "This script shall be put in the directory of Totalcmd.exe!"
            return ""
        }
        return TC
    }
    
    IsFolderOpenInTabs(ActiveTabs,InputPath)
    {
        ; loop to see if there is any tab already exist
        if(!SubStr(InputPath,StrLen(InputPath)="\"))
            InputPath:=InputPath . "\"
        ArrAcTabs:=StrSplit(ActiveTabs,"`n","`r")
        AcTabsNum:=ArrAcTabs.Length-1
        loop AcTabsNum
        {
            i:=Floor((A_Index-1)/2)  ; in SAVETABS2.tab, tab id starts from 0
            iTabIndex:=String(i) . "_path"
            ThisLine:=ArrAcTabs[A_Index]
            ThisLineID:= GetTabID(ThisLine) 
            ThisLinePath:= GetTabPath(ThisLine) 
            if(!InStr(ThisLineID,iTabIndex))
                continue
            if(StrCompare(InputPath,ThisLinePath)=0)
            {
                TabIndex:=StrSplit(ThisLine,"_")[1]
                return TabIndex+1
            }
        }
        return false
    }
    IsFolderInActiveTab(ActiveTabPath,InputPath,AcTabNumber)
    {
        if(StrCompare(InputPath,ActiveTabPath)=0)
            return AcTabNumber
        else
            return false
    }
    GetTabID(iniLine)
    {
        ; to the left of =, like 0_path, 1_path
        EqualPos:=InStr(iniLine,"=")
        TabID:=SubStr(iniLine,1,EqualPos-1)
        return TabID
    }
    GetTabPath(iniLine)
    {
     EqualPos:=InStr(iniLine,"=")
     TabPath:=SubStr(iniLine,EqualPos+1)
     return TabPath
    }
    ReOutput(TC_OpenTabsFile)
    {
        if(FileExist(TC_OpenTabsFile))
            FileDelete TC_OpenTabsFile
    
        ; output open tab list
        TC_SendUserCommand("em_savealltabs")
        
        loop 10
        {
            Sleep(200)
            if(FileExist(TC_OpenTabsFile))
                break
        }
    }
    DoubleQuote(strInput)
    {
        return Chr(34) . strInput . Chr(34)
    }
}



