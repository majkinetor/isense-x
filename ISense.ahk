; Isense_trace := true					; uncomment to enable ISense_Trace tooltip for debug
#NoEnv
#SingleInstance force
SetBatchLines, -1
CoordMode, Tooltip, Screen

	;NAMESPACES: ISense, Info, Tooltip, ISHelp, RoutineInfoGui, ActiveGoTo
	ISENSE_Init()	
return


ISENSE_Init( lastGUI=0, subMenu="", bStandalone=true )
{
	local hasConfig		   

	CoordMode, Caret, screen			; required
	SetKeyDelay, 0						; required
	SetTitleMatchMode, 2				; required
	
	;set merging environment
	Isense_title		:= "ISense"	
	Isense_version		:= "1.5.3"
	ISense_standalone	:= bStandalone
	ISense_trayMenu		:= subMenu
  
 
	ISense_SetMenu()
	hasConfig := ISense_GetConfig()

	;create GUIs
	Info_Create( lastGui + 1 )			; ceate info window
	ISense_CreateFonts(lastGui + 3)	; create font handles
	ISHelp_Create(lastGui + 2)			; create help window
	Tooltip_GUI    := lastGui + 4		; reserve gui number for Tooltip, Setup, & ActiveGoto  ***
	ISSetup_GUI    := lastGui + 5
	ActiveGoTo_GUI := lastGui + 6

	;read AHK commands into array
	ISense_ReadCommandSyntax()			; read all commands into array

	;init global variables
	ISense_endKyes0 = {Enter}{HOME}{END}{PGUP}{PGDN}{Left}{Right}{Up}{Down}{Tab}{Escape}{space}{BackSpace}`,`;
	ISense_endKyes1 = {Enter}{HOME}{END}{PGUP}{PGDN}{Left}{Right}{Up}{Down}{Escape}{BackSpace}`;
	Isense_paramMode = 0	; application mode
	ISense_monitor	 = 0	; start with monitor OFF, turn it ON on space & Tab

	;set the hotkeys
	ISense_SetHotkies( "on" )

	if !hasConfig
		ISSetup_Create()
																															 
	;ISSetup_Create()

	OnExit,  ISense_OnExit

  ActiveGoTo_Init()   ;*** Starts ActiveGoto..

	;enter loop
	if (ISense_standalone)
		ISense_WatchForInput()

	return, lastGui + 5
}

;---------------------------------------------------------------------------------------------
ISense_OnExit:
  Gosub, RoutineInfoGui_Close
	ExitApp
return
;---------------------------------------------------------------------------------------------

ISense_SetHotkies( state ){	
	global

	Hotkey, IfWinActive, %ISense_Opt_TitleWord%
	Hotkey, %ISense_Hotkey%,	_ISense_HotkeyHandler,   %state% UseErrorLevel
	Hotkey, %ISense_onOffKey%,	ISense_OnOffKeyHandler,	%state% UseErrorLevel
}

;---------------------------------------------------------------------------------------------		

ISense_OnOffKeyHandler:
	ISense_off := !Isense_off
	if (Isense_off)	
			Menu, %Isense_trayMenu%, icon, res\disable.ico          
	else	Menu, %Isense_trayMenu%, icon, res\enable.ico		 
return	

;---------------------------------------------------------------------------------------------

ISense_HotkeyHandler()           
{	
	global
	local tmp, x, key

	if (Info_visible) 
		return		

	if (Tooltip_visible)
  	if !ISHelp_Visible
  	{
  		ISHelp_Show( Tooltip_X, Tooltip_Y + 60, Isense_selection )
  		return
  	}
  	else
  	{
  		ISHelp_Hide()
  		Return,
  	}

  tmp := ISense_GetLineMethod%Isense_CurrentGetLineMethod%()
	Isense_HandleSelection(tmp)

}

_ISense_HotkeyHandler:
	ISense_HotkeyHandler()
return

;----------------------------------------------------------------------------------------------
ISense_Sleep(value=1000, reason="")
{
	global

	ISense_Trace("Sleeping: " . ISense_activeTitle . "`nHandle:" . ISense_editorHwnd . "`nReason: " . reason)

	ISense_sleeping := true
	Sleep, %value%
}

;----------------------------------------------------------------------------------------------

Isense_HandleSelection( pSel )  {
  global ISense_lastMatch, ISense_monitor, ISense_lastWord, ISense_selection
  static init, Lang_Delim, LangRE

  IfEqual, pSel,, return
  If !init  {     ;--this can be pulled from ini...
    Lang_Delim := ","
    LangRE     := "J)("
                .   "(?P<Ignore>^(?P<Start>.*)\((?U).*(?-U)\)(?P<End>.*))" . "|"
                .   "(?P<Found>(.* )?(?P<Cmnd>[^\(]*\()(?P<Params>.*))"    . "|"
                .   "(?P<Found>(?P<Cmnd>[a-zA-Z0-9_\s]+),?(?P<Params>.*))"
                . "$)"
    init := true
  }

	;remove spaces and tabs from the start of the selection
	ISense_TrimLeft( pSel )

  ;get the command and parameters
  Loop,  {
    RegExMatch( pSel, LangRE, m )
    mIgnore ? ( pSel := mStart . mEnd )
    If mFound
      break
    Sleep, 1
  }

  If SubStr( mCmnd, 0, 1 ) = "("
    mCmnd := SubStr( mCmnd, 1, StrLen( mCmnd )-1 ) , cmndType := "[]"

	ISense_FindMatches( mCmnd . cmndType )
	!ISense_lastMatch ? ( mParams := "" )

	;Rise info or tooltip mode and set internal variables they use before that.
	ISense_monitor := true
	if mParams =
		ISense_lastWord := mCmnd     ,   ISense_lastMatch ? Info_Show( ISense_lastMatch )
	else {
		ISense_selection := mCmnd . cmndType
		ISense_lastWord := mParams
		ISense_ESetParamMode()
		Tooltip_Show(-1, ISense_GetCurrentParam( mParams ))
	}
}

	
;----------------------------------------------------------------------------------------------

ISense_GetCurrentParam( pParams )
{
	p = 0 
	loop, % StrLen( pParams )
	{
		adr := &pParams + A_Index
		c := chr(*adr)
		if ( c="," )
			if chr( *(adr-1) ) != "`"
				p++	
	}

	Return p + 1
}

