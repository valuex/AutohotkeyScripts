iniSecToMap(iniFile,iniSec)
{
    SecContents:=IniRead(iniFile,iniSec)
    ArrSecContents:=StrSplit(SecContents,"`n","`r")
    KeyValueMap:=Map()
    loop ArrSecContents.Length
    {
        ThisPair:=ArrSecContents[A_Index]
        EqualPos:=InStr(ThisPair,"=")
        ThisKey:=Trim(SubStr(ThisPair,1,EqualPos-1))
        ThisValue:=Trim(SubStr(ThisPair,EqualPos+1))
        KeyValueMap[ThisKey]:=ThisValue
    }
    return KeyValueMap
}

IniSec2Arr(FileName,SecName)
{
    SecContents:=IniRead(FileName,SecName)
    ArrSecItems:=StrSplit(SecContents,"`r","`n")
    ArrKeyValue:=Array()
    loop ArrSecItems.Length
    {
        ThisLine:=ArrSecItems[A_Index]
        EqualPos:=InStr(ThisLine,"=")
        ThisKey:=SubStr(ThisLine,1,EqualPos-1)
        ThisValue:=SubStr(ThisLine,EqualPos+1)
        ArrKeyValue.Push(Map("key",ThisKey,"value",ThisValue))
    }
}
