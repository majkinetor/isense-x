

;-- ISense_Init section --
; SetBatchLines, -1
;   ISense_Opt_TitleWord   = .ahk,.bat,.pl,Internet Explorer
  ISense_Opt_ClearKeys = SPACE,ENTER,NumpadEnter,LButton,RButton
  ISense_Opt_MinLen    = 2

  If err := ISense_ValidateEditorPlugins()  ; Parse through and validate editor plugins
    MsgBox, 48, Error with editor plugin detected  , % err
    
  If err := ISense_ValidateLangPlugins()    ; Parse through and validate language plugins
    MsgBox, 48, Error with language plugin detected, % err

  WinGetTitle, title, A
  ISense_ValidateCurrentEditor( title ) ; Set initial values based on current window
  ToolTip()                             ; refresh debugging window

  ; Set event hooks to monitor editor
  ISense_EnableEditorHook(true)

  ; Set keyboard hooks (hotkeys) to monitor typing
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
  global ISense_Opt_ClearKeys, ISense_Opt_MinLen, ISense_lastWord, ISense_LangSyntax, ISense_CommandResults

  key := SubStr( A_ThisHotkey, 3 )
  
  if key in %ISense_Opt_ClearKeys%
    ISense_lastWord := ISense_CommandResults := ""
  Else If key = BACKSPACE
    ISense_lastWord := SubStr( ISense_lastWord, 1, StrLen( ISense_lastWord ) - 1 )
  Else
    ISense_lastWord .= key


    
  ; if lastword is less than users minLen..
  If ( StrLen( ISense_lastWord ) < ISense_Opt_MinLen )  {
    ISense_CommandResults =
    return
  }

  ; Search lang syntax for command matches
  ISense_CommandResults := RegExReplace( ISense_LangSyntax "`n", "Uim`a)((^" ISense_lastWord ".*\R)|(?<!^" ISense_lastWord ").*\R)", "$2" )
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
;   global    ; assumed
  local class, thisEditor
  static pEditorNum,pCurrentLang

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
        thisEditor := Editor_aPluginName%A_Index%
        %thisEditor%_init()
        ISense_lastWord =
        break
      }
  } 

  ;-- not a detected editor, but recognized title word
  Else If ISense_Opt_TitleWord && InStr_MatchList( title, ISense_Opt_TitleWord )
    pEditorNum := Editor_GetLineMethod := Editor_SendLineMethod := "?" ; Default methods
    
  ;-- not a known editor & no match in title word
  Else {
    pEditorNum := Editor_GetLineMethod := Editor_SendLineMethod := ISense_CurrentLang := ""
    ISense_lastWord = (not monitoring..)
    return
  }

  Editor_Class = %class%
  WinGet, Editor_Hwnd, ID, %title%

  ;-- if editor has a default language specified
  If Editor_DefaultLang
    ISense_CurrentLang := Editor_DefaultLang
  Else If OnMatch_Ext in %ISense_LangPlugins%
    ISense_CurrentLang := OnMatch_Ext
  Else
    ISense_CurrentLang := ISense_LangSyntax := ""

  ;-- load lang_init section
  If ISense_CurrentLang && (ISense_CurrentLang != pCurrentLang) {
    pCurrentLang := ISense_CurrentLang  , ISense_LangSyntax := ""
    %ISense_CurrentLang%_init()
  }

  Loop, % Editor_Count  ; global cleanup of RE named param matches..
    OnMatch_EditorNum%A_Index% := ""
   OnMatch_Name := OnMatch_UnSaved := ""
}

;---
ISense_ValidateLangPlugins()  {
  global ISense_LangPlugins, ISense_LangSyntax
;   local lang_plugins, errorMsg

;   PluginLoader_Init("Lang") , lang_plugins := PluginLoader_Get()
  lang_plugins = Ahk`nBat`nPl`nTxt   ;***
  
  ; load each lang_init individually, & error check.. (not sure what all will be involved yet..)
  Loop, Parse, lang_plugins, `n, `r
  {
    If %A_LoopField%_init()  {

      ISense_LangPlugins .= ISense_LangPlugins ? "," A_LoopField : A_LoopField
    }
    Else
      errorMsg .= """" A_LoopField "_init()"" doesn't exist. Couldn't initialize.`n"
  }
  ISense_LangSyntax =
  return errorMsg
}

