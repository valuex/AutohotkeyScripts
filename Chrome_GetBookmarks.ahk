#Requires AutoHotkey 2.0

#Include  D:\Downloads\cherry-snippet-v2-master\lib\Class_SQLiteDB.ahk
; #Include D:\SoftX\AHK_Scripts_V2\Lib\Image_ImagePut.ahk
; %LocalAppData%\Google\Chrome\
db_file:="D:\SoftX\AHK_Scripts_V2\Chrome_Bookmarks\Favicons"


DB := SQLiteDB()
DB.OpenDB(db_file)
Get_Icon_For_URL(strUrl)
If !DB.CloseDB()
	MsgBox("Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, "SQLite Error", 16)

Get_Icon_For_URL(URL)
{
	; URL:="https://mail.google.com/mail/"
	IconID:=Get_Icon_ID_From_URL(URL)
	blob:=Get_Icon_File(IconID)
	FileObj := FileOpen('1.ico', "w")
	FileObj.RawWrite(blob , blob.Size)
	FileObj.Close()
	return IconID ;. "`n" . IconFile
	; get icon_id in table "icon_mapping" by url
	Get_Icon_ID_From_URL(strURL)
	{
		sql_cmd  := 'SELECT icon_id FROM icon_mapping WHERE page_url IN ("' . strURL . '");'
		result:=IndexDb(sql_cmd)
		return result
	}


	Get_Icon_File(icon_id_number)
	{
		sql_cmd  := 'SELECT image_data FROM favicon_bitmaps WHERE icon_id =' . icon_id_number . ' AND width = 32;'
		If !db.Query(sql_cmd, &query_result)
			{
				MsgBox("SQLite QUERY Error`n`nMessage: " . db.ErrorMsg . "`nCode: " . db.ErrorCode . "`nFile: " . db_file . "`nQuery: " . sql_cmd)
				return 0
			}

		search_result := ''
		Loop
		{
			result := query_result.Next(&row)
			If !result
			{
				MsgBox("SQLite NEXT Error`n`nMessage: " . db.ErrorMsg . "`nCode: " . db.ErrorCode)
				return 0
			}
			If result = -1
			{
				Break
			}
			search_result := row[1]
			query_result.Free()
			return search_result
		}
	}

	IndexDb(sql_cmd)
	{
		If !db.Query(sql_cmd, &query_result)
			{
				MsgBox("SQLite QUERY Error`n`nMessage: " . db.ErrorMsg . "`nCode: " . db.ErrorCode . "`nFile: " . db_file . "`nQuery: " . sql_cmd)
				return 0
			}

		search_result := ''
		Loop
		{
			result := query_result.Next(&row)
			If !result
			{
				MsgBox("SQLite NEXT Error`n`nMessage: " . db.ErrorMsg . "`nCode: " . db.ErrorCode)
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
		return search_result
	}

}
