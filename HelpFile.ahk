/**
 * Interface for the AutoHotkey v2 help file.
 * https://github.com/G33kDude/CodeQuickTester/blob/v2-main/lib/HelpFile.ahk
 */
class HelpFile {

	/** @type {String} Base string of the URL for documentation files */
	; baseUrl := "ms-its:{}::/docs"
	baseUrl := "mk:@MSITStore:{}::/docs"

	/** @type {Map} Cache of known syntax strings by keyword */
	syntaxes := Map(), syntaxes.CaseSense := false

	/** @type {Map} Cache of known command URL fragments by keyword */
	commands := Map(), commands.CaseSense := false

	/** @type {Map} Cache of known variable URL fragments by keyword */
	variables := Map(), variables.CaseSense := false

	/** @type {Map} Cache of known URL fragments by keyword */
	lookup := Map(), lookup.CaseSense := false

	/**
	 * @param {String} path - Path to the AutoHotkey.chm file
	 */
	__New(path := A_AhkPath "\..\AutoHotkey.chm") {
		if !FileExist(path)
			return this
		this.baseUrl := Format(this.baseUrl, path)

		; Get the command reference
		page := this.GetPage("lib/index.htm")
		rows := unset
		if !IsSet(rows) ; Windows
			try rows := page.querySelectorAll(".info td:first-child a")
		if !IsSet(rows) ; Wine
			try rows := page.body.querySelectorAll(".info td:first-child a")
		if !IsSet(rows) { ; IE8
			rows := this.HTMLCollection()
			trows := page.getElementsByTagName("table")[0].children[0].children
			loop trows.length
				rows.push(trows.Item(A_Index - 1).children[0].children[0])
		}

		; Pull the keywords
		loop rows.length {
			row := rows.Item(A_Index - 1)
			for text in StrSplit(row.innerText, "/")
				if RegExMatch(text, "^[\w#]+", &match) && !this.commands.Has(match.0)
					this.commands[match.0] := "lib/" RegExReplace(row.getAttribute("href"), "^about:")
		}

		; Get the variables reference
		page := this.GetPage("Variables.htm")
		rows := unset
		if !IsSet(rows) ; Windows
			try rows := page.querySelectorAll(".info td:first-child")
		if !IsSet(rows) ; Wine
			try rows := page.body.querySelectorAll(".info td:first-child")
		if !IsSet(rows) { ; IE8
			rows := HelpFile.HTMLCollection()
			tables := page.getElementsByTagName("table")
			loop tables.length {
				trows := tables.Item(A_Index - 1).children[0].children
				loop trows.length
					rows.push(trows.Item(A_Index - 1).children[0])
			}
		}

		; Pull the keywords
		loop rows.length {
			row := rows.Item(A_Index - 1)
			if RegExMatch(row.innerText, "A_\w+", &match)
				this.variables[match.0] := "Variables.htm#" row.parentNode.getAttribute("id")
		}

		; Combine
		; out := ""
		for k, v in this.commands {
			this.lookup[k] := v
			; out .= "|" k 
		}
		; A_Clipboard := SubStr(out, 2)
		for k, v in this.variables
			this.lookup[k] := v
	}

	/**
	 * Gets an HtmlFile object for the given page
	 * @param {String} path - The given page
	 */
	GetPage(path) {
		; Strip fragment
		path := this.baseUrl "/" RegExReplace(path, "[?#].+")

		; Request the page
		xhr := ComObject("MSXML2.XMLHTTP.3.0")
		xhr.open("GET", path, True)
		xhr.send()

		; Load it into HtmlFile
		html := ComObject("HtmlFile")
		html.open()
		html.write(xhr.responseText)
		html.close()

		; Wait for it to finish parsing
		while !(html.readyState = "interactive" || html.readyState = "complete")
			Sleep 50

		return html
	}

	/**
	 * Opens the help file to the page corresponding to a given keyword
	 * 
	 * @param {String} keyword - A keyword to open the help file to
	 */
	Open(keyword := "") {
		suffix := this.lookup.has(keyword) ? this.lookup[keyword] : "index.htm"
		Run 'hh.exe "' this.baseUrl '/' suffix '"'
	}