;----------------------------------------------------------------------------------------------
; Check if editor is active. ISense Help windows is considered as editor	
;	return true or false
;
ISense_EditorActive()
{
	global

	ISense_editorHwnd := WinExist("A")
	WinGetTitle, ISense_activeTitle, A

  
	if ISense_activeTitle = ISense_Help
		return 1

	IfNotInString, ISense_activeTitle, %ISense_Opt_TitleWord%
		return 0


	return 1	
}	 

;---------------------------------------------------------------------------------------------
; Main loop
; 
ISense_WatchForInput()
{
	local c, endKey, lastKey,	b1, b2
	
	loop
	{
		;Editor window check to turn of 
		;open ISense windows or just to sleep
																				
		WinGetTitle, c, A
		b1 := !ISense_EditorActive()
		b2 := (Isense_currentTitle != "") AND (Isense_currentTitle != c) AND (c != "ISense_Help")

		if ISense_Off || b1 || b2
		{
			ISense_EResetMode()
			ISense_Sleep(1000, "NOTEditorActive=" b1 "  TitleChanged=" b2)
		}

		; Editor is active, get next charachter, timeout 1 second just not to stuck the script here
		ISense_sleeping := false
		Input, lastKey, L1 I V T1, % ISense_endKyes%ISense_paramMode%
		if (errorlevel = "Timeout")
		{
			ISense_Trace(".", true)
			continue	
		}

	  endKey = %ErrorLevel%
		If (endKey = "Max" AND ISense_monitor)
		{ 
			StringRight c, ISense_lastWord, 1					;get the key before last one
			ISense_lastWord .= lastKey
			ISense_Trace(Isense_lastWord)
			if (ISense_paramMode && lastKey = ",")
			{
				;check for escape char
	 			if c != ``
					Isense_HandleEndKeys("$,")
 			}
		}
		else
		{
			StringMid endKey, endKey, 8, 64
			ISense_HandleEndKeys( endKey )
			if (endKey != "Backspace")
				continue
		}

		ISense_ESetInfo()
	} ;end of loop
} 

