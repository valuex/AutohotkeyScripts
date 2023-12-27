#Requires AutoHotkey >=2.0
; TC_QuickMove
; Move files/Folders in the current dir to [destination folder] quickly
; [destination folder] is in the oppsite panel of Total Commander
; user can choose the [destination folder] from a menu which list all the tabs open in the oppsite panel of TC.
; Author: Valuex
; Date: 2023-12-27
F2::
{
    global TC_Sel
    AcWinClass:=WinGetClass("A")
    if(AcWinClass!="TTOTAL_CMD")
        return
    TC_Sel:=TC_GetSelection()
    if(!TC_Sel)
        return
    TC_ListOpenTabs()
}
return
TC_GetSelection(){

    SendMessage( 1075, 2018, 0, , "ahk_class TTOTAL_CMD")  ;cm_CopyFullNamesToClip
    SelectedFiles:=StrSplit(A_Clipboard,"`n","`r")
    if(SelectedFiles.Length=1)
    {
        Candy_IsOneFile:=1
        return SelectedFiles[1]
    }
    Else
    {
        Candy_IsMultiFile:=1
        loop SelectedFiles.Length
        {
            SelectedFilesNames.=SelectedFiles[A_Index] . "`n"
        }
        return SelectedFilesNames
    }   
}
TC_ListOpenTabs()
{
    MyMenu:=Menu()
    global TC_OpenTabsFile
    TC_OpenTabsFile:=A_ScriptDir . "\User\SAVETABS2.tab"
    ReOutput(TC_OpenTabsFile)
    ; get open tabs number in inactive panel
    AcTabs:=IniRead(TC_OpenTabsFile,"inactivetabs")
    loop 200
    {
        DirPath:=IniRead(TC_OpenTabsFile, "inactivetabs",String(A_Index-1) . "_path", "error")
        if(DirPath="error")
            break
        PathArr:=StrSplit(DirPath,"\")
        if(PathArr.Length=1)
            ThisDir:=DirPath
        else
            ThisDir:=PathArr[PathArr.Length-1]
        ThisDir_Pinyin:=zh2py(ThisDir)
        FoundPos:=RegExMatch(ThisDir_Pinyin,"(a-zA-Z)",&F1st_Pinyin)
        try
            MenuItemName:="&" . F1st_Pinyin[1] . "`t" . ThisDir
        catch as e
            MenuItemName:="&" . A_Index . "`t" . ThisDir
        MyMenu.Add MenuItemName, TC_MoveSelection
    }
    MyMenu.Show()
    ReOutput(TC_OpenTabsFile)
    {
        if(FileExist(TC_OpenTabsFile))
            FileDelete TC_OpenTabsFile
    
        ; output open tab list
        SendTCUserCommand("em_savealltabs")
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
TC_MoveSelection(ItemName,ItemPos,*)
{
    DirPath:=IniRead(TC_OpenTabsFile, "inactivetabs",String(ItemPos-1) . "_path", "error")
    SelDirArr:=StrSplit(TC_Sel,"`n","`r")
    loop SelDirArr.Length
    {
        FileMove SelDirArr[A_Index],DirPath
    }
}
SendTCUserCommand(userCommand) 
{
    ; https://www.autohotkey.com/boards/viewtopic.php?p=538463&sid=4471e03917209854441ac07ebdc70901#p538463
    static EM := 19781
    static WM_COPYDATA := 0x4A
    ansiBuf := Buffer(StrPut(userCommand, 'CP0'))
    StrPut(userCommand, ansiBuf, 'CP0')
    COPYDATASTRUCT := Buffer(A_PtrSize * 3)
    NumPut('Ptr', EM, 'Ptr', ansiBuf.size, 'Ptr', ansiBuf.ptr, COPYDATASTRUCT)
    MsgResult:=SendMessage( WM_COPYDATA,, COPYDATASTRUCT,, 'ahk_class TTOTAL_CMD')
    return MsgResult
}

zh2py(str)
{
    ; 从 php 转换而来的 (http://www.sjyhome.com/php/201311170606.html)
	; 根据汉字区位表,(http://www.mytju.com/classcode/tools/QuWeiMa_FullList.asp)
	; 我们可以看到从16-55区之间是按拼音字母排序的,所以我们只需要判断某个汉字的区位码就可以得知它的拼音首字母.

	; 区位表第一部份,按拼音字母排序的.
	; 16区-55区
	/*
		'A'=>0xB0A1, 'B'=>0xB0C5, 'C'=>0xB2C1, 'D'=>0xB4EE, 'E'=>0xB6EA, 'F'=>0xB7A2, 'G'=>0xB8C1,'H'=>0xB9FE,
		'J'=>0xBBF7, 'K'=>0xBFA6, 'L'=>0xC0AC, 'M'=>0xC2E8, 'N'=>0xC4C3, 'O'=>0xC5B6, 'P'=>0xC5BE,'Q'=>0xC6DA,
		'R'=>0xC8BB, 'S'=>0xC8F6, 'T'=>0xCBFA, 'W'=>0xCDDA, 'X'=>0xCEF4, 'Y'=>0xD1B9, 'Z'=>0xD4D1
	*/
	static FirstTable  := [ 0xB0C5, 0xB2C1, 0xB4EE, 0xB6EA, 0xB7A2, 0xB8C1, 0xB9FE, 0xBBF7, 0xBFA6, 0xC0AC, 0xC2E8
	                      , 0xC4C3, 0xC5B6, 0xC5BE, 0xC6DA, 0xC8BB, 0xC8F6, 0xCBFA, 0xCDDA, 0xCEF4, 0xD1B9, 0xD4D1, 0xD7FA ]
	static FirstLetter := StrSplit("ABCDEFGHJKLMNOPQRSTWXYZ")

	; 区位表第二部份,不规则的,下面的字母是每个区里面对应字的拼音首字母.从网上查询整理出来的,可能会有部份错误.
	; 56区-87区
	static SecondTable := [ StrSplit("CJWGNSPGCGNEGYPBTYYZDXYKYGTZJNMJQMBSGZSCYJSYYFPGKBZGYDYWJKGKLJSWKPJQHYJWRDZLSYMRYPYWWCCKZNKYYG")
	                      , StrSplit("TTNGJEYKKZYTCJNMCYLQLYPYSFQRPZSLWBTGKJFYXJWZLTBNCXJJJJTXDTTSQZYCDXXHGCKBPHFFSSTYBGMXLPBYLLBHLX")
	                      , StrSplit("SMZMYJHSOJNGHDZQYKLGJHSGQZHXQGKXZZWYSCSCJXYEYXADZPMDSSMZJZQJYZCJJFWQJBDZBXGZNZCPWHWXHQKMWFBPBY")
	                      , StrSplit("DTJZZKXHYLYGXFPTYJYYZPSZLFCHMQSHGMXXSXJYQDCSBBQBEFSJYHWWGZKPYLQBGLDLCDTNMAYDDKSSNGYCSGXLYZAYPN")
	                      , StrSplit("PTSDKDYLHGYMYLCXPYCJNDQJWXQXFYYFJLEJPZRXCCQWQQSBZKYMGPLBMJRQCFLNYMYQMSQYRBCJTHZTQFRXQHXMQJCJLY")
	                      , StrSplit("QGJMSHZKBSWYEMYLTXFSYDXWLYCJQXSJNQBSCTYHBFTDCYZDJWYGHQFRXWCKQKXEBPTLPXJZSRMEBWHJLBJSLYYSMDXLCL")
	                      , StrSplit("QKXLHXJRZJMFQHXHWYWSBHTRXXGLHQHFNMGYKLDYXZPYLGGSMTCFBAJJZYLJTYANJGBJPLQGSZYQYAXBKYSECJSZNSLYZH")
	                      , StrSplit("ZXLZCGHPXZHZNYTDSBCJKDLZAYFFYDLEBBGQYZKXGLDNDNYSKJSHDLYXBCGHXYPKDJMMZNGMMCLGWZSZXZJFZNMLZZTHCS")
	                      , StrSplit("YDBDLLSCDDNLKJYKJSYCJLKWHQASDKNHCSGAGHDAASHTCPLCPQYBSZMPJLPCJOQLCDHJJYSPRCHNWJNLHLYYQYYWZPTCZG")
	                      , StrSplit("WWMZFFJQQQQYXACLBHKDJXDGMMYDJXZLLSYGXGKJRYWZWYCLZMSSJZLDBYDCFCXYHLXCHYZJQSQQAGMNYXPFRKSSBJLYXY")
	                      , StrSplit("SYGLNSCMHCWWMNZJJLXXHCHSYZSTTXRYCYXBYHCSMXJSZNPWGPXXTAYBGAJCXLYXDCCWZOCWKCCSBNHCPDYZNFCYYTYCKX")
	                      , StrSplit("KYBSQKKYTQQXFCMCHCYKELZQBSQYJQCCLMTHSYWHMKTLKJLYCXWHEQQHTQKZPQSQSCFYMMDMGBWHWLGSLLYSDLMLXPTHMJ")
	                      , StrSplit("HWLJZYHZJXKTXJLHXRSWLWZJCBXMHZQXSDZPSGFCSGLSXYMJSHXPJXWMYQKSMYPLRTHBXFTPMHYXLCHLHLZYLXGSSSSTCL")
	                      , StrSplit("SLDCLRPBHZHXYYFHBMGDMYCNQQWLQHJJCYWJZYEJJDHPBLQXTQKWHLCHQXAGTLXLJXMSLJHTZKZJECXJCJNMFBYCSFYWYB")
	                      , StrSplit("JZGNYSDZSQYRSLJPCLPWXSDWEJBJCBCNAYTWGMPAPCLYQPCLZXSBNMSGGFNZJJBZSFZYNTXHPLQKZCZWALSBCZJXSYZGWK")
	                      , StrSplit("YPSGXFZFCDKHJGXTLQFSGDSLQWZKXTMHSBGZMJZRGLYJBPMLMSXLZJQQHZYJCZYDJWFMJKLDDPMJEGXYHYLXHLQYQHKYCW")
	                      , StrSplit("CJMYYXNATJHYCCXZPCQLBZWWYTWBQCMLPMYRJCCCXFPZNZZLJPLXXYZTZLGDLTCKLYRZZGQTTJHHHJLJAXFGFJZSLCFDQZ")
	                      , StrSplit("LCLGJDJZSNZLLJPJQDCCLCJXMYZFTSXGCGSBRZXJQQCTZHGYQTJQQLZXJYLYLBCYAMCSTYLPDJBYREGKLZYZHLYSZQLZNW")
	                      , StrSplit("CZCLLWJQJJJKDGJZOLBBZPPGLGHTGZXYGHZMYCNQSYCYHBHGXKAMTXYXNBSKYZZGJZLQJTFCJXDYGJQJJPMGWGJJJPKQSB")
	                      , StrSplit("GBMMCJSSCLPQPDXCDYYKYPCJDDYYGYWRHJRTGZNYQLDKLJSZZGZQZJGDYKSHPZMTLCPWNJYFYZDJCNMWESCYGLBTZZGMSS")
	                      , StrSplit("LLYXYSXXBSJSBBSGGHFJLYPMZJNLYYWDQSHZXTYYWHMCYHYWDBXBTLMSYYYFSXJCBDXXLHJHFSSXZQHFZMZCZTQCXZXRTT")
	                      , StrSplit("DJHNRYZQQMTQDMMGNYDXMJGDXCDYZBFFALLZTDLTFXMXQZDNGWQDBDCZJDXBZGSQQDDJCMBKZFFXMKDMDSYYSZCMLJDSYN")
	                      , StrSplit("SPRSKMKMPCKLGTBQTFZSWTFGGLYPLLJZHGJJGYPZLTCSMCNBTJBQFKDHBYZGKPBBYMTDSSXTBNPDKLEYCJNYCDYKZTDHQH")
	                      , StrSplit("SYZSCTARLLTKZLGECLLKJLQJAQNBDKKGHPJTZQKSECSHALQFMMGJNLYJBBTMLYZXDXJPLDLPCQDHZYCBZSCZBZMSLJFLKR")
	                      , StrSplit("ZJSNFRGJHXPDHYJYBZGDLQCSEZGXLBLGYXTWMABCHECMWYJYZLLJJYHLGNDJLSLYGKDZPZXJYYZLWCXSZFGWYYDLYHCLJS")
	                      , StrSplit("CMBJHBLYZLYCBLYDPDQYSXQZBYTDKYXJYYCNRJMPDJGKLCLJBCTBJDDBBLBLCZQRPYXJCJLZCSHLTOLJNMDDDLNGKATHQH")
	                      , StrSplit("JHYKHEZNMSHRPHQQJCHGMFPRXHJGDYCHGHLYRZQLCYQJNZSQTKQJYMSZSWLCFQQQXYFGGYPTQWLMCRNFKKFSYYLQBMQAMM")
	                      , StrSplit("MYXCTPSHCPTXXZZSMPHPSHMCLMLDQFYQXSZYJDJJZZHQPDSZGLSTJBCKBXYQZJSGPSXQZQZRQTBDKYXZKHHGFLBCSMDLDG")
	                      , StrSplit("DZDBLZYYCXNNCSYBZBFGLZZXSWMSCCMQNJQSBDQSJTXXMBLTXZCLZSHZCXRQJGJYLXZFJPHYMZQQYDFQJJLZZNZJCDGZYG")
	                      , StrSplit("CTXMZYSCTLKPHTXHTLBJXJLXSCDQXCBBTJFQZFSLTJBTKQBXXJJLJCHCZDBZJDCZJDCPRNPQCJPFCZLCLZXZDMXMPHJSGZ")
	                      , StrSplit("GSZZQLYLWTJPFSYASMCJBTZYYCWMYTZSJJLJCQLWZMALBXYFBPNLSFHTGJWEJJXXGLLJSTGSHJQLZFKCGNNNSZFDEQFHBS")
	                      , StrSplit("AQTGYLBXMMYGSZLDYDQMJJRGBJTKGDHGKBLQKBDMBYLXWCXYTTYBKMRTJZXQJBHLMHMJJZMQASLDCYXYQDLQCAFYWYXQHZ") ]


	static var := Buffer(2)
	
	; 如果不包含中文字符，则直接返回原字符
	if !RegExMatch(str, "[^\x{00}-\x{ff}]")
		Return str
	
	Loop Parse str
	{
		StrPut(A_LoopField, var, "CP936")
		H := NumGet(var, 0, "UChar")
		L := NumGet(var, 1, "UChar")
		
		; 字符集非法
		if (H < 0xB0 || L < 0xA1 || H > 0xF7 || L = 0xFF)
		{
			newStr .= A_LoopField
			Continue
		}
		
		if (H < 0xD8) || (H >= 0xB0 && H <=0xD7) ; 查询文字在一级汉字区(16-55)
		{
			W := (H << 8) | L
			For key, value in FirstTable
			{
				if (W < value)
				{
					newStr .= FirstLetter[key]
					Break
				}
			}
		}
		else ; if (H >= 0xD8 && H <= 0xF7) ; 查询中文在二级汉字区(56-87)
			newStr .= SecondTable[ H - 0xD8 + 1 ][ L - 0xA1 + 1 ]
	}
	
	Return newStr
}
