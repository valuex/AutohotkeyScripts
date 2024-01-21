#Requires Autohotkey >=2.0
#Include  .\lib\Ini_File_Lib.ahk
#Include .\lib\TC_AHK_Lib.ahk
global g_TCDir:="D:\SoftX\TotalCommander11\"
global g_tc_CmdFile:=g_TCDir . "TotalCMD.inc"
global g_CMDGroups
global g_TC_CMDArr
global g_UserCMDGroupName:="UCMD"
global WinCMD_ini:=g_TCDir . "WinCMD.ini"


g_TC_CMDArr:=GetCMDArr(&g_CMDGroups)
MyGui := Gui("+AlwaysOnTop +ToolWindow")
MyGui.SetFont("s14", "Verdana")
; MyGui.Opt("-Caption")
CurrentHwnd := MyGui.Hwnd
CtlInput:=MyGui.AddEdit("w700")
CtlInput.OnEvent("Change",UserInput_Change)
LVS_SHOWSELALWAYS := 8 ; Seems to have the opposite effect with Explorer theme, at least on Windows 11.
LV_BGColor:=Format(' Background{:x}', DllCall("GetSysColor", "int", 15, "int"))  ; background color of listview item when get selected by up & down arrow
LV := MyGui.Add("ListView", "r20 w700 -Multi -Hdr " LVS_SHOWSELALWAYS LV_BGColor, ["Group","Command","Description","Code"])
LV.OnEvent("DoubleClick", LVItemHanlder)
OnMessage(WM_KEYDOWN := 0x100, KeyDown)
#HotIf WinActive("ahk_class TTOTAL_CMD")
!e::
{
    if(FileExist("log.txt"))
        FileDelete("log.txt")
    Add2List()
    ; LV.ModifyCol ; Auto-size each column to fit its contents.
    LV.ModifyCol(1,"80")
    LV.ModifyCol(2,"200")
    LV.ModifyCol(3,"300")
    LV.ModifyCol(4,"150")
    MyGui.Show()    
}

; excute corrsponding command
LVItemHanlder(LV,RowNum)
{
    InputStr:=CtlInput.Value
    CMDCode :=LV.GetText(RowNum,1)
    CMDName := LV.GetText(RowNum,2)  
    CMDComment := LV.GetText(RowNum,3)  
    CMDGroup :=LV.GetText(RowNum,4)

    if(CMDGroup=g_UserCMDGroupName)
    {
        IniWrite(InputStr,"Setting.ini","commands",CMDName)
        ; MsgBox CMDComment
        %CMDComment%()
    }
    else if(CMDCode>0) 
    {
        IniWrite(InputStr,"Setting.ini","commands",CMDName)
        try
            PostMessage(0x433,CMDCode,0,,"ahk_class TTOTAL_CMD")
        catch TimeoutError as err
            ToolTip "Time out"
    }
    WinClose()
}


KeyDown(wParam, lParam, nmsg, Hwnd) 
{
    global LV
    static VK_UP := 0x26
    static VK_DOWN := 0x28
    static VK_Enter := 0x0D
    static VK_ESC:=0x1B
    static VK_Ctrl:=0x11
    static VK_W:=0x57
    static VK_CtrlW:=0x1157

    gc := GuiCtrlFromHwnd(Hwnd)
    if !(wParam = VK_UP || wParam = VK_DOWN || wParam=VK_Enter || wParam=VK_ESC || wParam=VK_W) ;|| wParam=VK_Ctrl|| wParam=VK_W
        return
    if  (gc is Gui.Edit and (wParam = VK_UP || wParam = VK_DOWN ))
    {
        ; press up & down in Eidt control to select item in listview
        CurRowNumber := LV.GetNext()  ;get current selected row number
        LastRowNumber := LV.GetCount()
        if(CurRowNumber=1 and wParam = VK_UP)
            LV.Modify(LastRowNumber, "Select Focus")
        else if (CurRowNumber=LastRowNumber and wParam = VK_DOWN)
            LV.Modify("1", "Select Focus")
        else
            PostMessage nmsg, wParam, lParam, LV
        return true
    }
    else if (wParam=VK_ESC or (wParam=VK_W and GetKeyState("Ctrl")))
    {
        WinClose("ahk_id " . CurrentHwnd)
    }
    ; else if ( gc is Gui.ListView and  wParam=VK_Enter )
    else if (wParam=VK_Enter )
    {       
        RowNumber := LV.GetNext()  ;get current selected row number
        LVItemHanlder(LV,RowNumber)
        return true
    }    
} 
Add2List()
{
    global LV
    i:=0
    For CMDName , CMDInfo in g_TC_CMDArr
    {
        i:=i+1
        if(i>50)
            break
        ThisItem:=g_TC_CMDArr[CMDName]
        LV.Add(,ThisItem["Code"],CMDName,ThisItem["Comment"],ThisItem["Group"])
    }
    LV.Modify("1", "Select Focus")
}

