

;-- ISense_Init section --
; SetBatchLines, -1
  ISense_Opt_TitleWord   = .ahk,.bat,.pl,Internet Explorer
  ISense_Opt_ClearKeys = SPACE,ENTER,NumpadEnter,LButton,RButton

  ISense_ValidateEditorPlugins()  ; Parse through and validate editor plugins
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
  global
  static pEditorNum
  local class,

  WinGetClass, class, %title%
  IfEqual, class,tooltips_class32,return
  
  Editor_Hwnd := Editor_Class := ""
  Editor_Title = %title%

  ;-- if match to editor title -OR- class RE strings..
  If RegExMatch( title, Editor_TitleRE, OnMatch_ ) || RegExMatch( class, Editor_ClassRE, OnMatch_ )  {
    Loop, % Editor_TitleRE_Count
      ; if found editor num doesn't match previous editor..
      If OnMatch_EditorNum%A_Index% && ( A_Index != pEditorNum ) {
        pEditorNum = %A_Index%
        Editor_GetLineMethod  := Editor_aGetLineMethod%A_Index%
        Editor_SendLineMethod := Editor_aSendLineMethod%A_Index%
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
  If Editor_aDefaultLang%pEditorNum%
    ISense_CurrentLang := Editor_aDefaultLang%pEditorNum%
  Else If OnMatch_Ext
    ISense_CurrentLang := OnMatch_Ext
  Else
    ISense_CurrentLang := "(unspecified..)"


  Loop, % Editor_TitleRE_Count  ; global cleanup of RE named param matches..
    OnMatch_EditorNum%A_Index% := ""
   OnMatch_Name := OnMatch_UnSaved := ""
}

;---
; ***
ISense_ValidateEditorPlugins()  {

  local getLineMethod, sendLineMethod, defaultLang, class
;- This section will parse editor plugins, assemble validation RE's, & set editor arrays

  Editor_TitleRE_Count := 4
  Editor_TitleRE := "JU)("
    . "(?P<EditorNum1>(^EditPlus.* - \[(?P<Name>.*(\.(?P<Ext>.*))?)(?P<UnSaved> \*)?(?: R/O)?\]?$))" . "|"  ;EditPlus
    . "(?P<EditorNum2>(^PSPad(?: - \[)?(?P<Name>.*(\.(?P<Ext>.*))?)(?P<UnSaved> \*)?(?: R/O)?\]?$))" . "|"  ;PSPad
    . "(?P<EditorNum3>(^(?P<Name>.*(\.(?P<Ext>.*))?) - Notepad$))"                                          ;Notepad
    . ")"

  Editor_ClassRE := "JU)("
    . "(?P<EditorNum4>(^ConsoleWindowClass$))"   ;cmd prompt
    . ")"

  ; Methods can be generic number (included w/ IS), or custom func name for dymanic call

  ;Method # used to retrieve the current line of text from editor      ;***
  getLineMethod =
    (LTrim Comments
       3             ;EditPlus
       3             ;PSPad
       1             ;Notepad
       MyDosGetLine  ;cmd prompt
    )

  ;Method # used to send the desired cmd/function
  sendLineMethod =
    (LTrim Comments
       1     ;EditPlus
       2     ;PSPad
       1     ;Notepad
       4     ;cmd prompt
    )

  ;Default lang for editor (if any..). Most can be determined from title RE..
  defaultLang =
    (LTrim Comments
       0     ;EditPlus
       0     ;PSPad
       0     ;Notepad
       bat   ;cmd prompt
    )

  ;Create arrays from the above lists
  StringSplit, Editor_aGetLineMethod , getLineMethod , `n
  StringSplit, Editor_aSendLineMethod, sendLineMethod, `n
  StringSplit, Editor_aDefaultLang   , defaultLang   , `n
  
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

