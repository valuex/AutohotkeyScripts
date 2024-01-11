#Requires AutoHotkey 2.0
#Include .\lib\_JXON.ahk

F1::
{
global bk_dir
bk_dir := DirSelect("D:\", 3, "Saving bookmarks to")
if bk_dir = ""
{
    MsgBox "You didn't select a folder."
    return
}

; Chrome's bookmarks is saved in %Appdata%\Local\Google\Chrome\User Data\xxx\, xxx stands for Default or Profile N
; the file is named as [Bookmarks] without extension, it is acutally a json file.
; copy [Bookmarks] file into \temp and rename it as Bookmarks.json
bk_pos1:=StrReplace(A_AppData,"\Roaming") . "\Local\Google\Chrome\User Data\Profile 1\"
bk_pos_d:=StrReplace(A_AppData,"\Roaming") . "\Local\Google\Chrome\User Data\Default\"
chrome_bk_file_dir:=FileExist(bk_pos1 . "Bookmarks")?bk_pos1:bk_pos_d
chrome_bk_file:=chrome_bk_file_dir . "Bookmarks"
json_file:=A_Temp . "\Bookmarks.json"
if(FileExist(chrome_bk_file))
    FileCopy chrome_bk_file,json_file,1
else
{
    MsgBox "Can't locate the [Bookmarks] file"
    return
}

ToolTip "Converting urls..."
strAllData:= FileRead(json_file , "UTF-8")
objAllData := jxon_load(&strAllData)
objAllBookmarks:=objAllData["roots"]["bookmark_bar"]
parse_json(objAllBookmarks,"")
ToolTip
}
parse_json(data,ThisDir:="")
{   
    nOjectType:=OjectType(data)
    if(OjectType(data)=1 and data.Has("type") and data["type"]=="folder")
    {
        ThisDir:=ThisDir . data["name"] . "\"
    }
     data.Has("url")
    
    if (OjectType(data)=1)  ;map
    {
        for key, value in data
        {
            if (OjectType(value)=1 or OjectType(value)=2)
            {
                parse_json(value,ThisDir)
            }
            else
            {
                ; do sth to for the level N elements here
                if(data.Has("name")  and data.Has("url"))
                {
                    Out_str:= "Dir:" . ThisDir  . "`tkey: " . data["name"] . "`tvalue: " . data["url"] . "`r`n"
                    FileAppend Out_str, "1.txt"
                    GenShortcut(data["name"],data["url"])
                }
                break
            }
        }
    }
    else if (OjectType(data)=2)  ;array
    {
        loop data.Length
        {
            Item:=data[A_Index]
            parse_json(Item,ThisDir)
        }
    }
    else
        MsgBox "data member " . data.Count

}

GenShortcut(bk_name,bk_url)
{
    if(Trim(bk_name)="") ;bookmark name is empty
        return
    bk_full_name:=bk_dir . "\" . bk_name . ".url"
    IniWrite bk_url, bk_full_name, "InternetShortcut", "URL"
    ; IniWrite <IconFile>, bk_full_name, "InternetShortcut", "IconFile"
    ; IniWrite 0, bk_full_name, "InternetShortcut", "IconIndex"
}
OjectType(data)
{
    try
    {
        ObjItemNum:=data.Count 
        AHKOjbect:=1  ; map 
    }
    catch as e 
    {
        try
        {
            ObjItemNum:=data.Length
            AHKOjbect:=2  ; array
        }
        catch as e 
        {
            try
            {
                ObjItemNum:=ObjOwnPropCount(data)
                AHKOjbect:=3  ; ojbect
            }
            catch as e 
                AHKOjbect:=4   ;string
        }
    }
    return AHKOjbect
}