;---
ISense_ValidateEditorPlugins()  {
;- This section will parse editor plugins, assemble validation RE's, & set editor arrays

; global Editor_Count, Editor_PluginTitleRE, Editor_PluginClassRE, Editor_aPluginName
  local editor_plugins, errorMsg, cnt, titleRE, classRE

;   PluginLoader_Init("Editors") , editor_plugins := PluginLoader_Get()
  editor_plugins = CmdPrompt`nEditPlus`nNotepad`nPSPad    ;***
  
  Loop, Parse, editor_plugins, `n, `r
  {
    If %A_LoopField%_init()  {
      If !(Editor_TitleRE || Editor_ClassRE)
        errorMsg .= A_LoopField "_init(): Neither editor title nor class were specified. Couldn't initialize.`n"

      Else If !Editor_SendLineMethod
        errorMsg .= A_LoopField "_init(): Editor_SendLineMethod = ''. Must specify value.`n"

      Else If !Editor_GetLineMethod
        errorMsg .= A_LoopField "_init(): Editor_GetLineMethod = ''. Must specify value.`n"

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
      errorMsg .= """" A_LoopField "_init()"" doesn't exist. Couldn't initialize.`n"

    Editor_TitleRE := Editor_ClassRE := Editor_GetLineMethod := Editor_SendLineMethod :=
    Editor_DefaultLang := Editor_GotoShortCut := ""
  }
  return errorMsg
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
           . "ISense_CurrentLang = " . ISense_CurrentLang  . "`t`t"
           . "ISense_LangSyntax = " . (ISense_LangSyntax ? "loaded.." : "undefined..")  . "`n"
           . "ISense_lastWord = " . ISense_lastWord . "`n"
           . (ISense_CommandResults ? "`n/// ISense_CommandResults ///`n`n" . ISense_CommandResults . "`n" : "")
           . , 5, 5
}


;/// Includes / Plugins ///

;==================== START: #Include Editors\CmdPrompt.ahk  ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

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

;==================== END: #Include Editors\CmdPrompt.ahk  ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Editors\EditPlus.ahk   ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

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


;==================== END: #Include Editors\EditPlus.ahk   ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Editors\Notepad.ahk    ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

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

;==================== END: #Include Editors\Notepad.ahk    ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Editors\PSPad.ahk      ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

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

;==================== END: #Include Editors\PSPad.ahk      ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


;==================== START: #Include Lang\Ahk.ahk           ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


Ahk_init()  {
;   global    --assumed..
  local cmds,funcs
  static lang

  If !lang  {
    FileRead,cmds, % SubStr(A_AhkPath,1,InStr(A_AhkPath,"\","",0)) "Extras\Editors\Syntax\Commands.txt"
    lang:=RegExReplace( RegExReplace(cmds,"\r") . "`n"  ,"mU)([^\[,]+)((\[|,| ).*)?\n","$1" A_Tab "$2`n")

    FileRead,funcs, % SubStr(A_AhkPath,1,InStr(A_AhkPath,"\","",0)) "Extras\Editors\Syntax\Functions.txt"
    lang.=RegExReplace( RegExReplace(funcs,"\r") . "`n" ,"mU)([^\(]+\()([^\)]+)?\)\n","$1)" A_Tab "$2`n")
    Sort, lang
  }
  
  ISense_LangSyntax = %lang%

  return true
}


;==================== END: #Include Lang\Ahk.ahk           ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Lang\Bat.ahk           ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


Bat_init()  {
  global    ;    --assumed..

  ISense_LangSyntax =
  ( ltrim %
    ASSOC [.ext[=[fileType]]]
    AT [\\computername] [ [id] [/DELETE] | /DELETE [/YES]]
    AT [\\computername] time [/INTERACTIVE][ /EVERY:date[,...] | /NEXT:date[,...]] "command"
    ATTRIB [+R | -R] [+A | -A ] [+S | -S] [+H | -H] [drive:][path][filename][/S [/D]]
    CACLS filename [/T] [/E] [/C] [/G user:perm] [/R user [...]][/P user:perm [...]] [/D user [...]]
    CALL [drive:][path]filename [batch-parameters]
    CALL :label arguments
    CHDIR [/D] [drive:][path]
    CHDIR [..]
    CD [/D] [drive:][path]
    CD [..]
    CHCP [nnn]
    CHDIR [/D] [drive:][path]
    CHDIR [..]
    CD [/D] [drive:][path]
    CD [..]
    CHKDSK [volume[[path]filename]]] [/F] [/V] [/R] [/X] [/I] [/C] [/L[:size]]
    CHKNTFS volume [...]
    CHKNTFS /D
    CHKNTFS /T[:time]
    CHKNTFS /X volume [...]
    CHKNTFS /C volume [...]
    CLS
    CMD [/A | /U] [/Q] [/D] [/E:ON | /E:OFF] [/F:ON | /F:OFF] [/V:ON | /V:OFF][[/S] [/C | /K] string]
    COLOR [attr]
    COMP [data1] [data2] [/D] [/A] [/L] [/N=number] [/C] [/OFF[LINE]]
    COMPACT [/C | /U] [/S[:dir]] [/A] [/I] [/F] [/Q] [filename [...]]
    CONVERT volume /FS:NTFS [/V] [/CvtArea:filename] [/NoSecurity] [/X]
    COPY [/D] [/V] [/N] [/Y | /-Y] [/Z] [/A | /B ] source [/A | /B][+ source [/A | /B] [+ ...]] [destination [/A | /B]]
    DATE [/T | date]
    DEL [/P] [/F] [/S] [/Q] [/A[[:]attributes]] names
    ERASE [/P] [/F] [/S] [/Q] [/A[[:]attributes]] names
    DIR [drive:][path][filename] [/A[[:]attributes]] [/B] [/C] [/D] [/L] [/N][/O[[:]sortorder]] [/P] [/Q] [/S] [/T[[:]timefield]] [/W] [/X] [/4]
    DISKCOMP [drive1: [drive2:]]
    DISKCOPY [drive1: [drive2:]] [/V]
    DOSKEY [/REINSTALL] [/LISTSIZE=size] [/MACROS[:ALL | :exename]][/HISTORY] [/INSERT | /OVERSTRIKE] [/EXENAME=exename] [/MACROFILE=filename][macroname=[text]]
    ECHO [ON | OFF]
    ECHO [message]
    ENDLOCAL
    DEL [/P] [/F] [/S] [/Q] [/A[[:]attributes]] names
    ERASE [/P] [/F] [/S] [/Q] [/A[[:]attributes]] names
    EXIT [/B] [exitCode]
    FC [/A] [/C] [/L] [/LBn] [/N] [/OFF[LINE]] [/T] [/U] [/W] [/nnnn][drive1:][path1]filename1 [drive2:][path2]filename2
    FC /B [drive1:][path1]filename1 [drive2:][path2]filename2
    FIND [/V] [/C] [/N] [/I] [/OFF[LINE]] "string" [[drive:][path]filename[ ...]]
    FINDSTR [/B] [/E] [/L] [/R] [/S] [/I] [/X] [/V] [/N] [/M] [/O] [/P] [/F:file][/C:string] [/G:file] [/D:dir list] [/A:color attributes] [/OFF[LINE]]
    FOR %variable IN (set) DO command [command-parameters]
    FORMAT volume [/FS:file-system] [/V:label] [/Q] [/A:size] [/C] [/X]
    FORMAT volume [/V:label] [/Q] [/F:size]
    FORMAT volume [/V:label] [/Q] [/T:tracks /N:sectors]
    FORMAT volume [/V:label] [/Q]
    FORMAT volume [/Q]
    FTYPE [fileType[=[openCommandString]]]
    GOTO label
    GRAFTABL [xxx]
    GRAFTABL /STATUS
    HELP [command]
    IF [NOT] ERRORLEVEL number command
    IF [NOT] string1==string2 command
    IF [NOT] EXIST filename command
    LABEL [drive:][label]
    LABEL [/MP] [volume] [label]
    MKDIR [drive:]path
    MD [drive:]path
    MODE COMm[:] [BAUD=b] [PARITY=p] [DATA=d] [STOP=s][to=on|off] [xon=on|off] [odsr=on|off][octs=on|off] [dtr=on|off|hs][rts=on|off|hs|tg] [idsr=on|off]
    MODE [device] [/STATUS]
    MODE LPTn[:]=COMm[:]
    MODE CON[:] CP SELECT=yyy
    MODE CON[:] CP [/STATUS]
    MODE CON[:] [COLS=c] [LINES=n]
    MODE CON[:] [RATE=r DELAY=d]
    MORE [/E [/C] [/P] [/S] [/Tn] [+n]] < [drive:][path]filename
    MOVE [/Y | /-Y] [drive:][path]filename1[,...] destination
    PATH [[drive:]path[;...][;%PATH%]
    POPD
    PRINT [/D:device] [[drive:][path]filename[...]]
    PROMPT [text]
    PUSHD [path | ..]
    RMDIR [/S] [/Q] [drive:]path
    RD [/S] [/Q] [drive:]path
    RECOVER [drive:][path]filename
    REM [comment]
    RENAME [drive:][path]filename1 filename2.
    REN [drive:][path]filename1 filename2.
    REPLACE [drive1:][path1]filename [drive2:][path2] [/A] [/P] [/R] [/W]
    REPLACE [drive1:][path1]filename [drive2:][path2] [/P] [/R] [/S] [/W] [/U]
    RMDIR [/S] [/Q] [drive:]path
    RD [/S] [/Q] [drive:]path
    SET [variable=[string]]
    SETLOCAL
    SHIFT [/n]
    SORT [/R] [/+n] [/M kilobytes] [/L locale] [/REC recordbytes][[drive1:][path1]filename1] [/T [drive2:][path2]][/O [drive3:][path3]filename3]
    START ["title"] [/Dpath] [/I] [/MIN] [/MAX] [/SEPARATE | /SHARED][/LOW | /NORMAL | /HIGH | /REALTIME | /ABOVENORMAL | /BELOWNORMAL][/WAIT] [/B] [command/program][parameters]
    SUBST [drive1: [drive2:]path]
    SUBST drive1: /D
    TIME [/T | time]
    TITLE [string]
    TREE [drive:][path] [/F] [/A]
    TYPE [drive:][path]filename
    VER
    VERIFY [ON | OFF]
    VOL [drive:]
    XCOPY source [destination] [/A | /M] [/D[:date]] [/P] [/S [/E]] [/V] [/W][/C] [/I] [/Q] [/F] [/L] [/G] [/H] [/R] [/T] [/U][/K] [/N] [/O] [/X] [/Y] [/-Y] [/Z][/EXCLUDE:file1[+file2][+file3]...]
  )

  return true
}


;==================== END: #Include Lang\Bat.ahk           ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Lang\Pl.ahk            ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


Pl_init()  {
  global    ;    --assumed..

  ; some commands to play w/...
  ISense_LangSyntax =
  ( ltrim
    abs VALUE
    abs
    accept NEWSOCKET,GENERICSOCKET
    chdir EXPR
    chdir FILEHANDLE
    chdir DIRHANDLE
    chdir
    chomp VARIABLE
    chomp( LIST )
    chomp
    chop VARIABLE
    chop( LIST )
    chop
    chown LIST
    chr NUMBER
    chr
    chroot FILENAME
    chroot
    close FILEHANDLE
    close
    closedir DIRHANDLE
    connect SOCKET,NAME
    continue BLOCK
    cos EXPR
    dbmclose HASH
    dbmopen HASH,DBNAME,MASK
    delete EXPR
    do BLOCK
    do SUBROUTINE(LIST)
    do EXPR
    dump LABEL
    eof FILEHANDLE
    eval EXPR
    eval BLOCK
    exists EXPR
    exit EXPR
    fork
    format
    formline PICTURE,LIST
    getc FILEHANDLE
    getlogin
    getpeername SOCKET
    getpgrp PID
    getppid
    getpriority WHICH,WHO
    getpwnam NAME
    getgrnam NAME
    gethostbyname NAME
    getnetbyname NAME
    getprotobyname NAME
    getpwuid UID
    getgrgid GID
    getservbyname NAME,PROTO
    gethostbyaddr ADDR,ADDRTYPE
    getnetbyaddr ADDR,ADDRTYPE
    getprotobynumber NUMBER
    getservbyport PORT,PROTO
    getpwent
    getgrent
    gethostent
    getnetent
    getprotoent
    getservent
    setpwent
    setgrent
    sethostent STAYOPEN
    setnetent STAYOPEN
    setprotoent STAYOPEN
    setservent STAYOPEN
    endpwent
    endgrent
    endhostent
    endnetent
    endprotoent
    endservent
    getsockname SOCKET
  )
  Sort, ISense_LangSyntax

  return true
}


;==================== END: #Include Lang\Pl.ahk            ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3

;==================== START: #Include Lang\Txt.ahk           ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


Txt_init()  {
  global    ;    --assumed..

  ISense_LangSyntax =
  ( ltrim
    hello there..
    corey was here.
    have a nice day.
    this is my custom text dictionary
  )

  return true
}

;==================== END: #Include Lang\Txt.ahk           ;*** :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3



;==================== START: #Include Includes\PluginLoader.ahk  :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3
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
;==================== END: #Include Includes\PluginLoader.ahk  :B1AD529B-BF4E-477F-8B9F-3080CAC55AE3


