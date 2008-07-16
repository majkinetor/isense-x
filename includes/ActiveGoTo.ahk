/*
--ActiveGoTo--

bookmarklist for ahk scripts in different editors
requires AHK 1.0.46.00
original by Rajat (www.autohotkey.com/forum/topic11998.html)
mod by toralf (AHK syntax RegEx by PhiLho) 
*/

/*
ActiveGoto EDITOR ISSUES:
  Notepad++, SynPlus, Crimson - Cannot track file changes through titlebar (no '*')
                                but dynamic func's are still added to cmnds on
                                windows 1st activation.

  SciTE, Syn, Notepad         - Cannot fully track file changes through titlebar;
                                Doesn't show full path to file.

  Notepad2  - Works only w/ 'Settings -> Window Title Display -> Full PathName' setting.


 ActiveGoto WORKS PERFECT:
    PSPad
    Notepad2
    ConTEXT
    UltraEdit-32
    EditPlus
    EmEditor
    Metapad
    Programers Notepad
    TextPad
*/
;----------------------------------------------------------------------------------------------

ActiveGoTo_Init()  {
  local Hotkeys, GuiGrp
;   global ActiveGoTo_HtkGrp, ActiveGoTo_aEditorTitleRE, 
;     , ActiveGoto_aGotoShortCut, ActiveGoTo_identifierRE, ActiveGoto_parameterListRE, ActiveGoto_lineCommentRE
  

  ;RegEx for window titles of different editors     ***
  ActiveGoTo_aEditorTitleRE =
    (LTrim Comments
      ^PSPad(?: - \[)?(?P<Name>.*?)(?P<UnSaved> \*)?(?: R/O)?\]?$               ;PSPad
      ^(?P<Name>.*?) (?P<UnSaved>[-*]) SciTE$                                   ;SciTE
      ^Notepad\+\+ - (?P<Name>.*?)$                                             ;Notepad++
      ^(?P<UnSaved>\*)? ?(?P<Name>.*?)(?: \(Read only\))? - Notepad2$           ;Notepad2 
      ^ConTEXT(?: - \[)?(?P<Name>.*?)(?P<UnSaved> \*?#?)?(?: \[ReadOnly\])?\]?$ ;ConTEXT
      ^UltraEdit-32(?: - \[)?(?P<Name>.*?)(?P<UnSaved>\*)?(?: R/O)?\]?$         ;UltraEdit
      ^EditPlus.* - \[(?P<Name>.*?)(?P<UnSaved> \*)?(?: R/O)?\]?$            ;EditPlus
      ^(?P<Name>.*) - Notepad$                                                  ;Notepad
      ^(?P<Name>.*?)(?P<UnSaved> \*)? - EmEditor$                               ;EmEditor
      ^SynPlusEditor-\[(?P<Name>.*)\]$                                          ;SynPlus
      ^syn - \[(?P<Name>.*)(?P<UnSaved> \*)\]$                                  ;Syn
      ^Crimson Editor - \[(?P<Name>.*)\]$                                       ;Crimson
      ^(?P<UnSaved> \* )?(?P<Name>.*) - metapad$                                ;Metapad
      ^Programmers Notepad 2 - \[(?P<Name>.*)(?P<UnSaved>\*)?\]$                ;Programers Notepad
      ^TextPad - (?P<Name>.*?)(?P<UnSaved> \*)?(?: R/O)?$                       ;TextPad
    )
;       ^EditPlus(?: - \[)?(?P<Name>.*?)(?P<UnSaved> \*)?(?: R/O)?\]?$            ;EditPlus (original regex)

  ;ShortCut for GoTo in Editor, in case it is different from Ctrl+g
  ActiveGoto_aGotoShortCut =
    (LTrim Comments
       ^g     ;PSPad
       ^g     ;SciTE
       ^g     ;Notepad++
       ^g     ;Notepad2
       ^g     ;ConTEXT
       ^g     ;UltraEdit-32
       ^g     ;EditPlus
       ^g     ;Notepad
       ^g     ;EmEditor
       ^g     ;SynPlus
       ^g     ;Syn
       ^g     ;Crimson
       ^g     ;Metapad
       ^g     ;Programers Notepad
       ^g     ;TextPad
    )

  ;Whether ActiveGoTo should track changes/open InfoGui       
  ActiveGoto_aMonitorDocument =
    (LTrim Comments
       True     ;PSPad
       False    ;SciTE
       False    ;Notepad++
       True     ;Notepad2
       True     ;ConTEXT
       True     ;UltraEdit-32
       True     ;EditPlus
       True     ;Notepad
       True     ;EmEditor
       False    ;SynPlus
       False    ;Syn
       False    ;Crimson
       True     ;Metapad
       True     ;Programers Notepad
       True     ;TextPad
    )

  ;Method # used to retrieve the current line of text from editor      ;***
  Isense_aGetLineMethod =
    (LTrim Comments
       3     ;PSPad
       2     ;SciTE
       2     ;Notepad++
       3     ;Notepad2
       4     ;ConTEXT
       4     ;UltraEdit-32
       3     ;EditPlus
       1     ;Notepad
       2     ;EmEditor
       4     ;SynPlus
       4     ;Syn
       3     ;Crimson
       3     ;Metapad
       2     ;Programers Notepad
       3     ;TextPad
    )

  ;Method # used to send the desired cmd/function                      
  Isense_aSendLineMethod =
    (LTrim Comments
       2     ;PSPad
       1     ;SciTE
       1     ;Notepad++
       1     ;Notepad2
       1     ;ConTEXT
       1     ;UltraEdit-32
       1     ;EditPlus
       1     ;Notepad
       1     ;EmEditor
       1     ;SynPlus
       1     ;Syn
       1     ;Crimson
       1     ;Metapad
       1     ;Programers Notepad
       1     ;TextPad
    )
    
  ;Create arrays from the above lists
  StringSplit, ActiveGoTo_aEditorTitleRE      , ActiveGoTo_aEditorTitleRE      , `n
  StringSplit, ActiveGoto_aGotoShortCut       , ActiveGoto_aGotoShortCut       , `n

  StringSplit, ActiveGoto_aMonitorDocument    , ActiveGoto_aMonitorDocument    , `n       
  StringSplit, Isense_aGetLineMethod          , Isense_aGetLineMethod          , `n       
  StringSplit, Isense_aSendLineMethod         , Isense_aSendLineMethod         , `n       


  ;Regex to get AHK syntax right
  ActiveGoTo_identifierRE    = ][#@$?\w                  ; Legal chars for AHK identifiers (var & func names)
  ActiveGoto_parameterListRE = %ActiveGoTo_identifierRE%,=".\s-  ; Legal chars in func def params
  ActiveGoto_lineCommentRE   = \s*?(?:\s;.*)?$          ; Legal line comment regex for performance

  ;build gui
  RoutineInfoGui_Create()

  ;add HWND of GUI to the groups for context sensitive Hotkeys
  GroupAdd, GuiGrp, ahk_id %ActiveGoTo_HWND%
  GroupAdd, ActiveGoTo_HtkGrp, ahk_id %ActiveGoTo_HWND%

  ;activate hotkeys for editors and gui
  Hotkey, IfWinActive, ahk_group ActiveGoTo_HtkGrp
  Hotkey, F2, ActiveGoTo_HotkeyDispatch   ; HK_LastSection = F2
  Hotkey, F1, ActiveGoTo_HotkeyDispatch, Off  ; HK_ShowGUI= F1
  Hotkey, IfWinActive

  ;context menu
  Menu, Context, Add, Frame             , ActiveGoTo_MenuDispatch
  Menu, Context, Add, Slide             , ActiveGoTo_MenuDispatch
  Menu, Context, Add, Slide Left        , ActiveGoTo_MenuDispatch
  Menu, Context, Add, Adjust Height     , ActiveGoTo_MenuDispatch
  Menu, Context, Add, Hide On Lost Focus, ActiveGoTo_MenuDispatch

  ;check for open editors
  ActiveGoTo_EditorTypeCheck()

  ;check for newly opened editors every 2 seconds
  SetTimer, ActiveGoTo_EditorTypeTimer, 2000

  ;check editor window title for change
  SetTimer, ActiveGoTo_EditorTitleTimer, 500

  ;set defaults by calling once with inverse value
  ActiveGoTo_ToggleFrame     := !ReadIni("ToggleFrame"    , 0)
  ActiveGoTo_ToggleLeft      := !ReadIni("ToggleLeft"     , 1)
  ActiveGoTo_Slide           := !ReadIni("Slide"          , 1)
  ActiveGoTo_AdjustHeight    := !ReadIni("AdjustHeight"   , 1)
  ActiveGoTo_HideOnLostFocus := !ReadIni("HideOnLostFocus", 1)

  ActiveGoTo_MenuHandler( "Frame" )              ;ToggleFrame
  ActiveGoTo_MenuHandler( "Slide Left" )         ;ToggleLeft
  ActiveGoTo_MenuHandler( "Slide" )              ;Slide
  ActiveGoTo_MenuHandler( "Adjust Height" )      ;AdjustHeight
  ActiveGoTo_MenuHandler( "Hide On Lost Focus" ) ;HideOnLostFocus

  ;activate hotkeys for gui
  Hotkeys = Up|Down|PgUp|PgDn|WheelUp|WheelDown|MButton|^BackSpace
  Hotkey, IfWinActive, ahk_group GuiGrp

  Loop, Parse, Hotkeys, |
     Hotkey, %A_LoopField%, ActiveGoTo_HotkeyDispatch

  Hotkey, IfWinActive
}
;----------------------------------------------------------------------------------------------

RoutineInfoGui_Create() {
  Global ActiveGoTo_GUI, ActiveGoTo_HWND, MaxVisibleListViewRows, Search, TxtOffset
        , Offset, SubFunc, Limit, SelItem
  ; SubVersion Keywords, also available: LastChangedBy, HeadURL
  RegExMatch("$LastChangedRevision: 12 $"
           . "$LastChangedDate: 2006-12-07 23:01:24 +0100 (Do, 07 Dez 2006) $"
           , "(?P<Num>\d+).*?(?P<Date>(?:\d+-?){3})", SVN_Rev)

  ;MaxVisible Rows of Listview
  MaxVisibleListViewRows := A_ScreenHeight // 16

  ;build gui
  Gui, %ActiveGoTo_GUI%:+LabelRoutineInfoGui_
  Gui, %ActiveGoTo_GUI%:+AlwaysOnTop +ToolWindow -Caption +Border +Resize
  Gui, %ActiveGoTo_GUI%:Margin, 2, 2
  Gui, %ActiveGoTo_GUI%:Add , Edit    , Section w130 r1 vSearch gRoutineInfoGui_Search ,
  Gui, %ActiveGoTo_GUI%:Add , Text    , ys+3 r1 vTxtOffset                             ,Offset
  Gui, %ActiveGoTo_GUI%:Add , Edit    , ys w35 r1 Right Number Limit4 gRoutineInfoGui_FillList vOffset,
  Gui, %ActiveGoTo_GUI%:Add , CheckBox, xs Section gRoutineInfoGui_FillList vSubFunc Check3           , Only Sub/Func
  Gui, %ActiveGoTo_GUI%:Add , CheckBox, ys gRoutineInfoGui_FillList vLimit                            , Filter
  Gui, %ActiveGoTo_GUI%:Add , ListView, xs w200 r%MaxVisibleListViewRows% Count200 vSelItem gRoutineInfoGui_LSelect,Line|Label
  LV_ModifyCol(1, "Integer")
  Gui, %ActiveGoTo_GUI%:Add , Button  , x-10 y-10 w1 h1 gRoutineInfoGui_Select Default,
  Gui, %ActiveGoTo_GUI%:Show, x0 Hide , Active GoTo r%SVN_RevNum%

  Gui, %ActiveGoTo_GUI%:+LastFound
  ActiveGoTo_HWND := WinExist()           ;--get handle to this gui..

  ;apply previous position and size
  IniRead, Pos, Config.ini, ActiveGoTo, Pos, x0
  IniRead, Size, Config.ini, ActiveGoTo, Size,
  Gui, %ActiveGoTo_GUI%:Show, %Pos% %Size% Hide

;   WinWaitClose, ahk_id %ActiveGoTo_HWND%  ;--waiting for gui to close (modal simulation..)
;   return ReturnCode                       ;--returning value
return
}   ;//// End Of RoutineInfoGui ////
;----------------------------------------------------------------------------------------------

RoutineInfoGui_Show() {   ;show/hide gui with slide on hotkey press
global

  If GuiVisible || !ActiveGoto_MonitorDoc {  ;hotkey got pressed with visible window, hide it
      Gosub, RoutineInfoGui_Escape
      Return
    }

  GuiControl, %ActiveGoTo_GUI%:Focus, Search      ;focus search field
  DllCall( "AnimateWindow", "Int", ActiveGoTo_HWND, "Int", 200, "Int", AniShow )
  WinActivate, ahk_id %ActiveGoTo_HWND%
  GuiVisible := True
  Send, ^a                       ;select search string
  Return
}
;----------------------------------------------------------------------------------------------

RoutineInfoGui_FillList:                    ; Fill listview from BM array
  SetBatchLines, -1
  Gui, %ActiveGoTo_GUI%:Default
  Gui, %ActiveGoTo_GUI%:Submit, NoHide
  LV_Delete()                                  ;remove old content
  GuiControl, %ActiveGoTo_GUI%:-Redraw, SelItem
  
  If ( (Search AND !Limit AND !SubFunc)        ;show full list for search
         OR (!Search AND !SubFunc) ){          ;show full list
      Loop, %id%
          If (Position%A_Index% > Offset)
              LV_Add("", Position%A_Index%,Text%A_Index%)
  }Else If (Search AND Limit AND !SubFunc){    ;show limited list for search
      Loop, %id%
          If InStr(Text%A_Index%, Search)
              If (Position%A_Index% > Offset)
                  LV_Add("", Position%A_Index%,Text%A_Index%)
  }Else If (Search AND Limit AND SubFunc){     ;show limited subFunc list for search
      Loop, %id%
          If (InStr(Text%A_Index%, Search) and Type%A_Index% = SubFunc)
              If (Position%A_Index% > Offset)
                  LV_Add("", Position%A_Index%,Text%A_Index%)
  }Else If ( (Search AND !Limit AND SubFunc)   ;show subFunc list for search
         OR (!Search AND SubFunc) )            ;show subFunc list
      Loop, %id%
          If (Type%A_Index% = SubFunc)
              If (Position%A_Index% > Offset)
                  LV_Add("", Position%A_Index%,Text%A_Index%)
  LV_ModifyCol(1, "Auto")                     ;adjust width
  LV_ModifyCol(2, "Auto")

  If ActiveGoTo_AdjustHeight {
      ListViewHeight := 45 + 14 * ( LV_GetCount() < MaxVisibleListViewRows ? LV_GetCount() : MaxVisibleListViewRows)
      GuiControl,  %ActiveGoTo_GUI%:Move, SelItem, h%ListViewHeight%
      Hide := GuiVisible ? "" : "Hide"
      Gui, %ActiveGoTo_GUI%:Show, Autosize %Hide%
    }

  GuiControl, %ActiveGoTo_GUI%:+Redraw, SelItem
  GoSub, RoutineInfoGui_HighlightItems                       ;reapply last search
  
  ISense_DynamicCmds := ""
  Loop, %id%
    If Type%A_Index% = -1
    {
      RegExMatch( Text%A_Index%, "(.*)\((.*)\)", m)
      If m2
        ISense_DynamicCmds .= m1 . "()," . m2 . "`n"
      Else
        ISense_DynamicCmds .= m1 . "()`n"
      ISense_m_%m1%[] := "about:" . m1 . "(" . m2 . ")"        ; dynamic function help
      
    }
  ISense_CreateSyntaxArray( ISense_AllStaticCmds . "`n" . ISense_DynamicCmds )
Return
;-----
RoutineInfoGui_HighlightItems:              ;highlight items in listview
  Loop % LV_GetCount() {             ;highlight all which contain search
    LV_GetText(Text, A_Index , 2)
    If ( InStr(Text,Search) AND Search)
      LV_Modify(A_Index,"Select")
    Else
      LV_Modify(A_Index,"-Select")
  }
  If !Search                         ;highlight first if no search text
    LV_Modify(1,"Select")
;   If A_GuiControl <> Offset             ;*** This was causing editor to lose window focus
;     GuiControl, %ActiveGoTo_GUI%:Focus, Search
Return
;-----
RoutineInfoGui_Close:                       ;exit when gui closes
  If !GuiVisible
      Gui, %ActiveGoTo_GUI%:Show, Hide
  DetectHiddenWindows, On
  WinGetPos, X, Y, W, H, ahk_id %ActiveGoTo_HWND%
  DetectHiddenWindows, Off
  IniWrite, x%X% y%Y%, Config.ini, ActiveGoTo, Pos
  IniWrite, w%W% h%H%, Config.ini, ActiveGoTo, Size
;   ExitApp
; return
;-------
RoutineInfoGui_Escape:                      ;hide gui on ESC
  WinActivate, ahk_id %ActiveGoTo_EditorHWND%
  If !Slide
    Return
RoutineInfoGui_Hide:
  DllCall( "AnimateWindow", "Int", ActiveGoTo_HWND, "Int", 200, "Int", AniHide )
  GuiVisible := False
Return
;-------
RoutineInfoGui_Search:                      ; Search by user input
  GuiControlGet, Search, %ActiveGoTo_GUI%:
  If Limit
    GoSub, RoutineInfoGui_FillList
  Else
    GoSub, RoutineInfoGui_HighlightItems
Return
;-------
RoutineInfoGui_LSelect:                     ;goto position on double click in listview
  IfNotEqual, A_GuiEvent, DoubleClick, Return
  GotoPos(A_EventInfo)
Return
;-------
RoutineInfoGui_Select:                      ;goto position of first selected (highlighted)
  Row := LV_GetNext()
  If !Row
      Return
  GotoPos(Row)
Return
;-------
RoutineInfoGui_ContextMenu:                 ;show context menu
  Menu, Context, Show
return
;-------
RoutineInfoGui_Size:
  Anchor("Search",    "w",  True)
  Anchor("TxtOffset", "x",  "")
  Anchor("Offset",    "x",  True)
  Anchor("SelItem",   "wh", "")
Return
;----------------------------------------------------------------------------------------------

;generate BM array
GenerateBM( FileName ){
    local state,CurrLine,hotkey,hotkeyName
         ,function,functionName,functionLine,functionClosingParen,functionOpeningBrace
         ,functionParameters,functionParametersEX,hotstring,hotstringName,label,labelName
;     Global ActiveGoTo_identifierRE, ActiveGoto_parameterListRE, ActiveGoto_lineCommentRE
    SetBatchLines, -1
    id = 0                                        ;reset index of BM array
    FileRead, FileData, %FileName%                ;read file
    state = DEFAULT
    Loop, Parse, FileData, `n, `r                 ;search for bookmarks
      {
        CurrLine = %A_LoopField%                  ;remove spaces and tabs
        
        If RegExMatch(CurrLine, "^\s*(?:;.*)?$") ; Empty line or line with comment, skip it
            Continue
                 
        Else If InStr(state, "COMMENT"){             ; In a block comment
            If RegExMatch(CurrLine, "S)^\s*\*/")     ; End of block comment
                StringReplace state, state, COMMENT  ; Remove state
                ; "*/ function_def()" is legal but quite perverse... I won't support this
      
        }Else If InStr(state,"CONTSECTION") {        ; In a continuation section
            If RegExMatch(CurrLine, "^\s*\)")        ; End of continuation section
                state = DEFAULT
  
        }Else If RegExMatch(CurrLine, "^\s*/\*")         ; Start of block comment, to skip
            state = %state% COMMENT
      
        Else If RegExMatch(CurrLine, "^\s*\(")           ; Start of continuation section, to skip
            state = CONTSECTION
      
        ;hotstring RegEx
          ;very strict : "i)^\s*(?P<Name>:(?:\*0?|\?0?|B0?|C[01]?|K(?:-1|\d+)|O0?|P\d+|R0?|S[IPE]|Z0?)*:.+?)::"
          ;less strict : "i)^\s*:[*?BCKOPRSIEZ\d-]*:(?P<Name>.+?)::"
        ;loose         : "^\s*:[*?\w\d-]*:(?P<Name>.+?)::" 
        ;the loose RegEx doesn't need update when new features get added
      
        Else If RegExMatch(CurrLine, "^\s*:[*?\w\d-]*:(?P<Name>.+?)::", hotstring){ ;HotString
            AddToBMArray(A_Index, ".." . hotstringName . "::")
            state = DEFAULT
  
        }Else If RegExMatch(CurrLine, "i)^\s*(?P<Name>[^ \s]+?(?:\s+&\s+[^\s]+?)?(?:\s+up)?)::", hotkey){  ;Hotkey
            AddToBMArray(A_Index,hotkeyName . "::")
            state = DEFAULT
      
        }Else If RegExMatch(CurrLine, "^\s*(?P<Name>[^\s,```%]+):" . ActiveGoto_lineCommentRE, label){   ; Label are very tolerant...
            AddToBMArray(A_Index,labelName . ":", 1)
            state = DEFAULT
        
        }Else If InStr(state,"DEFAULT"){
            If RegExMatch(CurrLine, "^\s*(?P<Name>[" . ActiveGoTo_identifierRE . "]+)"         ; Found a function call or a function definition
                              . "\((?P<Parameters>[" . ActiveGoto_parameterListRE . "]*)"
                              . "(?P<ClosingParen>\)\s*(?P<OpeningBrace>\{)?)?"
                              . ActiveGoto_lineCommentRE, function){
                state = FUNCTION
                functionLine := A_Index
                If functionClosingParen{        ; With closed parameter list
                    If functionOpeningBrace {     ; Found! This is a function definition
                        AddToBMArray(functionLine,functionName . "(" . functionParameters . ")", - 1)
                        state = DEFAULT
                    }Else                         ; List of parameters is closed, just search for opening brace
                        state .= " TOBRACE"
                }Else                           ; With open parameter list
                    state .= " INPARAMS"      ; Search for closing parenthesis
                  }
        
        }Else If InStr(state,"FUNCTION"){
            If InStr(state, "INPARAMS") {     ; After a function definition or call
                ; Looking for ending parenthesis
                If (RegExMatch(CurrLine, "^\s*(?P<ParametersEX>,[" . ActiveGoto_parameterListRE . "]+)"
                                   . "(?P<ClosingParen>\)\s*(?P<OpeningBrace>\{)?)?" . ActiveGoto_lineCommentRE, function) > 0){
                    functionParameters .= functionParametersEX
                    If functionClosingParen {            ; List of parameters is closed
                        If functionOpeningBrace{   ; Found! This is a function definition
                          AddToBMArray(functionLine,functionName . "(" . functionParameters . ")", -1)
                          state = DEFAULT
                        }Else                              ; Just search for opening brace
                          StringReplace state, state, INPARAMS, TOBRACE ; Remove state
                      }                                    ; Otherwise, we continue
                }Else   
                    ; Incorrect syntax for a parameter list, it was probably just a function call, e.g. contained a "+"
                    state = DEFAULT
            }Else If InStr(state,"TOBRACE"){ ; Looking for opening brace. There can be only empty lines and comments, which are already processed
                If (RegExMatch(CurrLine, "^\s*(?:\{)" . ActiveGoto_lineCommentRE) > 0){  ; Found! This is a function definition
                    AddToBMArray(functionLine,functionName . "(" . functionParameters . ")", -1)
                    state = DEFAULT
                }Else  ; Incorrect syntax between closing parenthesis and opening brace,
                    state = DEFAULT     ; it was probably just a function call
            }
          }
      }
    GoSub, RoutineInfoGui_FillList
  }

;generate BM Array
AddToBMArray(Pos, Text, Type =""){
    global
    id++                  ;add BM to array
    Text%id% := RegExReplace(Text, "\s\s*", " ")  ; Replace multiple blank chars with simple space
    Position%id% = %Pos%
    Type%id% = %Type%
  }


;find goto position
GotoPos(Row="")  {
    static LastPos,LastB4LastPos
    If Row {                          
        LV_GetText(Pos, Row, 1)       ;get pos of row
        SendGoTo(Pos)                 ;send position
        If !LastPos                   ;remember positions
            LastPos = %Pos%
        LastB4LastPos = %LastPos%     
        LastPos = %Pos%
    }Else {
        SendGoTo(LastB4LastPos)       ;send previous position
        swap = %LastB4LastPos%        ;swap last with previous position
        LastB4LastPos = %LastPos%
        LastPos = %swap%
      }
    GoSub, RoutineInfoGui_Escape      ;hide gui
}

;send position to editor
SendGoTo(Position)  {
    Global ActiveGoTo_EditorHWND, ActiveGoto_aGotoShortCut
    WinActivate, ahk_id %ActiveGoTo_EditorHWND%
;     WinWaitActive, ahk_id %ActiveGoTo_EditorHWND%   ; overkill
    Send, %ActiveGoto_aGotoShortCut%
    Send, %Position%{Enter}
}

;return key value from script
ReadIni(Key, Default=""){
    IniRead, Value, Config.ini, ActiveGoTo, %Key%, %Default%
    Return Value
  } 


;///////////////////////////////////
;///////////////////////////////////
;///////////////////////////////////
;///////////////////////////////////


;----------------------------------------------------------------------------------------------

Anchor(ctrl, a, draw = false) { ; v3.4.1 - Titan
    static d

    ;controls are moved/resized by a fraction of the amount the gui changes size
    ;e.g.     New pX := orig. pX  + factor * ( current guiW - orig. guiW )

    ;get pos/size of control and return if control or Gui do not exist
    GuiControlGet, p, Pos, %ctrl%
    If !A_Gui or ErrorLevel
        Return

    s = `n%A_Gui%:%ctrl%=                         ;unique prefix to store pos/size
    c = x.w.y.h./.7.%A_GuiWidth%.%A_GuiHeight%    ;multi purpose string for efficiency
    StringSplit, c, c, .

    Loop, 4     ;get scale factors
        b%A_Index% += !RegExMatch(a, c%A_Index% . "(?P<" . A_Index . ">[\d.]+)", b)

    ;on first call for this control, remember original position, size
    If !InStr(d, s)
        d .= s . px - c7 * b1 . c5 . pw - c7 * b2
          . c5 . py - c8 * b3 . c5 . ph - c8 * b4 . c5

    ;calculate new position and size
    Loop, 4
      If InStr(a, c%A_Index%) {
        c6 += A_Index > 2
        RegExMatch(d, s . "(?:(-?[\d.]+)/){" . A_Index . "}", p) ;get factor
        ;combine "x/w/y/h" with (orig. control pos/size - orig. gui width/height * factor  + current gui width/height * factor)
        m := m . c%A_Index% . p1 + c%c6% * b%A_Index%
      }

    ;move/resize control to new pos/size
    t := !draw ? "" : "Draw"
    GuiControl, Move%t%, %ctrl%, %m%
  }
;----------------------------------------------------------------------------------------------

ActiveGoTo_MenuHandler( ThisMenuItem )
{
	global
; 	global ActiveGoTo_HtkGrp

	if ( ThisMenuItem = "Frame" ) {           ;toggle visibility of frame
    If ActiveGoTo_ToggleFrame
        Gui, %ActiveGoTo_GUI%:-Caption
    Else
        Gui, %ActiveGoTo_GUI%:+Caption
    ActiveGoTo_MenuToggle(ActiveGoTo_ToggleFrame ? "UnCheck" : "Check","Frame")
    ActiveGoTo_ToggleFrame := not ActiveGoTo_ToggleFrame
    IniWrite, %ActiveGoTo_ToggleFrame%, Config.ini, ActiveGoTo, ToggleFrame
  }
  
  if ( ThisMenuItem = "Slide" ) {           ;toggle slide of gui On/0ff
  	If (!GuiVisible And ActiveGoTo_Slide)
      RoutineInfoGui_Show()
    Hotkey, IfWinActive, ahk_group ActiveGoTo_HtkGrp
    Hotkey, F1, % ActiveGoTo_Slide ? "Off" : "On"
    Hotkey, IfWinActive
    ActiveGoTo_MenuToggle(ActiveGoTo_Slide ? "UnCheck" : "Check","Slide")
    ActiveGoTo_Slide := not ActiveGoTo_Slide
    IniWrite, %ActiveGoTo_Slide%, Config.ini, ActiveGoTo, Slide
	}

	if ( ThisMenuItem = "Slide Left" ) {       ;toggle slide of gui to left or right
    AniShow := ActiveGoTo_ToggleLeft ? "0x00040002" : "0x00040001"
    AniHide := ActiveGoTo_ToggleLeft ? "0x00050001" : "0x00050002"
    ActiveGoTo_MenuToggle(ActiveGoTo_ToggleLeft ? "UnCheck" : "Check","Slide Left")
    ActiveGoTo_ToggleLeft := not ActiveGoTo_ToggleLeft
    IniWrite, %ActiveGoTo_ToggleLeft%, Config.ini, ActiveGoTo, ToggleLeft
  }

	if ( ThisMenuItem = "Adjust Height" ) {    ;toggle auto adjust gui to number of items in list
    ListViewHeight := 45 + 14 * ( LV_GetCount() > MaxVisibleListViewRows OR ActiveGoTo_AdjustHeight OR !LV_GetCount() ? MaxVisibleListViewRows : LV_GetCount() )
    GuiControl, %ActiveGoTo_GUI%:Move, SelItem, h%ListViewHeight%
    Hide := GuiVisible ? "" : "Hide"
    Gui, %ActiveGoTo_GUI%:Show, Autosize %Hide%
    ActiveGoTo_MenuToggle(ActiveGoTo_AdjustHeight ? "UnCheck" : "Check","Adjust Height")
    ActiveGoTo_AdjustHeight := not ActiveGoTo_AdjustHeight
    IniWrite, %ActiveGoTo_AdjustHeight%, Config.ini, ActiveGoTo, AdjustHeight
  }

	if ( ThisMenuItem = "Hide On Lost Focus" ) {
    ActiveGoTo_MenuToggle(ActiveGoTo_HideOnLostFocus ? "UnCheck" : "Check","Hide On Lost Focus")
    ActiveGoTo_HideOnLostFocus := not ActiveGoTo_HideOnLostFocus
    IniWrite, %ActiveGoTo_HideOnLostFocus%, Config.ini, ActiveGoTo, HideOnLostFocus
  }
}

ActiveGoTo_MenuDispatch:
  ActiveGoTo_MenuHandler( A_ThisMenuItem )
return


ActiveGoTo_MenuToggle(State,Menu){      ;toggle context menu checkbox
     Menu, Context, %State%, %Menu%
  }

;----------------------------------------------------------------------------------------------
ActiveGoTo_HotkeyHandler( ThisHotkey )
{
 global ActiveGoTo_HWND

; ToolTip, % ThisHotkey
  If ( ThisHotkey = "F1" )
    RoutineInfoGui_Show()
  Else If ( ThisHotkey = "F2" ) ;toggle between last and last before last position
    GotoPos()
  Else If ( ThisHotkey = "Up" )
    ControlSend, SysListView321, {Up},   ahk_id %ActiveGoTo_HWND%
  Else If ( ThisHotkey = "Down" )
    ControlSend, SysListView321, {Down}, ahk_id %ActiveGoTo_HWND%
  Else If ( ThisHotkey = "PgUp" )
    ControlSend, SysListView321, {PgUp}, ahk_id %ActiveGoTo_HWND%
  Else If ( ThisHotkey = "PgDn" )
    ControlSend, SysListView321, {PgDn}, ahk_id %ActiveGoTo_HWND%
  Else If ( ThisHotkey = "WheelUp" )
    ControlSend, SysListView321, {Up},   ahk_id %ActiveGoTo_HWND%
  Else If ( ThisHotkey = "WheelDown" )
    ControlSend, SysListView321, {Down}, ahk_id %ActiveGoTo_HWND%
  Else If ( ThisHotkey = "MButton" )
    GoSub, RoutineInfoGui_Select
  Else If ( ThisHotkey = "^BackSpace" )
    Send,^+{Left}{Del}
}

ActiveGoTo_HotkeyDispatch:
  ActiveGoTo_HotkeyHandler( A_ThisHotkey )
return

;----------------------------------------------------------------------------------------------

;check editor window title for change timer
ActiveGoTo_EditorTitleTimer:    
  ActiveGoTo_EditorTitleCheck()
Return

;check editor window title for change
ActiveGoTo_EditorTitleCheck( ) {
  local HWND, EType, WinTitle, Extension, File, FileName, FileUnSaved
  static PreviousSaveStatus,LastFileName
  ;global ActiveGoTo_aEditorTitleRE, ActiveGoTo_EditorHWND, ActiveGoto_aGotoShortCut

  If GetKeyState("Ctrl")           ;wait for ctrl key to be up again while changing tabs
    Return

  HWND := WinExist("A")       ;get HWND of active window
  EType := EType%HWND%        ;and test what editor type this Window is

  ;Set methods based on current editor.    ;***
  Isense_CurrentGetLineMethod  := EType ? Isense_aGetLineMethod%EType%  : 2
  ISense_CurrentSendLineMethod := EType ? Isense_aSendLineMethod%EType% : 1
  ISense_CurrentEditorTypeNum  := EType
  ActiveGoto_MonitorDoc := ActiveGoto_aMonitorDocument%EType% = "True" ? true : false

  If (ActiveGoTo_Slide AND GuiVisible AND HWND <> ActiveGoTo_HWND AND (!EType OR ActiveGoTo_HideOnLostFocus))
    GoSub, RoutineInfoGui_Hide ;when slide is turned on and gui or a editor are not active, but gui is visible, hide it

  If !EType                  ;No Editor active, don't update
    Return

  WinGetTitle, WinTitle, ahk_id %HWND%    ;get current editor title
  RegExMatch(WinTitle, ActiveGoTo_aEditorTitleRE%EType%, File)  ;extract filename and save state

  SplitPath, FileName, , , Extension, ,   ;get extension
  If (Extension <> "ahk")                 ;don't continue when not a ahk script
    Return

  If ( ( FileName <> LastFileName )       ;update BM list, when filename changed
    OR (  !InStr(FileUnSaved,"*")
        AND !PreviousSaveStatus)){        ;or when file got saved
      ActiveGoTo_EditorHWND            = %HWND%
      ActiveGoto_aGotoShortCut        := ActiveGoto_aGotoShortCut%EType%
      GenerateBM( FileName )              ;trigger bookmark (BM) generation
      LastFileName = %FileName%
      PreviousSaveStatus := True
  }Else If InStr(FileUnSaved,"*")
    PreviousSaveStatus := False
}
;----------------------------------------------------------------------------------------------

;check for open editors timer
ActiveGoTo_EditorTypeTimer:
  ActiveGoTo_EditorTypeCheck()
Return

ActiveGoTo_EditorTypeCheck()  {       ; GetEditorHWNDandType - Check for open editors
  local IDsOfAllWindows,WinTitle,HWND
  Static ListOfHWND
;   global ActiveGoTo_HtkGrp, ActiveGoTo_aEditorTitleRE

  ;New editor windows get added to EType array
  ;Closed editor windows are not removed.
  ;Script should be restarted after a time to start from scratch
  ;Didn't want to re-initialize the list each time, since it might cause trouble
  ;if a goto jump is performed the same time.
  DetectHiddenWindows, On         ;detect editor also when minimized
  WinGet, IDsOfAllWindows, List
  Loop, %IDsOfAllWindows% {
    HWND := IDsOfAllWindows%A_Index%
    If HWND in %ListOfHWND%
        Continue
    WinGetTitle, WinTitle, ahk_id %HWND%
    IfEqual, WinTitle,, Continue

    Loop, %ActiveGoTo_aEditorTitleRE0%{
      If RegExMatch(WinTitle, ActiveGoTo_aEditorTitleRE%A_Index%, File){
        EType%HWND% = %A_Index%
        ListOfHWND .= (ListOfHWND ? "," : "") . HWND
        GroupAdd, ActiveGoTo_HtkGrp, ahk_id %HWND%
        break
      }
    }
  }
  DetectHiddenWindows, Off
}

;----------------------------------------------------------------------------------------------
