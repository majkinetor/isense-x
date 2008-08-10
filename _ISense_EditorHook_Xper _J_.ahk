

;-- ISense_Init section --
; SetBatchLines, -1
;   ISense_Opt_TitleWord   = .ahk,.bat,.pl,Internet Explorer
  ISense_Opt_TitleWord   = .bat
  ISense_Opt_ClearKeys = SPACE,ENTER,NumpadEnter,LButton,RButton

  If err := ISense_ValidateEditorPlugins()  ; Parse through and validate editor plugins
    MsgBox, 48, Error with editor plugin detected, % err
    
;   ISense_ValidateLangPlugins()  ; Parse through and validate language plugins (not yet..)

  WinGetTitle, title, A
  ISense_ValidateCurrentEditor( title ) ; Set initial values based on current window
  ToolTip()                             ; refresh debugging window

  ; Set event hooks to monitor editor 
  ISense_EnableEditorHook(true)

  ; Set keyboard hooks to monitor typing
  keys := "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,"
        . "1,2,3,4,5,6,7,8,9,0,#,_,BACKSPACE,"
        . ISense_Opt_ClearKeys
  Loop, Parse, keys, `,
    Hotkey, ~*%A_LoopField%, ISense_OnKeyPressDispatch
  Hotkey, ~*`,, ISense_OnKeyPressDispatch
  
  OnExit,  ISense_OnExit
return  ; #### End of auto-execute section  ####
;-------------------------------------------------------------------------

^l::reload
^q::exitapp

ISense_OnExit:
  ISense_EnableEditorHook(false)
ExitApp


;---
ISense_OnKeyPressDispatch:
  IfEqual, Editor_Hwnd,,return
  ISense_HotkeyHandler()
  ToolTip()   ; refresh debugging window
return


ISense_HotkeyHandler()  {
  global ISense_Opt_ClearKeys, ISense_lastWord

  key := SubStr( A_ThisHotkey, 3 )
  
  if key in %ISense_Opt_ClearKeys%
    ISense_lastWord =
  Else If key = BACKSPACE
    ISense_lastWord := SubStr( ISense_lastWord, 1, StrLen( ISense_lastWord ) - 1 )
  Else
    ISense_lastWord .= key
}

;---
ISense_EnableEditorHook( enable="true" )  {
   static hookProcAdr, hHook1, hHook2, hHook3, hHook4
;   (recycled from dock.ahk  :) )

  if (enable && hHook1)
    return true

  if !enable
    API_UnhookWinEvent(hHook1), API_UnhookWinEvent(hHook2), API_UnhookWinEvent(hHook3)
    , DllCall("GlobalFree", "UInt", hookProcAdr)
    , hHook1 := hHook2 := hHook3 := hHook4 := hookProcAdr := ""
  else  {

    if !hookProcAdr
      hookProcAdr := RegisterCallback("ISense_OnEditorChange")

    hHook1 := API_SetWinEventHook(3,3,0,hookProcAdr,0,0,0)			  	  ; EVENT_SYSTEM_FOREGROUND (window changed)
    hHook2 := API_SetWinEventHook(0x8002,0x8003,0,hookProcAdr,0,0,0)	; EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE
    hHook3 := API_SetWinEventHook(0x800C,0x800C,0,hookProcAdr,0,0,0)	; EVENT_OBJECT_NAMECHANGE  (http://www.autohotkey.com/forum/topic19367-64.html)
;     hHook4 := API_SetWinEventHook(0x800B,0x800B,0,hookProcAdr,0,0,0)	; EVENT_OBJECT_LOCATIONCHANGE

    if !(hHook1 && hHook2 && hHook3) {	   ;some of them failed, unregister everything
      API_UnhookWinEvent(hHook1), API_UnhookWinEvent(hHook2), API_UnhookWinEvent(hHook3)
      return false
    }
  }
  return true
}

;---
ISense_OnEditorChange(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime ) {
  global ISense_lastWord, ISense_Group, Editor_Hwnd, Editor_Title
  static lck 

  IfNotEqual, lck,, return  ; if thread is already being handled..
  WinGetTitle, title, A
  If ( title != Editor_Title )  {
    lck = 1
    ISense_ValidateCurrentEditor( title ) 
    ToolTip()   ; refresh debugging window
    lck =
  }
}