;----------------------------------------------------------------------------------------------
; Rise events on end keys
;
ISense_HandleEndKeys( pEndKey )
{
	global
	local tmp

	if !Isense_monitor
		if pEndKey in Space,Tab,Enter
		{
			;!!! for languages with more then one command in a line
			; here we have the problem when FindMatches return nothing
			ISense_Trace("monitoring...")
			ISense_monitor := true			
			return
		}

	if !Isense_paramMode
		if pEndKey = Space
		{
			StringReplace tmp, Isense_lastWord, %A_Space%
			if tmp !=
				Isense_lastWord .= A_Space
			return
		}

	if (pEndKey = "Enter")
	{
		Isense_EResetMode()	

		ISense_Trace("monitoring...")
		ISense_monitor := true
		return
	}

	if (pEndKey = "BackSpace")
	{
		ISense_EErase() 
		return
	}

	;on TAB and "," replace the text if match is found
	if (pEndKey = "Tab"  OR   pEndKey = ","  OR  pEndKey = "Click")
	{
		Gui %Info_GUI%:Submit, NoHide
		if !Isense_EEvaluate(pEndKey)
		{
			;if the user typed something then add it to the last word
			;if only spaces and tabs are present, don't do anything
			StringReplace tmp, Isense_lastWord, %A_Tab%
			if tmp !=
				Isense_lastWord .= A_Tab
		}
		return
	}

	;reset recognition on those keys 
	if pEndKey in Home,PgUp,PgDn,Up,Down,Left,Right,;
	{
		ISense_Trace("reset mode")
		Isense_EResetMode()	
		return
	}

	;this "," is from parameter section
	if (pEndKey = "$,")
	{
		Tooltip_Show(-1, Tooltip_bold + 1) 
		return
	}
}

;----------------------------------------------------------------------------------------------
;EVENTS: Show Info window or hide it
;
ISense_ESetInfo()
{
	global 
	local len

	if (ISense_paramMode)
		return

	ISense_Trace("monitoring: " . ISense_lastWord)
	len := StrLen( ISense_lastWord )

	if (len >= ISense_Opt_MinLen)
	{
		ISense_FindMatches( ISense_lastWord )
		if ISense_lastMatch !=
			Info_Show( ISense_lastMatch )
		else
			Info_Hide()
	}
	else Info_Hide()
}

