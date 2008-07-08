ISHelp_Create( pGuiNum )
{
	local oldActive

	ISHelp_Gui := pGuiNum

	StringReplace ISense_m_chm, A_AhkPath, .exe, .chm
	
	Gui, %ISHelp_Gui%: +LastFound -Caption ToolWindow +AlwaysOnTop
	ISHelp_hwnd := WinExist()

	IEAdd( ISHelp_hwnd, 0, 0, ISHelp_width, ISHelp_height, "about:blank")

	Gui, %ISHelp_Gui%:Show, x-10000 y-10000 NoActivate

	ISHelp_SetWindow( true ) 
	ISHelp_SetFontSize( ISHelp_fontSize ) 


	Gui %ISHelp_Gui%:Hide
}

;----------------------------------------------------------------------------------------------

ISHelp_SetWindow(flag) {
	global

	if (flag) {
		 WinSet, Region, 0-0 W%ISHelp_width% H%ISHelp_height% R20-20, ahk_id %ISHelp_hwnd% 
		 WinSet, Transparent, %ISHelp_trans%, ahk_id %ISHelp_hwnd%
	}
	else {
		WinSet, Region, , ahk_id %ISHelp_hwnd% 
		WinSet, Transparent, OFF, ahk_id %ISHelp_hwnd%
	}
}

;----------------------------------------------------------------------------------------------

ISHelp_Zoom( direction ) {
	local w, h

	if (direction = "in") {
		w := A_ScreenWidth, h := A_ScreenHeight
		ISHelp_SetWindow(false)

;		DllCall("lbbrowse3\MoveBrowser", "uint", 0, "uint", 0, "uint", w, "uint", h)
		IEMove(0,0,w,h)
		WinMove, ahk_id %ISHelp_hwnd%,,0,0,w,h
		WinActivate, ahk_id %ISHelp_hwnd%

		ISHelp_zoomed := true
	}

	if (direction = "out") {
		w := ISHelp_width, h := ISHelp_Height
;		DllCall("lbbrowse3\MoveBrowser", "uint", 0, "uint", 0, "uint", w, "uint", h)
		IEMove(0,0,w,h)
		WinMove, ahk_id %ISHelp_hwnd%,,,,w,h

		ISHelp_zoomed := false
	}
}


;----------------------------------------------------------------------------------------------

;ISHelp_OnExit() {
   ;	DllCall("lbbrowse3\DestroyBrowser")
;}

;----------------------------------------------------------------------------------------------

ISHelp_SetFontSize( size ) {
;	DllCall("lbbrowse3\DoFontSize", "int", size)
	IEDoFontSize( size )
;	msgbox %size%
}

;----------------------------------------------------------------------------------------------

; Now requires 1.0.47.01 ***
; "Fixed WM_TIMER not to be blocked unless it's posted to the script's main window."
ISHelp_Show(pX, pY, pCmnd)
{
	local Url2Load

	pCmnd := ISHelp_GetHelpPage( pCmnd )
	if (pCmnd != ISHelp_cmnd)
	{
		Url2Load = %pCmnd%     ;*** All work now done in GetHelpPage
		
; 		Url2Load = ms-its:%ISense_m_chm%::/docs/commands/%pCmnd%.htm
;		DllCall("lbbrowse3\Navigate", "str", Url2Load)

		IELoadURL( Url2Load )
	}

	if (pY > A_ScreenHeight - 400)
		pY := pY - 500

	if (ISHelp_zoomed)
	{
		ISHelp_Zoom( "out" )
		Gui, %ISHelp_Gui%:Show, x%pX% y%pY% w%ISHelp_width% h%ISHelp_height% NoActivate, ISense_Help
		ISHelp_SetWindow(true)
	}
	else Gui, %ISHelp_Gui%:Show, x%pX% y%pY% w%ISHelp_width% h%ISHelp_height% NoActivate, ISense_Help

	ISHelp_visible := true
	ISHelp_cmnd := pCmnd
	return 1
}

;----------------------------------------------------------------------------------------------
 
ISHelp_Hide()
{
	global

	Gui %ISHelp_Gui%:Hide
	ISHelp_visible := false
}

;----------------------------------------------------------------------------------------------