UserInput_Change(*)
{
    InputStr:=CtlInput.Value
    FoundPos1 := RegExMatch(InputStr, "^\/(\w*?)\s(\w*)" , &OutputVar)
    FoundPos2 := RegExMatch(Trim(InputStr), "^\/(\w+?)$" , &InGroupNamePat)
    IsIndexByGroup:=FoundPos2=1
    InputStrLastChar:=SubStr(InputStr,StrLen(InputStr))
    IsAutoExpandToFirstGroup:=IsIndexByGroup and InputStrLastChar=" "
    SpacePos:=InStr(InputStr," ")
    Keywords:=Trim(SubStr(InputStr,SpacePos+1))
    static AutoExpandedGroup:=""
 
    if(InputStr="/")  ; start to index  groups' name only
    {
        LV.Delete
        loop g_CMDGroups.Length
            LV.Add(,g_CMDGroups[A_Index],"","","") 
        AutoExpandedGroup:=""    
    }
    else if(InputStr="")  ; if delete input to nothing
    {
        LV.Delete
        Add2List()
        AutoExpandedGroup:=""  
    }
    else if(IsIndexByGroup)  ; indexing group by "/xxx"
    {
        LV.Delete
        InRegNeedle:=Str2RegChars(InGroupNamePat[1])
        loop g_CMDGroups.Length
        {
            ThisItem:=g_CMDGroups[A_Index]
            FoundPos := RegExMatch(ThisItem, "i)" . InRegNeedle , &OutputVar)
            if(FoundPos>=1)
            { 
                LV.Add(,ThisItem,"","","")
            }
        }
    
        ; auto expand to the 1st group in the listview when space is input
        if(InputStrLastChar=" " and LV.GetCount()>=1) ;if  indexing by "/xxx<space>"
        {
            Row1Text:=LV.GetText(1,1)
            AutoExpandedGroup:=Row1Text
            LV.Delete
            For CMDName , CMDInfo in g_TC_CMDArr
            {
                ; mm CMDName 
                ThisItem:=g_TC_CMDArr[CMDName]
                if(ThisItem["Group"]=Row1Text)
                {
                    LV.Add(,ThisItem["Code"],CMDName,ThisItem["Comment"],ThisItem["Group"])  
                }
            }         
        }
    }
    else if(AutoExpandedGroup)  ;indexing command by "/xxx<space>xxx"
    {
        LV.Delete
        InRegNeedle:=Str2RegChars(Keywords)
        AllMatchedItems:=""
        For CMDName , CMDInfo in g_TC_CMDArr
        {
            ThisItem:=g_TC_CMDArr[CMDName]
            IsTheExpandedGroup:=(ThisItem["Group"]=AutoExpandedGroup)
            FoundPos1 := RegExMatch(CMDName, "i)" . InRegNeedle , &OutputVar)
            FoundPos2 := RegExMatch(ThisItem["Comment"], "i)" . InRegNeedle , &OutputVar)

            RegMatchX(CMDName,InRegNeedle,&InCMDNamePat,1, &FoundPos1,&MatchScore1:=0)
            RegMatchX(ThisItem["Comment"],InRegNeedle,&InCommentPat,1, &FoundPos2,&MatchScore2:=0)
            ThisMatchedScore:=GetMatchScore(MatchScore1,MatchScore2)
            ThisMatchedItem:=ThisMatchedScore . "|" . CMDName            

            if(IsTheExpandedGroup and (FoundPos1 or FoundPos2))
            {
                AllMatchedItems:=AllMatchedItems . ThisMatchedItem . "`n"
            }
        }
        SortAndAddToLV(AllMatchedItems)
    }
    else  ; indexing command name and description
    {
        InRegNeedle:=Str2RegChars(InputStr)
        LV.Delete
        PreCmdsAdded:=LoadPreSaved(InputStr)
        AllMatchedItems:=""
        For CMDName , CMDInfo in g_TC_CMDArr
        {
            ThisItem:=g_TC_CMDArr[CMDName]
            ThisMatchedScore:=0
            RegMatchX(CMDName,InRegNeedle,&InCMDNamePat,1, &FoundPos1,&MatchScore1:=0)
            RegMatchX(ThisItem["Comment"],InRegNeedle,&InCommentPat,1, &FoundPos2,&MatchScore2:=0)

            if(FoundPos1 or FoundPos2)
            {
                if(PreCmdsAdded.Has(CMDName))
                    continue
                ThisMatchedScore:=GetMatchScore(MatchScore1,MatchScore2)
                ThisMatchedItem:=ThisMatchedScore . "|" . CMDName
                AllMatchedItems:=AllMatchedItems . ThisMatchedItem . "`n"
            }
        }
        SortAndAddToLV(AllMatchedItems)          
    }
    LV.ModifyCol ; Auto-size each column to fit its contents.


    ; regmatchx to get matched results including matched content, position and score.
    RegMatchX(Haystack,NeedleRegEx,&OutputVar,StartingPos:=1, &FoundPos:=0,&MatchScore:=0)
    {
        FoundPos := RegExMatch(Haystack, "i)" . NeedleRegEx , &OutputVar)
        MatchScore:=0
        if(FoundPos)
        {
            loop  OutputVar.Count
                MatchScore:= MatchScore+OutputVar.Pos[A_Index]
        }
    }
    ;get match score for one command from matching results in name and description
    GetMatchScore(Score1,Score2)
    {
        
        if(Score1=0 and Score2=0)
            MatchScore:=10000 ; large number
        else if(Score1=0 or Score2=0)
            MatchScore:=Score1=0?Score2:Score1
        else
            MatchScore:=Min(Score1,Score2+0.5) ; 0.5 makes the 2nd item with a little bit lower priority
        return MatchScore
    }
    ; convert input string into regex pattern
    Str2RegChars(InputStr)
    {
        CharsRegNeedle:=""
        ArrChars:=StrSplit(InputStr)
        loop ArrChars.Length
        {
            ThisChar:=ArrChars[A_Index]
            if(ThisChar=" ")
                continue
            CharsRegNeedle:=CharsRegNeedle . "(" . ThisChar . ".*?)"
        }
        return CharsRegNeedle
    }
    ; load commands from setting. ini
    LoadPreSaved(InputStr:="")
    {   
        global LV
        PreCMDMap:=iniSecToMap("Setting.ini","Commands")
        PreCMDsAdded:=Map()
        AllMatchedItems:=""
        InRegNeedle:=Str2RegChars(InputStr)
        For CMDName , CMDShortName in PreCMDMap
        {
            ThisMatchedScore:=0
            FoundPos1 := RegExMatch(CMDShortName, "i)" . InRegNeedle , &CMDShortNamePat)
            if(FoundPos1)
            {
                loop  CMDShortNamePat.Count
                    ThisMatchedScore:= ThisMatchedScore+CMDShortNamePat.Pos[A_Index]                
                ThisItem:=g_TC_CMDArr[CMDName]                
                ThisMatchedItem:=ThisMatchedScore . "|" . CMDName
                AllMatchedItems:=AllMatchedItems . ThisMatchedItem . "`n"
            }
        }
        PreCMDsAdded:=SortAndAddToLV(AllMatchedItems)
      
        return PreCMDsAdded
    }
    ;  sort commands and load them into listview
    SortAndAddToLV(AllMatchedItems)
    {
        CMDsAdded:=Map()
        AllMatchedItems := subStr(AllMatchedItems, 1, strLen(AllMatchedItems) - 1) ; remove trailing `n
        SortedItems := Sort(Trim(AllMatchedItems) , , SortByScore)
        ArrAllMatchedItems:=StrSplit(SortedItems,"`n")
        loop  ArrAllMatchedItems.Length
        {
            ThisLine:=ArrAllMatchedItems[A_Index]
            CMDName:=StrSplit(ThisLine,"|")[2]
            ThisItem:=g_TC_CMDArr[CMDName]
            LV.Add(,ThisItem["Code"],CMDName,ThisItem["Comment"],ThisItem["Group"])
            CMDsAdded[CMDName]:=Map("Group", ThisItem["Group"],"Code",ThisItem["Code"],"Comment",ThisItem["Comment"])
        } 
        return CMDsAdded
    }

    SortByScore(a1,a2,*)
    {
        a1:=StrSplit(a1,"|")[1]
        a2:=StrSplit(a2,"|")[1]
        return a1 > a2 ? 1 : a1 < a2 ? -1 : 0  ; Sorts according to the lengths determined above.
    }
}