;----------------------------------------------------------------------------------------------
;EVENTS: Set parameter mode
;
Isense_ESetParamMode()
{
	global
	local params

	Isense_paramMode := true 

	params := ISense_aParams%ISense_firstIdx%
	StringSplit, Isense_aParams, params, `,,
	Tooltip_Show(A_CaretX, A_CaretY - 30)
}

;----------------------------------------------------------------------------------------------
;EVENTS: evaluate best metch up to that moment
;
;   Try to expand the pISense_lastWord 
;	Return TRUE on success FALSE otherwise
;
Isense_EEvaluate(pEndKey)
{
	local cntDelete, selection, cmndType

	If !Info_Visible
		return 0

	If (SubStr( ISense_selection, -1, 2 ) = "()")      ;*** While info shows ().. it needs to be converted to []
    selection := SubStr( ISense_selection, 1, StrLen(ISense_selection)-2 )
      , cmndType         := "[]"  
      , ISense_selection := selection . cmndType
  Else
    selection := ISense_selection

  ISense_FindMatches( ISense_selection )
	Info_Hide()
		
	;delete typed word         ;*** I may make this another Editor method type..
	If ISense_CurrentEditorTypeNum = 13    ;Metapad ctrl break difference
    SendInput, ^+{left 2}
  Else
    SendInput, ^+{left}
    
  ; If directive..
  ; ..& editor isn't notepad or EditPlus (all others have ctrl break at beginning of word.)
  If SubStr( Selection, 1, 1) = "#"   
              && (ISense_CurrentEditorTypeNum != "8" && ISense_CurrentEditorTypeNum != "7")
    SendInput, +{left}      ; highlight extra '#' char

/*
	cntDelete := StrLen(ISense_lastWord) + 1
	if pEndKey = Click
		cntDelete--
 	SendInput, {Backspace %cntDelete%}   
*/

	;type the desired word (dynamic call)
	ISense_SendSelectionMethod%ISense_CurrentSendLineMethod%( selection, cmndType )
      
	Sleep, 30

	ISense_ESetParamMode()
	ISense_lastWord  =

	ISense_Trace("Evaluated")
	return 1
}

;----------------------------------------------------------------------------------------------
;EVENTS: Reset modefrom paramMode
;
Isense_EResetMode()
{
	global
	ISense_Trace("reset mode")

	Info_Hide()
	Tooltip_Close()
	ISHelp_Hide()

	ISense_lastWord		=
	Isense_paramMode	= 0
	ISense_monitor		= 0
	ISense_currentTitle =
}

;----------------------------------------------------------------------------------------------
;EVENTS: Erase last charachter typed
;
Isense_EErase()
{
	global 
	local c

	;check if user deleted all parameters
	if (ISense_paramMode AND ISense_lastWord = "")
	{
		ISense_EResetMode()
		return
	}

	StringRight c, ISense_lastWord, 1
	StringTrimRight, ISense_lastWord, ISense_lastWord, 1

	;if deleting "," in paramMode 
	if (ISense_paramMode AND c = ",")
	{
		ISense_Trace("Erase - " . ISense_lastWord)

		;check for escape char
		if ISense_lastWord !=
		{
			StringRight c, ISense_lastWord, 1
			if c = ``
				return
		}

		;show previous parametar
		Tooltip_Show(-1, Tooltip_bold - 1)
	}
}

;-------------------------------------------------------------------------------------------
; Tooltip is shown for the first time. Display parameters and bold the first one
;
Tooltip_Create( pX, pY ) {
	local sWidth, gWidth, str

	Tooltip_x := pX
	ToolTip_y := pY

	;set up gui window
	Gui %Tooltip_GUI%:+AlwaysOnTop -Caption +LastFound ToolWindow 
	Gui %Tooltip_GUI%:Color, %Tooltip_colorBG%
	Gui %Tooltip_GUI%:Font, s10 , Courier New
	Tooltip_hwnd := WinExist()

	;create statatics
	gWidth = 5
	loop, %ISense_aParams0%
	{
		str    := ISense_aParams%A_Index%
		sWidth := StrLen(str) * 8 + 8	

    If A_Index = 1                              ;***
      Gui %Tooltip_Gui%:Add, Text, c%Tooltip_colorFG% x%gWidth% y2 h28 w%sWidth%, %str%
    Else
      Gui %Tooltip_Gui%:Add, Text, c%Tooltip_colorFG% x%gWidth% y2 h28 w%sWidth%, `,%str%
		gWidth += sWidth
	}
	gWidth += 5		
	Gui %Tooltip_Gui%:Show, x%pX% y%pY% h26 w%gWidth% NoActivate, ISense_Tooltip
	WinSet, Transparent, %Tooltip_trans%
	WinSet, Region, 0-0 W%gWidth% H20 R5-5, ahk_id %Tooltip_hwnd%	 

	if (ISHelp_alwaysShow)
		ISHelp_Show(pX,pY+60, ISense_selection )

	Tooltip_SetBold( 1 )
	Tooltip_visible := true
}

;-------------------------------------------------------------------------------------------
; Show tooltip with parameter help
; Arguments: pX - x position, pY - y position
;            pX < 0 - change parameter boldness, pY - parameter to be bolded
;

Tooltip_Show( pX, pY )
{
	global 

	if (pX >= 0)
		return Tooltip_Create(pX, pY)

	if (pY > ISense_aParams0) {
		Tooltip_Close()	
		ISHelp_Hide()
	}
			
	ISense_Trace("Parameter: " . pY . "   LW: " . ISense_lastWord) 
	Tooltip_SetBold( pY )	
}

;----------------------------------------------------------------------------------------------

Tooltip_Close()
{	
	global
	Gui %Tooltip_GUI%:Destroy
	Tooltip_visible := false		
}