	/**
	 * Opens the help file to the page corresponding to a given keyword
	 * in the existed hh.exe instance or a new one
	 * @param {String} keyword - A keyword to open the help file to
	 */
    HH_AHKHelp(UserKeyWords)
    {
        Win_AHK_Help:="AutoHotkey v2 Help ahk_exe hh.exe"
        if (!WinExist(Win_AHK_Help))    
        {
            run "hh.exe C:\Program Files\AutoHotkey\v2.0.2\AutoHotkey.chm"
            Hwnd:=WinWait(Win_AHK_Help,,3)
            if(!Hwnd) 
                return
        }
        suffix := this.lookup.has(UserKeyWords)
        if(suffix)
        {
            suffix:=this.lookup[UserKeyWords]
            ThisKwUrl:=this.baseUrl '/' suffix
            this.HH_NavigateTo(ThisKwUrl)
            Send "!n"  ; activate Index tab
        }
        else
        {
            this.HH_SendToUI(UserKeyWords) 
        }
    }
    HH_SendToUI(UserKeyWords)
    {
        Win_AHK_Help:="AutoHotkey v2 Help ahk_exe hh.exe"
        if (WinExist(Win_AHK_Help))
        {
            WinActivate(Win_AHK_Help)
            WinWaitActive(Win_AHK_Help, , 2)
            Send "!s"  ; Alt+S:  activate Search tab
            Sleep(500)
            Send "^+{Home}"
            Sleep(500)
            Send "{del}"
            ClipSaved :=ClipboardAll()
            A_Clipboard:=Trim(UserKeyWords)
            Send "^v"
            Sleep(500)
            Send "{enter}"
            A_Clipboard:=ClipSaved 
            ClipSaved :=""        
        }
    }
    HH_NavigateTo(vPath)
    { 
        hWnd:=WinGetID("AutoHotkey v2 Help ahk_class HH Parent")
        if hWnd
        {
            oWB := this.WBGet("ahk_id " hWnd)
            oWB.Navigate(vPath)
            oWB := ""
        }
        else
            Run "hh.exe " . vPath
    }
    WBGet(WinTitle:="ahk_class IEFrame", Svr:=1) 
    {   
        ; Reference: 
        ; C:\Program%20Files\AutoHotkey\v2.0.2\AutoHotkey.chm::/docs/lib/ComObjQuery.htm 
        ; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=39869          
        static msg := DllCall("RegisterWindowMessage", "str", "WM_HTML_GETOBJECT")
             , IID := "{0002DF05-0000-0000-C000-000000000046}"   ;// IID_IWebBrowserApp
        static VT_UNKNOWN := 13
        lResult := SendMessage(msg, 0, 0, "Internet Explorer_Server" Svr, WinTitle)
        if (lResult != "") 
        {
            GUID:=Buffer(16)
            if DllCall("ole32\CLSIDFromString", "wstr","{332C4425-26CB-11D0-B483-00C04FD90119}", "ptr",GUID) >= 0 {
                DllCall("oleacc\ObjectFromLresult", "ptr",lResult, "ptr",GUID, "ptr",0, "ptr*",pdoc := ComValue(VT_UNKNOWN, 0))
                pweb :=ComObjQuery(pdoc,IID,IID)
                ObjAddRef(pweb.ptr)
                static VT_DISPATCH := 9
                return ComValue(VT_DISPATCH, pweb.ptr)
            }
        }
     }
    

	/**
	 * Gets the syntax hints for a given keyword, if available
	 * 
	 * @param {String} keyword - The keyword to pull the syntax for
	 * 
	 * @return {String} The syntax, or empty string
	 */
	GetSyntax(keyword := "") {
		; Only look for Syntax of commands
		if !this.commands.Has(keyword)
			return ""
		path := this.commands[keyword]

		; Try to find it in the cache
		if this.syntaxes.Has(keyword)
			return this.syntaxes[keyword]

		; Get the right DOM to search
		page := this.GetPage(path)
		root := page ; Keep the page root in memory or it will be garbage collected
		if RegExMatch(path, "#\K.+", &id)
			page := page.getElementById(id.0)

		; Search for the syntax-containing element
		if !IsSet(nodes) ; Windows
			try nodes := page.getElementsByClassName("Syntax")
		if !IsSet(nodes) ; Wine
			try nodes := page.body.getElementsByClassName("Syntax")
		if !IsSet(nodes) ; IE8
			nodes := page.getElementsByTagName("pre")
		if nodes.Length
			element := nodes.Item(0)
		else {
			try {
				loop 4
					page := page.nextElementSibling
				until page.classList.contains("Syntax")
			}
		}

		text := ""
		if text == "" ; Windows
			try text := nodes.Item(0).innerText
		if text == "" ; Some versions of Wine
			try text := nodes.Item(0).innerHTML

		return this.syntaxes[keyword] := StrReplace(text, "`r")
	}

	/** Array wrapper implementing some of the HTMLCollection interface */
	class HTMLCollection extends Array {
		Item(i) => this[i + 1]
	}
}
