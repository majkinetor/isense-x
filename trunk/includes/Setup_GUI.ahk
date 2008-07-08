
ISSetup_Create()
{
	global
	
	if (ISSetup_visible)
	{	
		WinActivate ahk_id %ISSetup_hwnd%
		return
	}

	ISSetup_visible := true
	Gui, %ISSetup_Gui%: +labelISSetup_ Toolwindow
	Gui, %ISSetup_Gui%:Font, normal s10

;mother tab
	Gui, %ISSetup_GUI%:Add, Tab,		X0 Y-30 h460 w400 +0x100 +0x400 vISSetup_tab, Main|Options|Help
	
;colors
	Gui, %ISSetup_Gui%:Add, GroupBox,	x16  y0  w270 h130 section												,
	Gui, %ISSetup_Gui%:Add, Text,		xs+16 ys+20																, Monitor applications witch title contains:
	Gui, %ISSetup_Gui%:Add, Edit,		xs+16 ys+40 w240 vISSetup_titleWord										, .ahk
	Gui, %ISSetup_Gui%:Add, Text,		xs+16  ys+70 w170														, Display Info window after 
	Gui, %ISSetup_Gui%:Add, Edit,		xs+170 ys+68 w20 h20 vISSetup_minLen									, 3
	Gui, %ISSetup_Gui%:Add, Text,		xs+195 ys+70															, letters

	Gui, %ISSetup_Gui%:Add, CheckBox,	xs+16 ys+105 w200	vISSetup_alwaysShow									, Show full help with the tooltip


;hotkies
	Gui, %ISSetup_Gui%:Add, GroupBox,	x16  y144  w270 h70  section											,

	Gui, %ISSetup_Gui%:Add, Text,		xs+20 ys+17 w100 h23  center											, Hotkey
	Gui, %ISSetup_Gui%:Add, Hotkey,		xs+20 ys+37 w100 h23  vISSetup_hotkey									, ^SPACE

	Gui, %ISSetup_Gui%:Add, Text,		xs+150 ys+17 w100 h22 center											, ON/OFF
	Gui, %ISSetup_Gui%:Add, Hotkey,		xs+150 ys+37 w100 h22 vISSetup_onOffKey									, !e


;editors & methods
	Gui, %ISSetup_Gui%:Add, GroupBox,	x16  y230  w270 h80  section											,
	
	;*** Disabled (for now..)
	Gui, %ISSetup_Gui%:Add, Text,		xs+20 ys+17 w240  h30 DISABLED 											        ,         Editor               or             Method
	Gui, %ISSetup_Gui%:Add, Combobox,	xs+16 ys+40 w100  h15 +0x100 vISSetup_editor gISSetup_OnEditorSel	DISABLED	,
	Gui, %ISSetup_Gui%:Add, Combobox,	xs+150 ys+40 w100 h15 +0x100 vISSetup_method gISSetup_OnMethodSel	DISABLED	,


;appeareance tab
	Gui, %ISSetup_Gui%:Tab, 2

  ;tooltip
  	Gui, %ISSetup_Gui%:Add, GroupBox,	x16  y5  w270 h90		section											, Tooltip

	Gui, %ISSetup_Gui%:Add, Text,		xs+16   ys+30  w80  h20													, Background
	Gui, %ISSetup_Gui%:Add, Text,		xs+16   ys+50  w80  h20	border 	vISSetup_bg g_ISSetup_OnTxtClick		,  ggggggggggggggg

	Gui, %ISSetup_Gui%:Add, Text,		xs+114 ys+30  w80  h20													, Foreground
	Gui, %ISSetup_Gui%:Add, Text,		xs+114 ys+50  w80  h20	border 	vISSetup_fg g_ISSetup_OnTxtClick		,  ggggggggggggggg

	Gui, %ISSetup_Gui%:Add, Text,		xs+220  ys+30															, Alpha
	Gui, %ISSetup_Gui%:Add, Edit,		xs+222  ys+50 w30  h20	center	vISSetup_transTooltip					, 


 ;help
	Gui, %ISSetup_Gui%:Add, GroupBox,	x16		y110  w270 h90  section											, Help

	Gui, %ISSetup_Gui%:Add, Text,		xs+20	ys+30		   													, Width
	Gui, %ISSetup_Gui%:Add, Edit,		xs+20	ys+50 w30  h20	center	vISSetup_width							, 

	Gui, %ISSetup_Gui%:Add, Text,		xs+65	ys+30   														, Height
	Gui, %ISSetup_Gui%:Add, Edit,		xs+70	ys+50 w30  h20	center	vISSetup_height							, 

	Gui, %ISSetup_Gui%:Add, Text,		xs+150	ys+30															, Font Size
	Gui, %ISSetup_Gui%:Add, Edit,		xs+165	ys+50 w20  h20	center	vISSetup_fontSize						, 

	Gui, %ISSetup_Gui%:Add, Text,		xs+220	ys+30   														, Alpha
	Gui, %ISSetup_Gui%:Add, Edit,		xs+222	ys+50 w30  h20	center	vISSetup_transHelp						, 



;help tab
	Gui, %ISSetup_Gui%:Tab, 3
	Gui, %ISSetup_Gui%:Font, s10
	Gui, %ISSetup_Gui%:Add, Button,		x0 y0 w0 h0 															, 
	Gui, %ISSetup_Gui%:Add, Edit,		x0 y0 w305 h360 readonly 0x4000 vISSetup_help disabled -wrap -vscroll   ,


;common controls
	Gui, %ISSetup_Gui%:Tab

	Gui, %ISSetup_Gui%:Add, GroupBox,	x16		y350  w0 h0  section											,
	Gui, %ISSetup_Gui%:Add, Button,		xs		ys+15 w110 h22 0x8000 gISSetup_OnSaveClickDispatch				, &Save
	Gui, %ISSetup_Gui%:Add, Picture,	xs+215	ys+15  0x8000 gISSetup_OnMain									, res\main.ico
	Gui, %ISSetup_Gui%:Add, Picture,	xs+250	ys+15  0x8000 gISSetup_OnOptions								, res\options.ico
	Gui, %ISSetup_Gui%:Add, Picture,	xs+270	ys-340 0x8000 g_ISSetup_OnHelp									, res\help.ico



; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	Gui, %ISSetup_GUI%: +LastFound
	ISSetup_hwnd := WinExist() + 0

	ISSetup_OnShow()
	Gui, %ISSetup_GUI%:Show,			x396 y253 w305 h400 													, ISense Setup
}