; read TotalCMD.inc into a MAP object
GetCMDArr(&CMDGroups)
{
    tc_CmdFileContent := FileRead(g_tc_CmdFile)
    ArrCMDContent:=StrSplit(tc_CmdFileContent,"`n","`r")
    ArrCMDs:=Map()
    CMDGroups:=Array()
    loop  ArrCMDContent.Length
    {
        ThisLine:=ArrCMDContent[A_Index]
        CMDGroupPos := RegExMatch(ThisLine, "(.*?)=0" , &ThisCMDGroupPat,1)
        IsCMDLine:=InStr(ThisLine, "cm_")
        ;cm_SrcViewModeList=333;Source: View mode menu
        if(CMDGroupPos>=1)
        {
            FoundPos1 := RegExMatch(ThisCMDGroupPat[1], "([a-zA-Z].*?)_" , &ThisNeatCMDGroupName)
            ThisGroup:=ThisNeatCMDGroupName[1]
            CMDGroups.Push(ThisGroup)
        }
        else if(IsCMDLine)
        {
            EqualPos:=InStr(ThisLine,"=")
            SemiPos:=InStr(ThisLine,";")
            CMDName := Trim(SubStr(ThisLine,4,EqualPos-4))
            CMDCode := Trim(SubStr(ThisLine,EqualPos+1,SemiPos-EqualPos-1))
            ; MsgBox CMDCode
            CMDComment := Trim(SubStr(ThisLine,SemiPos+1))
            try
            {
                ArrCMDs[CMDName]:=Map("Group", ThisGroup,"Code",CMDCode,"Comment",CMDComment)
                    ; ArrCMDs.Push(Map("Group",ThisGroup,"Name", CMDName,"Code",CMDCode,"Comment",CMDComment))
            }
            catch as e
                MsgBox "error info`n" . ThisLine
        }
    }
    LoadUserCMD()
    return ArrCMDs
    LoadUserCMD()
    {
        UserCMDs:=iniSecToMap("Setting.ini","UserCommands")
        for UserCMDName, UserCommand in UserCMDs
        {
            ArrCMDs[UserCMDName]:=Map("Group", g_UserCMDGroupName,"Code","","Comment",UserCommand)
        }
        g_CMDGroups.Push(g_UserCMDGroupName)
    }        
}