ISHelp_GetHelpPage( pCmnd )
{   
  global
  local res, AnchorList
  static initialised

  if !initialised
  {
    ISense_m_SendMessage        =  commands/PostMessage
    ISense_m_IfWinNotActive     =  commands/IfWinActive
    ISense_m_IfWinNotExist      =  commands/IfWinExist
    ISense_m_StringTrimRight    =  commands/StringTrimLeft
    ISense_m_StringUpper        =  commands/StringLower
    ISense_m__IfWinExist        =  commands/_IfWinActive

    ;commands/Send.htm
    AnchorList = SendRaw,SendInput,SendPlay
    Loop, Parse, AnchorList, `,
      ISense_m_%A_LoopField% = commands/Send.htm
      
    ;commands/IfEqual.htm
    AnchorList = if,IfNotEqual,IfGreater,IfGreaterOrEqual,IfLess,IfLessOrEqual
    Loop, Parse, AnchorList, `,
      ISense_m_%A_LoopField% = commands/IfEqual.htm

    ;commands/%A_LoopField%.htm#
    AnchorList = OnMessage,RegExMatch,RegExReplace,RegisterCallback,GetKeyState,DllCall
    Loop, Parse, AnchorList, `,
      ISense_m_%A_LoopField%[] = commands/%A_LoopField%.htm

    ;commands/ListView.htm#
    AnchorList = LV_Add,LV_Insert,LV_Modify,LV_Delete,LV_ModifyCol,LV_InsertCol
                ,LV_DeleteCol,LV_GetCount,LV_GetNext,LV_GetText,LV_SetImageList
    Loop, Parse, AnchorList, `,
      ISense_m_%A_LoopField%[] = commands/ListView.htm#%A_LoopField%
      
    ;commands/ListView#IL
    AnchorList = IL_Create,IL_Add,IL_Destroy
    Loop, Parse, AnchorList, `,
      ISense_m_%A_LoopField%[] = commands/ListView.htm#%A_LoopField%
      
    ;commands/TreeView#
    AnchorList = TV_Modify,TV_Delete,TV_GetSelection,TV_GetCount,TV_GetParent
                 ,TV_GetChild,TV_GetPrev,TV_GetNext
    Loop, Parse, AnchorList, `,
      ISense_m_%A_LoopField%[] = commands/TreeView.htm#%A_LoopField%
      
    ;commands/Function#
    AnchorList = FileExist,InStr,SubStr,StrLen,WinActive,WinExist
                 ,Asc,Chr,IsLabel,NumGet,NumPut,VarSetCapacity,Abs,Ceil,Exp,Floor
                 ,Log,Ln,Mod,Round,Sqrt,Sin,Cos,Tan,ASin,ACos,ATan
    Loop, Parse, AnchorList, `,
      ISense_m_%A_LoopField%[] = Functions.htm#%A_LoopField%
   
    initialised := true
  }

  StringReplace, pCmnd, pCmnd, #, _
  res := ISense_m_%pCmnd%

  If SubStr( res, 1, 6) = "about:"                         ;*** User function - generate dynamic help..
    res := ISHelp_GenerateDynamicHelpPage( res ), ISense_m_%pCmnd% := res, res := ISense_m_%pCmnd%

  if res =                                                 ;*** Standard AHK cmnd
    res := "commands/" . pCmnd . ".htm"

  If !InStr(res, ":")
    res := "ms-its:" . ISense_m_chm . "::/docs/" . res

    ;*** example from .mht files (not implemented yet...)
; 		Url2Load = mhtml:file://D:\THUMB DRIVE DEVEL\PROGS\AutoHotkey\Lib\CmnDlg.mht#ChooseColor

  Return, res
}

/**** Okay, so this is currently pretty lame. I mostly wanted to reserve a place for this
       & would like to enhance it in several ways.  There is something that makes me feel
       warm and fuzzy about having my functions spring to life in dynamic help  :)
       
 - Perhaps file could be parsed to seek commented notes (Natural Docs)
 - It might be useful to open in DHTML type control to provide a dynamic notetaking tool
*/
ISHelp_GenerateDynamicHelpPage( pCmnd )     ;***
{
  local LoopField, html, html2, ParamDesc
  
  If !RegExMatch( pCmnd, "m)about:(<b>)?(?<Cmnd>.*)\((?<Params>.*)\)", m )
    return pCmnd
  RegExMatch( RegExReplace( RegExReplace( FileData, "`n", "`r" ), "`r`r", "`r" ), "^.*(?P<NaturalDoc>Function.*);.*" . mCmnd . "\(.*$", m )

  If mNaturalDoc  {
    html := "about:<b>" . RegExReplace( mNaturalDoc, "`r", "<br>`r" )
    mCmnd := mParams := mNaturalDoc := mIsByRef := mParam := mDefaultVal := m1 := pCmnd:=""
    return html
  }
  Else  {
    html := "about:<b>" . mCmnd . "("
    Loop, Parse, mParams, `,
    {
      If A_LoopField =
        break
      html .= A_Index > 1 ? ", " . A_LoopField : A_LoopField
      F = %A_LoopField%   ; trim whitespace..
      If !(SubStr( F, 1, 5 ) = "ByRef") && !(InStr( F, "=" ))                               ; Standard InputVar
        html2 .= "<b>" . F . "  -</b> "
                . "Input parameter essentially the same as a local variable."
                . "<br>`n`n"
      Else If RegExMatch( F, "(?<IsByRef>[B|b]y[R|r]ef )?(?<Param>.*)= ?""(?<DefaultVal>.*)""", m ) ; Has default value..
        html2 .= "<b>" . mParam . "  -</b> "
                . (mIsByRef ? "ByRef parameter.  <i>" . mParam . "</i>   acts as an alias for the variable passed to it during call.  "
                            : "")
                . "Defaults to  <i>'" . mDefaultVal . "'</i>  if not specified."
                . "<br>`n`n"
      Else If SubStr( F, 1, 5 ) = "ByRef"                                                   ; Standard ByRef
        html2 .= "<b>" . SubStr( F, 7 ) . "  -</b> "
                . "ByRef parameter.  <i>" . SubStr( F, 7 ) . "</i>   acts as an alias for the variable passed to it during call.  "
                . "<br>`n`n"
    }
  }
  mCmnd:="", mParams:="", mIsByRef:="", mParam:="", mDefaultVal:="", m1:=""
  return html . ")</b><p>" . html2 . "</table><p></b>`n<i>More dynamic help functionality coming soon...</i>"
}

#include includes
#include CoHelper.ahk
#include IEControl.ahk
#include ..
