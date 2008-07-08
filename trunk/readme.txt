ISense - IntelliSense script for AutoHotKey language 


OVERVIEW
--------
This is command completition and parameter tracking script for AutoHotKey language. 
It is made to help you edit your code faster, to locate exact parameter position 
with complex commands (like InputBox), and generaly, provide you help with AutoHotKey 
without ever leaving your editor.


FEATURES
---------
- Info window that contain all commands that start with currently typed prefix
- Parameter display and tracking
- Full help on last typed command
- Works on already typed sentences
- Every aspect of script is customizable (colors, transparency, hotkeys ...)
- Plugins for non standard editors. Choose among different ISense methods or write your own.


USAGE
-----
Title of your editor window must include ".ahk" somewhere. To make ISense monitor your input, 
press SPACE, TAB or ENTER. After typing 3 letters Info window will appear containing AHK commands 
starting with letters you typed. If you continue to type Info window will repopulate commands in the
list based on your letters. The list will be returned to previous state when you delete characters. 
While Info windows is visible, use arrows, pgup, pgdn, home & end to select the desired command. 
Press TAB, COMMA, or CLICK to evaluate the selection. If you don't select anything first command 
in the Info window will be evaluated. 

After evaluation the script will change mode to parameter tracking. Current parameter will be shown bold. 
If you press CTRL SPACE while tooltip is visible, full help on current command will be shown. 
You can scroll help using arrows, pgup, pgdn, home & end. 

To cancel any ISense window at any moment pres ESC, or move arond the code.
You can also press CTRL SPACE on any part of the line. ISense will grab that line and try to locate 
the AHK command and current parameter. This procedure is editor specific so if it doesn't work with your
editor choose different method or write your own.



HOW TO WRITE METHOD
-------------------
Methods are located in includes\editor folder, with "Method N.ahk" names. Method is single AHK function,
ISense_GetLine witch returns text from the current cursor position to the beginning of the line, for 
supported editors. It also contains INI section [EDITOR] whree you specify supported editors for that 
method.

To write new method, start by duplicating some of the method files. Save it under any name that doesn't 
exist and replace the internals of the ISense_GetLine function.	Whatever you do, cursor must be returned
to the same position as before you stared. When you grab the line, return it to the ISense, and thats all.
Afterwards, go to Setup and activate the new method witch will be visible in the list as soon as you save it.\
All supported editors specified by the INI part of the method will also be added to the editor list.

When you discover that your editor works with some of the already present methods and editor itself is not
in the editor list, please inform me on the forum so I can update the editor list. Do the same if you wrote 
the new method for your editor.


CONFIRMED EDITORS:

Method1 - EditPlus, EmEditor, Programmers NotePad 2, PSPad, Scite 
Method2 - Crimson Editor, UltraEdit, SynPlus, Syn 
Method3 - Notepad, Metapad



NOTES 
-----
Tracing tooltip can be enabled for debuging. To enable it, uncomment line 1: 

    1:  Isense_trace := true
 
If you find any bug make sure nobody reported it (check out the BUGS section) before posting it. 
Suggestions & feedback are appreciated.


TO-DO
-----
- Functions
- User variables and functions
- Language definition file so it is able to work with other languages.


THANK YOU
---------
Rajat for inspiration
All who tested this script
Chris for creating AutoHotKey


ABOUT
-----
Created by Miodrag Milic  
miodrag.milic@gmail.com


code.r-moth.com		www.r-moth.com		 r-moth.deviantart.com

Belgrade
23. Januar 2007