;----------------------------------------------------------------------------------------------
; Create dummy window to serve as font supplier
;
ISense_CreateFonts(g)
{
	global ISense_fNormal, ISense_fBold, tooltip_hwnd

 	Gui %g%:+LastFound +ToolWindow
	hwnd := WinExist()
		 
	Gui %g%:Font, s10, Courier New
	Gui %g%:Add, Text, , dummy
	Gui %g%:Font, bold s10, Courier New
	Gui %g%:Add, Text, , dummy
	Gui %g%:Show, x-5000 y-5000 NoActivate  

	SendMessage, 0x31, 0, 0, Static1, ahk_id %hwnd%
	ISense_fNormal := ErrorLevel

	SendMessage, 0x31, 0, 0, Static2, ahk_id %hwnd%
	ISense_fBold := ErrorLevel
}

;----------------------------------------------------------------------------------------------
; Set parameter pNO to be bold and reverse previously bolded parameter 
; Tooltip_bold contains last bolded parameter
;
Tooltip_SetBold( pNo )
{
	global

	SendMessage, 0x30, ISense_fNormal, 0, Static%Tooltip_bold%, ahk_id %tooltip_hwnd%
	SendMessage, 0x30, ISense_fBold, 0, Static%pNo%, ahk_id %tooltip_hwnd%
	DllCall("InvalidateRect", "uint", Tooltip_hwnd, "uint", 0, "uint", 0)
	Tooltip_bold := pNo
}

;----------------------------------------------------------------------------------------------
;*** New function; split from functionality of CreateSyntaxArray
;                 since array will be called to refresh dynamic function list
ISense_ReadCommandSyntax()        
{
  Global
  FileRead, ISense_AllStaticCmds, %A_ScriptDir%\res\Commands.txt
  ISense_CreateSyntaxArray( ISense_AllStaticCmds )
}