;---
ISense_ValidateCurrentEditor( title )  {
;   global
  local class, thisEditor
  static pEditorNum

  WinGetClass, class, %title%
  IfEqual, class,tooltips_class32,return
  
  Editor_Hwnd := Editor_Class := ""
  Editor_Title = %title%

  ;-- if match to editor title -OR- class RE strings..
  If RegExMatch( title, Editor_PluginTitleRE, OnMatch_ ) || RegExMatch( class, Editor_PluginClassRE, OnMatch_ )  {
    Loop, % Editor_Count
      ; if found editor num doesn't match previous editor..
      If OnMatch_EditorNum%A_Index% && ( A_Index != pEditorNum ) {
        pEditorNum = %A_Index%
        thisEditor:= Editor_aPluginName%A_Index%
        %thisEditor%_init()
        ISense_lastWord =
        break
      }
  } 

  ;-- not a detected editor, but reconized title word
  Else If InStr_MatchList( title, ISense_Opt_TitleWord )
    pEditorNum := Editor_GetLineMethod := Editor_SendLineMethod := "?" ; Default methods
    
  ;-- not a known editor & no match in title word
  Else {
    pEditorNum := Editor_GetLineMethod := Editor_SendLineMethod := ISense_CurrentLang := ""
    ISense_lastWord = (not monitoring..)
    return
  }

  Editor_Class = %class%
  WinGet, Editor_Hwnd, ID, %title%

  ; if editor has a default language specified
  If Editor_DefaultLang
    ISense_CurrentLang := Editor_DefaultLang
  Else If OnMatch_Ext
    ISense_CurrentLang := OnMatch_Ext
  Else
    ISense_CurrentLang := "(unspecified..)"


  Loop, % Editor_Count  ; global cleanup of RE named param matches..
    OnMatch_EditorNum%A_Index% := ""
   OnMatch_Name := OnMatch_UnSaved := ""
}

