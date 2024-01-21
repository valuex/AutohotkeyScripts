# 1074
vMsg = 1074 ;WM_USER+50 
```
Result := SendMessage(1074, wparam, 0, ,"ahk_class TTOTAL_CMD")
```
##  wparam 取值  
* wparam=1~29, returns window handle of control. 
    * 1=leftlist   
    * 2=rightlist  
    * 3=active list	
    * 4=inactive list  
    * 5=leftheader  
    * 6=rightheader  
    * 7=leftsize  
    * 8=rightsize  
    * 9=leftpath  
    * 10=rightpath  
    * 11=leftinfo  
    * 12=rightinfo  
    * 13=leftdrives  
    * 14=rightdrives  
    * 15=leftpanel,
    * 16=rightpanel  
    * 17=bottompanel  
    * 18=lefttree  
    * 19=righttree  
    * 20=cmdline  
    * 21=curdirpanel  
    * 22=inplaceedit  
    * 23=splitpanel,
    * 24=leftdrivepanel  
    * 25=rightdrivepanel  
    * 26=lefttabs  
    * 27=righttabs  
    * 28=buttonbar  
    * 29=buttonbarvertical

*  1011/1012 to get index of first file in list (-1 if there are no files) (32/64)  
*  1009/1010 to get index of first item (0 if there is no updir, 1 otherwise) (32/64)  
*  1007/1008 to get index of current item (caret) (32/64)  
*  1005/1006 to get total number of selected items (32/64)  
*  1003/1004 to get total number of items (including those hidden by quick filter (32/64)  
*  1001/1002 to get number of items in left/right list (32/64)  
*  1000 to get active panel: 1=left, 2=right (32/64)  



## Exmaple1--check the active panel

``` autohotkey
; check the active panel
; 1- left, 2-right
Result := SendMessage(1074, 1000, 0, ,"ahk_class TTOTAL_CMD")
MsgBox Result
```

# 1075
* vMsg = 1075 ;WM_USER+51  
* TotalCMD.inc 中对应的command code 都通过1075调用
SendMessage(1075, em_code, 0, , TC_Class)

## 可接受参数的命令
;https://ghisler.ch/board/viewtopic.php?p=310263#p310263

```Autohotkey
Result := SendMessage(1075, wParam, lParam, Control, WinTitle, WinText, ExcludeTitle, ExcludeText, Timeout])
; 参数通过lParam 进行传递
； ;Place cursor on 5th item, folder OR file
PostMessage(1075 ,2049,4,,"ahk_class TTOTAL_CMD")
```
 15.05.16 Added: The following commands now accept a numeric parameter in the button bar or start menu:
* CM_WAIT
* cm_Select=2936;Select file under cursor, go to next
* CM_UNSELECT
* CM_REVERSE
* cm_GoToFirstEntry=2049;Place cursor on first folder or file
* cm_GoToFirstFile=2050;Place cursor on first file in list
* CM_SWITCHDRIVE
* CM_DELETE
* CM_LEFTSWITCHTOTHISCUSTOMVIEW
* CM_RIGHTSWITCHTOTHISCUSTOMVIEW
* CM_SEARCHFORINCURDIR
* CM_DIRECTORYHOTLIST


