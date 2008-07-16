/*
*****************************************************************************************************
					ISENSE EDITOR SPECIFIC METHODS (called dynamically)
******************************************************************************************************
*/


;------------------
/*
GetLineMethod1:  Least pervasive method. Used for editors where ControlGet cmd can retrieve

  Editors:  Notepad
*/

ISense_GetLineMethod1()
{
	ControlGet, curCol, CurrentCol
	ControlGet, curLine, CurrentLine
	ControlGet, line, Line, %curLine%

	StringMid, line, line, 1, % curCol - 1

	;return the line
	Return line
}

;------------------
/*
GetLineMethod2:  Used for editors where selected txt can be retrieved by highlighting & ControlGet

  Editors:  SciTE, Notepad++, EmEditor, Programers Notepad
*/

ISense_GetLineMethod2()
{
	;select up to the beginning
	x := A_CaretX
	Send +{home}
	Sleep 20

	;get selection
	ControlGetFocus, line, A
	ControlGet, line, Selected, ,%line%, A
	Sleep 20

	;cancel selection
	Send {RIGHT}
	Sleep 20

	;return the line
	Return line
}

;------------------
/*
GetLineMethod3:  Temporarily uses windows clipboard to retrieve text.
                 Used for editors that '{right}' returns your position to right side of selected text.

  Editors:  PSPad, Notepad2, Crimson, Metapad, EditPlus, TextPad
*/

ISense_GetLineMethod3()
{
	;select up to the beginning
; 	x := A_CaretX
	Send +{home}
	Sleep 20

	;get selection
	oldClip := clipboardall
	Send,  +{HOME}
	Send,  ^c
	Sleep, 50
	line := clipboard
	clipboard := oldClip

	;cancel selection
	Send {RIGHT}
	Sleep 20

	;return the line
	Return line
}

;------------------
/*
GetLineMethod4:  Temporarily uses windows clipboard to retrieve text.   (default method if editor isn't reconized..)
                 Similar to GetLineMethod3- but uses ^z (undo) cmd to returns your position to right side of selected text.
                 
  Editors:  ConTEXT, UltraEdit-32, SynPlus, Syn
*/

ISense_GetLineMethod4()
{
	Send, %A_Space%

	oldClip := clipboardall
	Send,  +{HOME}
	Send,  ^c
	Sleep, 50
	line := clipboard
	clipboard := oldClip

	Send, ^z
	Sleep, 50
	StringTrimRight, line, line, 1
	
	;return the line
	Return line
}


;///////////////////////////////////////////////////////////////////////////////////////////
/*
SendSelectionMethod1:  Used for most editors.  (default method if editor isn't reconized..)

  Editors:  SciTE, Notepad++, Notepad2, ConTEXT, UltraEdit-32, EditPlus, Notepad
          , EmEditor, SynPlus, Syn, Crimson, Metapad, Programers Notepad, TextPad
*/

ISense_SendSelectionMethod1( Selection, Type )
{
  ;type the desired word
  If (Type = "[]")                                                ; Send function
    SendInput, % Selection . "(  ){left 2}"     
  Else If SubStr( Selection, 1, 1) = "#" || Selection = "return"  ; Send directive
    SendRaw, %Selection%%A_SPACE%
  Else
    SendRaw, %Selection%,%A_SPACE%                                ; Send standard cmnd
}
;------------------
/*
SendSelectionMethod2:  Used for editors that auto-complete '()' (so far.. I've only found PSPad needs this)

  Editors:  PSPad
*/

ISense_SendSelectionMethod2( Selection, Type )
{
	;type the desired word
	If (Type = "[]")                              ; Send function
    SendInput, % Selection . "(  {left}"        
  Else If SubStr( Selection, 1, 1) = "#"        ; Send directive
    SendRaw, %Selection%%A_SPACE%
  Else If (Selection = "return")
    SendRaw, %Selection%%A_SPACE%
	Else
    SendRaw, %Selection%,%A_SPACE%              ; Send standard cmnd
}