;----------------------------------------------------------------------------------------------
ISSetup_OnShow()
{
	local sMethods, sEditors, iniEditors

	;set colors
	Gui, %ISSetup_Gui%:Font, c%Tooltip_colorBG% s32 bold, Webdings
	GuiControl,%ISSetup_Gui%:Font, ISSetup_bg

	Gui, %ISSetup_Gui%:Font, c%Tooltip_colorFG% s32 bold, Webdings
	GuiControl,%ISSetup_Gui%:Font, ISSetup_fg

	ISSetup_colorBG := Tooltip_colorBG,   ISSetup_colorFG := Tooltip_colorFG


	;set other data
	GuiControl,%ISSetup_Gui%:, ISSetup_alwaysShow,	%ISHelp_alwaysShow%
	GuiControl,%ISSetup_GUI%:, ISSetup_onOffKey,	%ISense_onOffKey%
	GuiControl,%ISSetup_GUI%:, ISSetup_hotkey,		%ISense_hotkey%

	GuiControl,%ISSetup_GUI%:, ISSetup_transTooltip,%Tooltip_trans%
	GuiControl,%ISSetup_GUI%:, ISSetup_transHelp,	%ISHelp_trans%

	GuiControl,%ISSetup_Gui%:, ISSetup_titleWord,	%ISense_Opt_TitleWord%
	GuiControl,%ISSetup_Gui%:, ISSetup_minLen,		%ISense_Opt_MinLen%

	GuiControl,%ISSetup_Gui%:, ISSetup_width,		%ISHelp_width%
	GuiControl,%ISSetup_Gui%:, ISSetup_height,		%ISHelp_height%
	GuiControl,%ISSetup_Gui%:, ISSetup_fontSize,	%ISHelp_fontSize%


	;add editor specific options
	Loop,  includes\editors\*.ahk
	{
		sMethods .= SubStr(A_LoopFileName, 1, -4) . "|"

		IniRead, iniEditors, %A_LoopFileFullPath%, Editor, Editors
		StringTrimRight, iniEditors, iniEditors, 1
		StringReplace, iniEditors, iniEditors, `, , |, A
		sEditors .= iniEditors
	}

	GuiControl, %ISSetup_GUI%:, ISSetup_method,  %sMethods%
	GuiControl, %ISSetup_GUI%:, ISSetup_editor,  %sEditors%
	
	;show current editor selection
	IniRead,  s1, Config.ini, ISense, editor, Method 1
	if InStr(s1, "Method") > 0
			GuiControl, %ISSetup_GUI%:ChooseString, ISSetup_method,  %s1%
	else 	GuiControl, %ISSetup_GUI%:ChooseString, ISSetup_editor,  %s1%


	GuiControl, %ISSetup_GUI%:ChooseString, ISSetup_tab, %ISSetup_lastTab%
}

;----------------------------------------------------------------------------------------------

ISSetup_OnHelp() {
	global
	static prevTab

	GuiControlGet, currentTab,, ISSetup_tab
	GuiControl, ,ISSetup_help, % SetHelpText( currentTab )

	if ( currentTab != "Help") 
		GuiControl, %ISSetup_GUI%:ChooseString, ISSetup_tab, Help
	else 									
		GuiControl, %ISSetup_GUI%:ChooseString, ISSetup_tab, %prevTab%

	prevTab := currentTab
}

_ISSetup_OnHelp:
	ISSetup_OnHelp()
return

ISSetup_OnMain:
	GuiControl, %ISSetup_GUI%:ChooseString, ISSetup_tab, Main
return

ISSetup_OnOptions:
	GuiControl, %ISSetup_GUI%:ChooseString, ISSetup_tab, Options
return


;----------------------------------------------------------------------------------------------

ISSetup_OnEditorSel:
	ISSetup_editorChanged := true
  	ControlSetText, Edit4,
return

ISSetup_OnMethodSel:
	ISSetup_editorChanged := true
	ControlSetText, Edit3,
return

;----------------------------------------------------------------------------------------------

ISSetup_OnTxtClick( ){
	local res

	res :=	A_GuiControl = "ISSetup_bg" ? ISSetup_colorBG : ISSetup_colorFG
	res := ISSetup_ChooseColor( res, ISSetup_hwnd)
	if res = -1
		return

	Gui, %ISSetup_Gui%:Font, c%res% s10 bold
	GuiControl, Font, %A_GuiControl%
	
	if (A_GuiControl = "ISSetup_bg")
			ISSetup_colorBG := res
	else	ISSetup_colorFG := res
}

_ISSetup_OnTxtClick:
	ISSetup_OnTxtClick()
Return, 


;----------------------------------------------------------------------------------------------
ISSetup_Close:
	GuiControlGet, ISSetup_lastTab,, ISSetup_tab
	if 	ISSetup_lastTab = Help
		ISSetup_lastTab = Main

	Gui, %ISSetup_Gui%:Destroy
	ISSetup_Visible := false
return

ISSetup_Escape:
	goto ISSetup_Close
return

;----------------------------------------------------------------------------------------------
ISSetup_OnSaveClick()
{
	global
	local iniEditors, txt

	Gui %ISSetup_Gui%:Submit


	IniWrite, %ISSetup_colorBG%, Config.ini, Tooltip, ColorBG
	IniWrite, %ISSetup_colorFG%, Config.ini, Tooltip, ColorFG

	IniWrite, %ISSetup_hotkey%,			Config.ini, ISense,		hotkey
	IniWrite, %ISSetup_onOffKey%,		Config.ini, ISense,		onOffKey

	IniWrite, %ISSetup_alwaysShow%,		Config.ini, Help,		alwaysShow

	IniWrite, %ISSetup_transTooltip%,	Config.ini, ToolTip,	trans
	IniWrite, %ISSetup_transHelp%,		Config.ini, Help,		trans
	

; 	Hotkey, %ISense_Hotkey%, off   ;***
; 	Hotkey, %ISense_onOffKey%, off

	Hotkey, %ISense_Hotkey%,	ISense_HotkeyHandlerDispatch,   On UseErrorLevel
	Hotkey, %ISense_onOffKey%,	ISense_OnOffKeyHandler, On UseErrorLevel

 	IniWrite, %ISSetup_titleWord%,	Config.ini, ISense,	TitleWord
 	IniWrite, %ISSetup_minLen%,		Config.ini, ISense,	MinLen

 	IniWrite, %ISSetup_width%,		Config.ini,  Help,	width
 	IniWrite, %ISSetup_height%,		Config.ini,  Help,	height
 	IniWrite, %ISSetup_fontSize%,	Config.ini,  Help,	fontSize

/*    *** removed for now
	;editor
	if 	(ISSetup_editorChanged)
	{
		ControlGetText, txt, Edit3

		if txt !=				
		{
			IniWrite, %ISSetup_editor%,	Config.ini, ISense,	editor
			
			Loop,  includes\editors\*.ahk
			{
				IniRead, iniEditors, %A_LoopFileFullPath%, Editor, Editors
				If InStr(iniEditors, "," ISSetup_editor ",") {
					FileCopy, %A_LoopFileFullPath%, includes\Method.ahk, 1
					break
				}
			}
		}				 		
		else {
			IniWrite, %ISSetup_method%,	Config.ini, ISense,	editor
			FileCopy, includes\editors\%ISSetup_method%.ahk, includes\Method.ahk, 1
		}

		Reload
	}
*/

	;- - - - - - - - - - - - - 

	ISense_SetHotkies("off")
	ISense_GetConfig()
	ISense_SetHotkies("on")

	Gui, %ISHelp_Gui%:Show, x-10000 y-10000 NoActivate
	ISHelp_SetFontSize( ISHelp_fontSize )
	ISHELP_SetWindow( true )
	ISHelp_Hide()

	Gosub ISSetup_Close
}


ISSetup_OnSaveClickDispatch:
	ISSetup_OnSaveClick()
return


;----------------------------------------------------------------------------------------------
;   PURPOSE:  Encapsulation of Windows color dialog 
;   ARGS:       1-Default color in RGB format, 2-Parents ID (HWND) 
;   USING:      InsertInteger, ExtractInteger 
;   RETURNS:    -1 on cancel, RGB value on OK 
; 
;   By majkinetor 
ISSetup_ChooseColor(pDefColor = 0x0 , pParentHandle=0)
{ 

    _rgb := pDefColor 
    pDefColor := ((_rgb & 0xFF) << 16) + (_rgb & 0xFF00) + ((_rgb >> 16) & 0xFF) 

    VarSetCapacity(sCHOOSECOLOR, 0x24, 0) 
    VarSetCapacity(aChooseColor, 64, 0) 

    ISense_InsertInteger(0x24,     sCHOOSECOLOR, 0)            ; DWORD lStructSize 
    ISense_InsertInteger(pParentHandle,  sCHOOSECOLOR, 4)      ; HWND hwndOwner (makes dialog "modal"). 
    ISense_InsertInteger(pDefColor, sCHOOSECOLOR, 12)          ; clr.rgbResult 
    ISense_InsertInteger(&aChooseColor , sCHOOSECOLOR, 16)     ; COLORREF *lpCustColors 
    ISense_InsertInteger(0x00000103, sCHOOSECOLOR, 20)         ; Flag: CC_ANYCOLOR || CC_RGBINIT 

    nRC := DllCall("comdlg32\ChooseColorA", str, sCHOOSECOLOR)  ; Display the dialog. 
    if (errorlevel <> 0) || (nRC = 0) 
       return  -1 

  
    res := ISense_ExtractInteger(sCHOOSECOLOR, 12) 
    
    oldFormat := A_FormatInteger 
    SetFormat, integer, hex  ; Show RGB color extracted below in hex format. 

;convert to rgb 
    rgbRes := (res & 0xff00) 
    rgbRes += ((res & 0xff0000) >> 16) 
    rgbRes += ((res & 0xff) << 16) 
    StringTrimLeft, rgbRes, rgbRes, 2 
    loop, % 6-strlen(rgbRes) 
      rgbRes=0%rgbRes% 
    rgbRes=0x%rgbRes% 
    SetFormat, integer, %oldFormat% 
    return rgbRes 
}

;----------------------------------------------------------------------------------------------
SetHelpText( page ) {
	global
	
	if (page = "Main")
		help = 
(
				
 - ISense will work only in windows witch title
   contains specified word (anywhere inside it)

 - Info window appears after typing specified 
   number of charachters while ISense monitors
   input.

 - If you want full help to be shown along with 
   the tooltip, check this option. Otherwise, you 
   have to press the hotkey again to show full help.

 - Find your editor in the list, or, if not there, 
   try with some of the offered methods. If you 
   don't know what to choose the best bet is 
   "General" editor.

   If you still have a problem, you will probably 
   have to write "method" for your own editor
   See readme.txt for details on how to do that.

)

	if (page = "Options")
		help= 
( 

 - Click on the color to change it.	

 - Set transparency of tooltip and help window
   255 = no transparency , 0 = full transparency.

 - Set the width & height of the help window

 - Set the default font size. You can change it 
   while help is active via CTRL Wheel up/down

)
 
 return help
}
