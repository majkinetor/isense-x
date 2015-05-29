# Overview #

This is command completition and parameter tracking script for [AutoHotKey](http://www.autohotkey.com) language. It is made to help you edit your code faster, to locate exact parameter position with complex commands (like [InputBox](http://www.autohotkey.com/docs/commands/InputBox.htm)), and generaly, provide you help with AutoHotKey without ever leaving your editor.


# [Forum](http://www.autohotkey.com/forum/viewtopic.php?t=12985&start=0) #

# Features #

  * Works in every place having keyboard input and generaly can be made to work with any  editor around.
  * Info window that contains all commands, AHK and user functions that start with currently typed word part.
  * [ActiveGoTo](http://www.autohotkey.com/forum/topic11998.html) integration (F1)
  * Parameter display and tracking.
  * Full help on last typed command.
  * Works on already typed sentences.
  * Every aspect of script is customizable (colors, transparency, hotkeys ...)


# Usage #

To make ISense monitoring your input, title of your editor window must have word ".ahk" somewhere and you must press SPACE, TAB or ENTER. After typing 3 letters Info window will be shown. It contains AHK commands starting with letters you typed. If you continue to type Info window will repopulate commands in the list based on the last letters you typed. The list will be returned to previous state when you delete charachters.

While Info window is visible, use arrows, pgup, pgdn, home & end to select the desired command. Press TAB or COMMA, or CLICK to evaluate the selection. If you don't select anything first command in the Info window will be evaluated.

After evaluation the script will change mode to parameter tracking. Current parameter will be shown bold.

To show full help for current command press press CTRL SPACE while tooltip is visible. You can scroll help using arrows, pgup, pgdn, home & end.

To cancel any ISense window at any moment pres ESC, or move around the code.

You can also press CTRL SPACE on any part of any line. ISense will grab that line and try to locate the AHK command and parameter at cursor position. This procedure is editor specific so if it doesn't work with your editor, choose different method or write your own.

# Notes #
Some editors have custom controls for text editing so some function may not work correctly or not work at all