ISense_CreateSyntaxArray( InCMDs )    ;*** MOD
{
	local fullCmnd, cmnd, c, lastDict, params

  Sort, InCMDs
  Loop, Parse, InCMDs, `n, `r
	{
		fullCmnd := A_LoopField

		; Directives have a first space instead of a first comma. Use whichever comes first.
		c := ISense_GetNextDelimiter( fullCmnd, ",,," . A_Space )
		if c > 0
		{
				StringMid cmnd, fullCmnd, 1, c-1
				StringMid params, fullCmnd, c+1, 256
		}
		else {
				cmnd := fullCmnd
				params := "   no parameters   "
		}

		StringReplace, params, params, ``n, `n, All
		StringReplace, params, params, ``t, `t, All
		ISense_TrimLeft(params)
		StringMid c, params, 1, 2

		; parenthesis in functions are unacceptable for var names (for array..) ;***
    If InStr( cmnd, "()") {
      StringReplace cmnd, cmnd, (, [
      StringReplace cmnd, cmnd, ), ]
    }
  
		; first comma will make some problems in parameter tracking so remove it
		if ( c = "[," )
			StringReplace params, params, `,
				
		;save the commands to arrays
		ISense_aCmd%A_Index%	:= cmnd
		ISense_aParams%A_Index% := params

		; Set the dictionary for faster search
		StringLeft c, cmnd, 1
		if (c != lastDict)
		{
			lastDict := c
			ISense_aDict_%lastDict% := A_Index
		}
	}
}

;----------------------------------------------------------------------------------------------

Info_Activate()
{
	global

	ControlSend selection1, {Down 2}, ahk_id %Info_hwnd%
	SendInput {Left}
	WinActivate ahk_id %Info_hwnd%
}

;----------------------------------------------------------------------------------------------

Info_Create(pGuiNum)
{
	global 

	Info_GUI := pGuiNum

	Gui %Info_GUI%: +labelInfo_ ToolWindow
	Gui %Info_GUI%:Font, normal, Courier
	GUI %Info_GUI%:Add, ListBox, vISense_selection gInfo_OnLBClickDispatch x20 y0 w280 h150		

	Gui %Info_GUI%:Font, bold, MS Sans Serif
	GUI %Info_GUI%:Add, Button, +0x8000 gInfo_OnCloseDispatch x2 y2 w15 h15, x


	Gui %Info_GUI%:+AlwaysOnTop -Caption +LastFound
	Info_hwnd := WinExist() + 0
}

;----------------------------------------------------------------------------------------------

Info_Show( pTxt )
{
	local x, y

	;get the title of the window we are using
	; since the user can switch to another code window in the editor
	WinGetTitle, ISense_currentTitle, A

  StringReplace pTxt, pTxt, [, (, All    ;*** functions. Converting so they look proper in info win
  StringReplace pTxt, pTxt, ], ), All
    
	;set the content of the ListBox
	GuiControl, %Info_GUI%:, ISense_selection, %pTxt%

	if !Info_Visible
	{
		Info_Visible := true

		x := A_CaretX
		y := A_CaretY + 20

		GUI %Info_GUI%:Show,  x%X% y%Y% w300 h150 NoActivate , ISense_Info
	}
}

;----------------------------------------------------------------------------------------------

Info_Hide()
{
	global

	if !Info_Visible
		return

	Info_Visible := false
	GUI %Info_GUI%:Hide
}

;----------------------------------------------------------------------------------------------

Info_OnClose()
{
	global
	ExitApp
}
								 
Info_OnCloseDispatch:
	Info_OnClose()
return

;----------------------------------------------------------------------------------------------
; handle single mouse clicks					  
Info_OnLBClickDispatch:

	if !Info_send
	{
		Info_send := false
		ISense_HandleEndKeys("Click")
	}
return		

;----------------------------------------------------------------------------------------------
;	The letter is valid if it is normal charachter or # and if there is command starting with that 
;	letter
;
ISense_IsValidLetter( c )
{
	global
	local a

	a := asc(c)
	if !((a >= 65 AND a <= 90) OR ( a>=97 AND a<=122) OR a=35)
		return 0

	if ISense_aDict_%c% =
		return 0
	
	return 1
}
	 
;----------------------------------------------------------------------------------------------
;	Find all matches based on the prefix pWord
;	Also remember index of first match, so we can use the same function to get the index of 
;	particular item that is selected.
;	
;	The variable to receive the mathch(es) is Isense_lastMatch
;
ISense_FindMatches( pWord )
{
	global 
	local c, start, cmd, iStart, lenWord, q, tmp, idx

	ISense_lastMatch =
	StringLeft c, pWord, 1
	if !ISense_IsValidLetter( c )
		return

	iStart := ISense_aDict_%c%

	q := 0
	lenWord := StrLen( pWord )

; msgbox, iStart = %iStart%
	Loop
	{
		idx := A_Index + iStart - 1
		cmd := ISense_aCmd%idx%

		if ( chr(*(&cmd)) != c )
			break

		StringLeft tmp, cmd, lenWord
		if ( tmp = pWord )
		{
			if (q = 0)		 
				ISense_firstIdx := idx

			q++
			ISense_lastMatch .= "|" . cmd

			if (q = 1)
				ISense_lastMatch .= "|" 
		}
	}	

	;add another | for selection. Not required if there are more then 1 item in the match
	if (q = 1)
		ISense_lastMatch .= "|"

	return ISense_lastMatch
}

;----------------------------------------------------------------------------------------------

Info_Escape:   
	Info_Hide()
return

;----------------------------------------------------------------------------------------------

ISense_SetMenu()
{
	global 

	if (ISense_standalone)
	{
		ISense_trayMenu := "Tray"
		Menu, %Isense_trayMenu%, icon, res\enable.ico
		Menu, %Isense_trayMenu%, NoStandard
		Menu, %ISense_trayMenu%, Tip, %ISense_title% %ISense_version%
	}

	Menu, %isense_trayMenu%, add, Setup,	isense_trayDispatch
	Menu, %isense_trayMenu%, add, On/Off,	isense_trayDispatch
	Menu, %isense_trayMenu%, Default, Setup
	Menu, %isense_trayMenu%, add

	Menu, %isense_trayMenu%, add, Help,		isense_trayDispatch
	Menu, %isense_trayMenu%, add, About,	isense_trayDispatch
	
	if (ISense_standalone)
	{
		Menu, %isense_trayMenu%, add
		Menu, %isense_trayMenu%, add, Reload,	isense_trayDispatch
		Menu, %isense_trayMenu%, add, Exit,		isense_trayDispatch
	}
}

;----------------------------------------------------------------------------------------------

ISense_TrayHandler()
{
	global 
	local msg

	if ( A_ThisMenuItem = "On/Off" )
		gosub ISense_OnOffKeyHandler

	if ( A_ThisMenuItem = "Setup" )
		ISSetup_Create()
	
	if ( A_ThisMenuItem = "About" )
	{
		
		msg = 
		(LTrim
			%Isense_title%  %Isense_version%

			Created by:	

			majkinetor <miodrag.milic@gmail.com>
			freakkk <coreydwilliams@gmail.com>
				
			HomePage:
			http://code.google.com/p/isense-x/


			2007, 2008
		)

		MsgBox 48, About, %msg%
	}

	if ( A_ThisMenuItem = "Exit" )
		ExitApp

	if ( A_ThisMenuItem = "Reload" )
		Reload
										
	if ( A_ThisMenuItem = "Help" )
		Run Readme.txt
}					

ISense_trayDispatch:
	ISense_TrayHandler()
return

ISense_onoffHotkey:

return

;----------------------------------------------------------------------------------------------

ISense_GetConfig()
{
	global 
	
	res := true
	if !FileExist( "Config.ini" )
		res := false


	IniRead, ISense_hotkey,			Config.ini, ISense,		hotkey,		^Space
	IniRead, ISense_onOffKey,		Config.ini, ISense,		onOffKey,	!e
	IniRead, ISense_Opt_TitleWord,	Config.ini,	ISense,		TitleWord,	.ahk 
	IniRead, ISense_Opt_MinLen,		Config.ini,	ISense,		MinLen,		3 

	IniRead, Tooltip_colorBG,		Config.ini, Tooltip,	colorBG,	0xEEAA99
	IniRead, Tooltip_colorFG,		Config.ini, Tooltip,	colorFG,	0x0
	IniRead, Tooltip_trans,			Config.ini, Tooltip,	Trans,		250

	IniRead, ISHelp_alwaysShow,		Config.ini, Help,		AlwaysShow, 0
	IniRead, ISHelp_trans,			Config.ini, Help,		Trans,		200
	IniRead, ISHelp_height,			Config.ini,	Help,		Height,		400 
	IniRead, ISHelp_width,			Config.ini,	Help,		Width,		600 
	IniRead, ISHelp_fontSize,		Config.ini,	Help,		fontSize,	3

	return res
}
	
;----------------------------------------------------------------------------------------------	

~esc::	
	if (Info_visible OR Tooltip_visible OR ISHelp_visible)
		ISense_EResetMode()
return	

up::			
down::
	If (ISHelp_visible)
	{
		ControlSend, ,{%A_ThisHotKey%},	ahk_id %ISHelp_hwnd%
		return
	}

	if (Info_visible)
	{
		Info_send := true
		ControlSend ListBox1,2 {%A_ThisHotkey%}, ahk_id %Info_hwnd%	
		return
	}
		
	send {%A_ThisHotkey%}										  
	if !ISense_sleeping

	ISense_EResetMode()
Return

pgup::
pgdn::
end::
home::
	If (ISHelp_visible)
	{
		ControlSend, ,{%A_ThisHotKey%},	ahk_id %ISHelp_hwnd%
		return
	} 		  

	if (Info_visible)
	{
		Info_send := true
		ControlSend ListBox1, {%A_ThisHotkey%}, ahk_id %Info_hwnd%	
		return	
	}

	Send {%A_ThisHotKey%}	
Return

^enter::
	if !ISHelp_visible
	{
		Send ^{ENTER}
		return
	}

	Tooltip_Close()
	ISHelp_Zoom("in")
return

;----------------------------------------------------------------------------------------------

#include includes\Setup_GUI.ahk
#include includes\ie.ahk
#include includes\aux_.ahk
#include includes\ActiveGoTo.ahk
#include includes\EditorMethods.ahk   ;***