;---
ISense_ValidateEditorPlugins()  {
;- This section will parse editor plugins, assemble validation RE's, & set editor arrays

  local editor_plugins, editor_errorMsg, cnt, titleRE, classRE
; global Editor_Count, Editor_PluginTitleRE, Editor_PluginClassRE, Editor_aPluginName

;   PluginLoader_Init("Editors") , editor_plugins := PluginLoader_Get()
  editor_plugins = CmdPrompt`nEditPlus`nNotepad`nPSPad    ;***
  Loop, Parse, editor_plugins, `n, `r
  {
    If %A_LoopField%_init()  {
      If !(Editor_TitleRE || Editor_ClassRE)
        editor_errorMsg .= A_LoopField "_init(): Neither editor title nor class were specified. Couldn't initialize.`n"

      Else If !Editor_SendLineMethod
        editor_errorMsg .= A_LoopField "_init(): Editor_SendLineMethod = ''. Must specify value.`n"

      Else If !Editor_GetLineMethod
        editor_errorMsg .= A_LoopField "_init(): Editor_GetLineMethod = ''. Must specify value.`n"

      Else  {
        cnt++
        Editor_aPluginName%cnt% := A_LoopField
        
        If Editor_TitleRE
          titleRE ? (titleRE.="|(?P<EditorNum" cnt ">" Editor_TitleRE ")")
                  : (titleRE:="(?P<EditorNum" cnt ">" Editor_TitleRE ")")
             
        If Editor_ClassRE
          classRE ? (classRE.="|(?P<EditorNum" cnt ">" Editor_ClassRE ")")
                  : (classRE:="(?P<EditorNum" cnt ">" Editor_ClassRE ")")
                  
        Editor_Count := cnt
      }
      Editor_PluginTitleRE := "JU)(" titleRE ")", Editor_PluginClassRE := "JU)(" classRE ")"
    }
    Else
      editor_errorMsg .= """" A_LoopField "_init()"" doesn't exist. Couldn't initialize.`n"

    Editor_TitleRE := Editor_ClassRE := Editor_GetLineMethod := Editor_SendLineMethod :=
    Editor_DefaultLang := Editor_GotoShortCut := ""
  }
  return editor_errorMsg
}



;---
API_SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags) {
   DllCall("CoInitialize", "uint", 0)
   return DllCall("SetWinEventHook", "uint", eventMin, "uint", eventMax, "uint", hmodWinEventProc, "uint", lpfnWinEventProc, "uint", idProcess, "uint", idThread, "uint", dwFlags)
}

API_UnhookWinEvent( hWinEventHook ) {
   return DllCall("UnhookWinEvent", "uint", hWinEventHook)
}

;---
InStr_MatchList( var, matchlist, delim="," )  {
  Loop, Parse, matchlist, %delim%, %A_Space%%A_Tab%
    If InStr( var, A_LoopField )
      return true
}

;---
ToolTip()  {
  global
  static count
  count++
  CoordMode, ToolTip, Screen
  tooltip, % "Editor_Hwnd = "    . Editor_Hwnd  . "`t`t"
           . "Editor_Title = "    . Editor_Title  . "`n"
           . "Editor_GetLineMethod = " . Editor_GetLineMethod  . "`t`t"
           . "Editor_SendLineMethod = " . Editor_SendLineMethod  . "`n"
           . "Editor_Class = " . Editor_Class  . "`n"
           . "-----" . "`n"
           . "ISense_CurrentLang = " . ISense_CurrentLang  . "`n"
           . "ISense_lastWord = " . ISense_lastWord . "`n"
           . , 5, 5
}


;/// Includes / Plugins ///

;==================== START: #Include Editors\CmdPrompt.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

CmdPrompt_Init()  {
  global

  ; RegEx for window title and/or class of editor
  Editor_TitleRE        =
  Editor_ClassRE       := "(^ConsoleWindowClass$)"

  ; Method # used to retrieve the current line of text from editor
  Editor_GetLineMethod  = MyDosGetLine

  ; Method # used to send the desired cmd/function
  Editor_SendLineMethod = 4

  ; Default lang for editor (if any..). Most can be determined from title RE..
  Editor_DefaultLang    = bat

  ; ShortCut for GoTo in Editor (assumes Ctrl+g if unspecified
  Editor_GotoShortCut   =

  return true
}

;==================== END: #Include Editors\CmdPrompt.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Editors\EditPlus.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

EditPlus_Init()  {
  global

  ; RegEx for window title and/or class of editor
  Editor_TitleRE       := "(^EditPlus.* - \[(?P<Name>.*(\.(?P<Ext>.*))?)(?P<UnSaved> \*)?(?: R/O)?\]?$)"
  Editor_ClassRE        =

  ; Method # used to retrieve the current line of text from editor
  Editor_GetLineMethod  = 3

  ; Method # used to send the desired cmd/function
  Editor_SendLineMethod = 1

  ; Default lang for editor (if any..). Most can be determined from title RE
  Editor_DefaultLang    =

  ; ShortCut for GoTo in Editor (assumes Ctrl+g if unspecified
  Editor_GotoShortCut   =

  return true
}


;==================== END: #Include Editors\EditPlus.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Editors\Notepad.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

Notepad_Init()  {
  global

  ; RegEx for window title and/or class of editor
  Editor_TitleRE       := "(^(?P<Name>.*(\.(?P<Ext>.*))?) - Notepad$)"
  Editor_ClassRE        =

  ; Method # used to retrieve the current line of text from editor
  Editor_GetLineMethod  = notepad_get

  ; Method # used to send the desired cmd/function
  Editor_SendLineMethod = 1

  ; Default lang for editor (if any..). Most can be determined from title RE..
  Editor_DefaultLang    =

  ; ShortCut for GoTo in Editor (assumes Ctrl+g if unspecified
  Editor_GotoShortCut   =

  return true
}

;==================== END: #Include Editors\Notepad.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Editors\PSPad.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

PSPad_Init()  {
  global

  ; RegEx for window title and/or class of editor
  Editor_TitleRE       := "(^PSPad(?: - \[)?(?P<Name>.*(\.(?P<Ext>.*))?)(?P<UnSaved> \*)?(?: R/O)?\]?$)"
  Editor_ClassRE        =

  ; Method # used to retrieve the current line of text from editor
  Editor_GetLineMethod  = 3

  ; Method # used to send the desired cmd/function
  Editor_SendLineMethod = pspad_send

  ; Default lang for editor (if any..). Most can be determined from title RE..
  Editor_DefaultLang    =

  ; ShortCut for GoTo in Editor (assumes Ctrl+g if unspecified
  Editor_GotoShortCut   =

  return true
}

;==================== END: #Include Editors\PSPad.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


;==================== START: #Include Includes\PluginLoader.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3
; Title:		PluginLoader
;				*Plugin framework for non-compiled scripts*

/*
  Function:		Init
				Must be called at te start of the script. Will check for new plugins.
				All .ahk files in the "plugins" folder will be considered as plugins.
				To install plugin simply move ahk script in plugin folder and restart
				the host script.

  Parameters:
				pPluginsFolder	- Relative path to the folder where plugins are located.
								Don't specify full path here. The path must be relative to the A_ScriptDir.
								By default, its "plugins".
 */
PluginLoader_Init( pPluginsFolder = "plugins" ) {
	local lastParam
	lastParam := %0%
	ifEqual, lastParam, Plugin_Reload, return
	PluginLoader_makeList( pPluginsFolder )
}

/*
 Function:		Get
				Creates array with the names of all loaded plugins

 Parameters:
				out	- String holding variable name which will be the base for the array. 
					  If empty, array will not be created and function will return list of loaded plugins.

 Returns:		
				If out is not empty, number of plugins. This info will also be available as array element with index zero.
				If out is empty string with list of plugins, each on new line
 */
PluginLoader_Get( out="" ){
	local code, res

  	FileRead code, %A_ScriptDir%\PluginList
	StringReplace code, code, %A_ScriptDir%\

	loop, parse, code,`n,`r 
		if out != 
			 %out%%A_Index% := SubStr(A_LoopField,InStr(A_LoopField, "\", 0,0)+1, -4), %out%0 := A_Index
		else res .= SubStr(A_LoopField,InStr(A_LoopField, "\", 0,0)+1, -4) "`n"

	return (out = "") ? SubStr(res, 1, -1) : %out%0
}

PluginLoader_makeList( pPluginsFolder ) {
	local code, old, param

	loop, %pPluginsFolder%\*.ahk,    
		code .= "#include *i " A_ScriptDir "\" pPluginsFolder "\" A_LoopFileName "`r`n"
	StringTrimRight,code,code,2

	FileRead old, %A_ScriptDir%\PluginList
	ifEqual, old, %code%, return

	FileDelete, %A_ScriptDir%\PluginList
	FileAppend, %code%, %A_ScriptDir%\PluginList
	FileSetAttrib, +H, %A_ScriptDir%\PluginList

	;re-run the host, with the same command line, add the flag as last parameter
	loop, %0%
		if InStr(%A_Index%, A_Space)
			 param .= """" %A_Index% """" " "
		else param .= %A_Index% " "
	param .= "Plugin_Reload"
		
	Run "%A_AHKPATH%" "%A_ScriptFullPath%" %param%
	ExitApp
}

;==================== START: #include *i %A_ScriptDir%\PluginList :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== END: #include *i %A_ScriptDir%\PluginList :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


/*
 Group: Remarks
:
	PluginLoader provides methods to automatically include ahk scripts from given folder. 
	Those scripts are called "plugins" as they can be plug in by simply coping them
	into the plugins folder and restarting the host script. To disable plugin, move it out of folder
	or change it's extension.
:
	PluginLoader does its job by maintaining list of plugins to be included in the hidden file in the 
	%A_ScriptDir%\PluginList. When the host script starts, if new plugins are detected in the plugins folder
	it restarts the script with modified PluginList include. If no new plugins are detected, the host script will not be
	interrupted in any way.
:
	Its up to the host script to create plugin SDK, for instance, via dynamic function or subroutine calls.
 */

/*
 Group: About
	o Ver 1.1 by majkinetor. See http://www.autohotkey.com/forum/topic22029.html
	o Licenced under GNU GPL <http://creativecommons.org/licenses/GPL/2.0/>.
*/
;==================== END: #Include Includes\PluginLoader.ahk :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


