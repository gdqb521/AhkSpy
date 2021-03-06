	;  AhkSpy

	;  Автор - serzh82saratov
	;  E-Mail: serzh82saratov@mail.ru

	;  Спасибо wisgest за помощь в создании HTML интерфейса
	;  Также благодарность teadrinker, Malcev, YMP, Irbis за их решения
	;  Описание - http://forum.script-coding.com/viewtopic.php?pid=72459#p72459
	;  Обсуждение - http://forum.script-coding.com/viewtopic.php?pid=72244#p72244
	;  GitHub - https://github.com/serzh82saratov/AhkSpy/blob/master/AhkSpy.ahk
	
p1 = %1%
If (p1 = "Zoom")
	GoTo ShowZoom
	
SingleInstance()
#NoEnv
SetBatchLines, -1
ListLines, Off
DetectHiddenWindows, On
CoordMode, Pixel

Global AhkSpyVersion := 3.00
Gosub, CheckAhkVersion
Menu, Tray, UseErrorLevel
Menu, Tray, Icon, Shell32.dll, % A_OSVersion = "WIN_XP" ? 222 : 278
If !InStr(FileExist(A_AppData "\AhkSpy"), "D")
	FileCreateDir, %A_AppData%\AhkSpy

Global MemoryFontSize := IniRead("MemoryFontSize", 0)
, FontSize := MemoryFontSize ? IniRead("FontSize", "15") : 15			;  Размер шрифта
, FontFamily :=  "Arial"												;  Шрифт - Times New Roman | Georgia | Myriad Pro | Arial
, ColorFont := "000000"													;  Цвет шрифта
, ColorBg := ColorBgOriginal := "FFFFFF"								;  Цвет фона          "F0F0F0" E4E4E4     F8F8F8
, ColorBgPaused := "FAFAFA"												;  Цвет фона при паузе     F0F0F0
, ColorSelMouseHover := "96C3DC"										;  Цвет фона элемента при наведении мыши     F9D886 96C3DC 8FC5FC AEC7E1
, ColorDelimiter := "E14B30"											;  Цвет шрифта разделителя заголовков и параметров
, ColorTitle := "27419B"												;  Цвет шрифта заголовка
, ColorParam := "189200"												;  Цвет шрифта параметров
, HeigtButton := 32														;  Высота кнопок
, PreMaxHeight := Round(A_ScreenHeight / 3 * 2)							;  Максимальная высота поля "Big text overflow hide" при которой добавлять прокрутку

  HeightStart := 523													;  Высота окна при старте
  wKey := 142															;  Ширина кнопок
  wColor := wKey//2														;  Ширина цветного фрагмента
  RangeTimer := 100														;  Период опроса данных, увеличьте на слабом ПК

Global ThisMode := IniRead("StartMode", "Control"), LastModeSave := (ThisMode = "LastMode"), ThisMode := ThisMode = "LastMode" ? IniRead("LastMode", "Control") : ThisMode
, ActiveNoPause := IniRead("ActiveNoPause", 0), MemoryPos := IniRead("MemoryPos", 0), MemorySize := IniRead("MemorySize", 0)
, MemoryZoomSize := IniRead("MemoryZoomSize", 0), MemoryStateZoom := IniRead("MemoryStateZoom", 0), StateLight := IniRead("StateLight", 1)
, StateLightAcc := IniRead("StateLightAcc", 1), SendCode := IniRead("SendCode", "vk"), StateLightMarker := IniRead("StateLightMarker", 1)
, StateUpdate := IniRead("StateUpdate", 0), SendMode := IniRead("SendMode", "send"), SendModeStr := Format("{:L}", SendMode)
, StateAllwaysSpot := IniRead("AllwaysSpot", 0), ScrollPos := {}, AccCoord := [], oOther := {}, oFind := {}, Edits := [], oMS := {}
, hGui, hTBGui, hActiveX, hFindGui, oDoc, ShowMarker, isFindView, isIE, isPaused, w_ShowStyles, MsgAhkSpyZoom, Sleep, oShowAccMarkers, oShowMarkers
, HTML_Win, HTML_Control, HTML_Hotkey, rmCtrlX, rmCtrlY, widthTB, FullScreenMode, hColorProgress
, ClipAdd_Before := 0, ClipAdd_Delimiter := "`r`n", oDocEl, oJScript, oBody, isConfirm, isAhkSpy := 1, WordWrap := IniRead("WordWrap", 0)
, MoveTitles := IniRead("MoveTitles", 1), PreOverflowHide := IniRead("PreOverflowHide", 1), DetectHiddenText := IniRead("DetectHiddenText", "on")
, MenuIdView := IniRead("MenuIdView", 0)

, _DB := "<span style='position: relative; margin-right: 1em;'></span>"
, _BT1 := "<span class='button' unselectable='on' oncontextmenu='return false' onmouseleave='OnButtonOut (this)' onmousedown='OnButtonDown (this)' "
	. "onmouseup='OnButtonUp (this)' onmouseover='OnButtonOver (this)' contenteditable='false' ", _BT2 := "</span>"
, _BP1 := "<span contenteditable='false' oncontextmenu='return false' class='BB'>" _BT1 "style='color: #" ColorParam ";' name='pre' ", _BP2 := "</span></span>"
, _BB1 := "<span contenteditable='false' oncontextmenu='return false' class='BB' style='height: 0px;'>" _BT1 " ", _BB2 := "</span></span>"
, _T1 := "<span class='box'><span class='line'><span class='hr'></span><span class='con'><span class='title'>", _T2 := "</span></span></span><br>"
, _T1P := "<span class='box'><span class='line'><span class='hr'></span><span class='con'><span class='title' style='color: #" ColorParam ";'>"
, _T0 := "<span class='box'><span class='hr'></span></span>"
, _PRE1 := "<pre contenteditable='true'>", _PRE2 := "</pre>"
, _LPRE := "<pre contenteditable='true' class='lpre'"
, _DP := "  <span id='delimiter' style='color: #" ColorDelimiter "'>&#9642</span>  "
, _BR := "<p class='br'></p>"
, _INPHK := "<input onfocus='funchkinputevent (this, ""focus"")' onblur='funchkinputevent(this, ""blur"")' "

, _PreOverflowHideCSS := ".lpre {max-width: 99`%; max-height: " PreMaxHeight "px; overflow: auto; border: 1px solid #E2E2E2;}"
, _BodyWrapCSS := "body {word-wrap: break-word; overflow-x: hidden;} .lpre {overflow-x: hidden;}"

, _ButAccViewer := ExtraFile("AccViewer Source") ? _BT1 " id='run_AccViewer'> run accviewer " _BT2 : ""
, _ButiWB2Learner := ExtraFile("iWB2 Learner") ? _BT1 " id='run_iWB2Learner'> run iwb2 learner " _BT2 : ""
, TitleText, FreezeTitleText, TitleTextP1, TitleTextP2 := TitleTextP2_Reserved := "     ( Shift+Tab - Freeze | RButton - CopySelected | Pause - Pause )     v" AhkSpyVersion
BLGroup := ["Backlight allways","Backlight disable","Backlight hold shift button"]

FixIE()
SeDebugPrivilege()
OnExit, Exit

Gui, +AlwaysOnTop +HWNDhGui +ReSize -DPIScale
Gui, Color, %ColorBgPaused%
Gui, Add, ActiveX, Border voDoc HWNDhActiveX x0 y+0, HTMLFile

ComObjError(false)
LoadJScript()
oBody := oDoc.body
oDocEl := oDoc.documentElement
oJScript := oDoc.Script
oJScript.WordWrap := WordWrap
oJScript.MoveTitles := MoveTitles
ComObjConnect(oDoc, Events)

OnMessage(0x133, "WM_CTLCOLOREDIT")
OnMessage(0x201, "WM_LBUTTONDOWN")
OnMessage(0x208, "WM_MBUTTONUP")
OnMessage(0xA1, "WM_NCLBUTTONDOWN")
OnMessage(0x7B, "WM_CONTEXTMENU")
OnMessage(0x6, "WM_ACTIVATE")
OnMessage(0x47, "WM_WINDOWPOSCHANGED")
OnMessage(0x05, "WM_SIZE")

OnMessage(MsgAhkSpyZoom := DllCall("RegisterWindowMessage", "Str", "MsgAhkSpyZoom"), "MsgZoom")
DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
OnMessage(DllCall("RegisterWindowMessage", "str", "SHELLHOOK"), "ShellProc")
DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0, "UInt", 0x409) ; eng layout

Gui, TB: +HWNDhTBGui -Caption -DPIScale +Parent%hGui% +E0x08000000 +0x40000000 -0x80000000
Gui, TB: Font, % " s" (A_ScreenDPI = 120 ? 8 : 10), Verdana
Gui, TB: Add, Button, x0 y0 h%HeigtButton% w%wKey% vBut1 gMode_Win, Window
Gui, TB: Add, Button, x+0 yp hp wp vBut2 gMode_Control, Control
Gui, TB: Add, Progress, x+0 yp hp w%wColor% vColorProgress HWNDhColorProgress cWhite, 100
Gui, TB: Add, Button, x+0 yp hp w%wKey% vBut3 gMode_Hotkey, Button
Gui, TB: Show, % "x0 y0 NA h" HeigtButton " w" widthTB := wKey*3+wColor

Gui, F: +HWNDhFindGui -Caption -DPIScale +Parent%hGui% +0x40000000 -0x80000000
Gui, F: Color, %ColorBgPaused%
Gui, F: Font, % " s" (A_ScreenDPI = 120 ? 10 : 12)
Gui, F: Add, Edit, x1 y0 w180 h26 gFindNew WantTab HWNDhFindEdit
SendMessage, 0x1501, 1, "Find to page",, ahk_id %hFindEdit%   ; EM_SETCUEBANNER
Gui, F: Add, UpDown, -16 Horz Range0-1 x+0 yp h26 w52 gFindNext vFindUpDown
GuiControl, F: Move, FindUpDown, h26 w52
Gui, F: Font, % (A_ScreenDPI = 120 ? "" : "s10")
Gui, F: Add, Text, x+10 yp+1 h24 c2F2F2F +0x201 gFindOption, % " case sensitive "
Gui, F: Add, Text, x+10 yp hp c2F2F2F +0x201 gFindOption, % " whole word "
Gui, F: Add, Text, x+3 yp hp +0x201 w52 vFindMatches
Gui, F: Add, Button, % "+0x300 +0xC00 y3 h20 w20 gFindHide x" widthTB - 21, X

Menu, Sys, Add, Backlight allways, Sys_Backlight
Menu, Sys, Add, Backlight hold shift button, Sys_Backlight
Menu, Sys, Add, Backlight disable, Sys_Backlight
Menu, Sys, Check, % BLGroup[StateLight]
Menu, Sys, Add
Menu, Sys, Add, Window or control backlight, Sys_WClight
Menu, Sys, % StateLightMarker ? "Check" : "UnCheck", Window or control backlight
Menu, Sys, Add, Acc object backlight, Sys_Acclight
Menu, Sys, % StateLightAcc ? "Check" : "UnCheck", Acc object backlight
Menu, Sys, Add
Menu, Sys, Add, Spot together (low speed), Spot_Together
Menu, Sys, % StateAllwaysSpot ? "Check" : "UnCheck", Spot together (low speed)
Menu, Sys, Add, Work with the active window, Active_No_Pause
Menu, Sys, % ActiveNoPause ? "Check" : "UnCheck", Work with the active window
If !A_IsCompiled
{
	Menu, Sys, Add, Check updates, CheckUpdate
	Menu, Sys, % StateUpdate ? "Check" : "UnCheck", Check updates
	Menu, Sys, Add
	If StateUpdate
		SetTimer, UpdateAhkSpy, -1000
}
Else
	StateUpdate := 0

Menu, Startmode, Add, Window, SelStartMode
Menu, Startmode, Add, Control, SelStartMode
Menu, Startmode, Add, Button, SelStartMode
Menu, Startmode, Add
Menu, Startmode, Add, Last Mode, SelStartMode
Menu, Sys, Add, Start mode, :Startmode
Menu, Startmode, Check, % {"Win":"Window","Control":"Control","Hotkey":"Button","LastMode":"Last Mode"}[IniRead("StartMode", "Control")]

Menu, Help, Add, Open script dir, Help_OpenScriptDir
Menu, Help, Add, Open user dir, Help_OpenUserDir
Menu, Help, Add
If FileExist(SubStr(A_AhkPath,1,InStr(A_AhkPath,"\",,0,1)) "AutoHotkey.chm")
	Menu, Help, Add, AutoHotKey help file, LaunchHelp
Menu, Help, Add, AutoHotKey official help online, Sys_Help
Menu, Help, Add, AutoHotKey russian help online, Sys_Help
Menu, Help, Add
Menu, Help, Add, About, Sys_Help
Menu, Sys, Add, Help, :Help

Menu, Script, Add, Reload, Reload
Menu, Script, Add, Exit, Exit
Menu, Sys, Add, Script, :Script

Menu, Sys, Add
Menu, Sys, Add, Pause, PausedScript
Menu, Sys, Add, Suspend hotkeys, Suspend
Menu, Sys, Add, Default size, DefaultSize
Menu, Sys, Add, Full screen, FullScreenMode
Menu, View, Add, Remember position, MemoryPos
Menu, View, % MemoryPos ? "Check" : "UnCheck", Remember position
Menu, View, Add, Remember size, MemorySize
Menu, View, % MemorySize ? "Check" : "UnCheck", Remember size
Menu, View, Add, Remember font size, MemoryFontSize
Menu, View, % MemoryFontSize ? "Check" : "UnCheck", Remember font size
Menu, View, Add, Remember state zoom, MemoryStateZoom
Menu, View, % MemoryStateZoom ? "Check" : "UnCheck", Remember state zoom
Menu, View, Add, Remember zoom size, MemoryZoomSize
Menu, View, % MemoryZoomSize ? "Check" : "UnCheck", Remember zoom size
Menu, View, Add
Menu, View, Add, Big text overflow hide, PreOverflowHide
Menu, View, % PreOverflowHide ? "Check" : "UnCheck", Big text overflow hide
Menu, View, Add, Moving titles, MoveTitles
Menu, View, % MoveTitles ? "Check" : "UnCheck", Moving titles
Menu, View, Add, Word wrap, WordWrap
Menu, View, % WordWrap ? "Check" : "UnCheck", Word wrap
Menu, Sys, Add, View settings, :View

Menu, Sys, Add, Find to page, FindView
Menu, Sys, Color, % ColorBgOriginal

Gui, Show, % "NA " (MemoryPos ? " x" IniRead("MemoryPosX", "Center") " y" IniRead("MemoryPosY", "Center") : "")
. (MemorySize ? " h" IniRead("MemorySizeH", HeightStart) " w" IniRead("MemorySizeW", widthTB) : " h" HeightStart " w" widthTB)
Gui, % "+MinSize" widthTB "x" 313

Hotkey_Init("Write_HotkeyHTML", "MLRJ")
Gosub, Mode_%ThisMode%

If (MemoryStateZoom && IniRead("ZoomShow", 0))
	AhkSpyZoomShow()
	
WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_id %hGui%
If !DllCall("WindowFromPoint", "Int64", WinX & 0xFFFFFFFF | WinY << 32) 
&& !DllCall("WindowFromPoint", "Int64", (WinX + WinWidth) & 0xFFFFFFFF | (WinY) << 32) 
&& !DllCall("WindowFromPoint", "Int64", (WinX + WinWidth) & 0xFFFFFFFF | (WinY + WinHeight) << 32) 
&& !DllCall("WindowFromPoint", "Int64", (WinX) & 0xFFFFFFFF | (WinY + WinHeight) << 32) 
	Gui, Show, NA xCenter yCenter
	
#Include *i %A_AppData%\AhkSpy\Include.ahk
Return

	; _________________________________________________ Hotkey`s _________________________________________________

#If isAhkSpy && ActiveNoPause

+Tab:: Goto PausedScript

#If (isAhkSpy && Sleep != 1 && !isPaused && ThisMode != "Hotkey")

+Tab::
SpotProc:
	(ThisMode = "Control" ? (Spot_Control() (StateAllwaysSpot ? Spot_Win() : 0) Write_Control()) : (Spot_Win() (StateAllwaysSpot ? Spot_Control() : 0) Write_Win()))
	If !WinActive("ahk_id" hGui)
	{
		ZoomMsg(1)
		WinActivate ahk_id %hGui%
		GuiControl, 1:Focus, oDoc
	}
	Else
		ZoomMsg(2) 
	KeyWait, Tab, T0.1
	Return

#If isAhkSpy && ShowMarker && (StateLight = 3 || WinActive("ahk_id" hGui))

~RShift Up::
~LShift Up:: HideMarker(), HideAccMarker()

#If isAhkSpy && Sleep != 1

Break::
Pause::
PausedScript:
	If isConfirm
		Return
	isPaused := !isPaused
	ColorBg := isPaused ? ColorBgPaused : ColorBgOriginal
	oBody.style.backgroundColor := "#" ColorBg
	ChangeCSS("css_ColorBg", ".title, .button {background-color: #" ColorBg ";}")
	Try SetTimer, Loop_%ThisMode%, % isPaused ? "Off" : "On"
	If (ThisMode = "Hotkey" && WinActive("ahk_id" hGui))
		Hotkey_Hook(!isPaused)
	If (isPaused && !WinActive("ahk_id" hGui))
		(ThisMode = "Control" ? Spot_Win() : ThisMode = "Win" ? Spot_Control() : 0)
	HideMarker(), HideAccMarker()
	Menu, Sys, % (isPaused ? "Check" : "UnCheck"), Pause
	ZoomMsg(isPaused || (!ActiveNoPause && WinActive("ahk_id" hGui)) ? 1 : 0)
	ZoomMsg(7, isPaused)
	isPaused ? TaskbarProgress(4, hGui, 100) : TaskbarProgress(0, hGui)
	TitleText := (TitleTextP1 := "AhkSpy - " ({"Win":"Window","Control":"Control","Hotkey":"Button"}[ThisMode]))
	. (TitleTextP2 := (isPaused ? "                Paused..." : TitleTextP2_Reserved))
	SendMessage, 0xC, 0, &TitleText, , ahk_id %hGui%
	PausedTitleText()
	Return
	
~RShift Up::
~LShift Up:: CheckHideMarker()
#If isAhkSpy && WinActive("ahk_id" hGui)

^WheelUp::
^WheelDown::
	FontSize := InStr(A_ThisHotkey, "Up") ? ++FontSize : --FontSize
	FontSize := FontSize < 10 ? 10 : FontSize > 24 ? 24 : FontSize
	oBody.Style.fontSize := FontSize "px"
	TitleText("FontSize: " FontSize)
	If MemoryFontSize
		IniWrite(FontSize, "FontSize")
	Return

F1::
+WheelUp:: NextLink("-")

F2::
+WheelDown:: NextLink()

F3::
~!WheelUp:: WheelLeft

F4::
~!WheelDown:: WheelRight

F5:: Write_%ThisMode%()		;  Return original HTML

F6:: AppsKey

F12::
F7:: ShowSys(5, 5)

!Space:: SetTimer, ShowSys, -1

Esc::
	If isFindView
		FindHide()
	Else If FullScreenMode
		FullScreenMode()
	Else
		GoSub, Exit
	Return

+#Tab:: AhkSpyZoomShow()

F8::
^vk46:: FindView()											;  Ctrl+F

F11:: FullScreenMode()

#If isAhkSpy && WinActive("ahk_id" hGui) && IsIEFocus()

^vk5A:: oDoc.execCommand("Undo")							;  Ctrl+Z

^vk59:: oDoc.execCommand("Redo")							;  Ctrl+Y

#If isAhkSpy && WinActive("ahk_id" hGui) && IsIEFocus() && (oDoc.selection.createRange().parentElement.isContentEditable)

^vk43:: Clipboard := oDoc.selection.createRange().text		;  Ctrl+C

^vk56:: oDoc.execCommand("Paste")							;  Ctrl+V

~^vk41:: oDoc.execCommand("SelectAll")						;  Ctrl+A

^vk58:: oDoc.execCommand("Cut")								;  Ctrl+X

Del:: oDoc.execCommand("Delete")							;  Delete

Enter:: oDoc.selection.createRange().pasteHTML("<br>")  ; oDoc.selection.createRange().text := "`r`n"

Tab:: oDoc.selection.createRange().text := "    "			;  &emsp

#If isAhkSpy && WinActive("ahk_id" hGui) && !Hotkey_Arr("Hook") && IsIEFocus()

#RButton:: ClipPaste()

#If (isAhkSpy && Sleep != 1 && ThisMode != "Hotkey" && oMS.ELSel) && (oMS.ELSel.OuterText != "" || MS_Cancel())

RButton::
^RButton::
	ToolTip("copy", 300)
	CopyText := oMS.ELSel.OuterText
	If (A_ThisHotkey = "^RButton")
		CopyText := CopyCommaParam(CopyText)
	Clipboard := CopyText 
	Return

+RButton:: ClipAdd(CopyText := oMS.ELSel.OuterText, 1) 
^+RButton:: ClipAdd(CopyText := CopyCommaParam(oMS.ELSel.OuterText), 1) 

#If (isAhkSpy && Sleep != 1 && oMS.ELSel) && (oMS.ELSel.OuterText != "" || MS_Cancel())  ;	Mode = Hotkey

RButton::
	CopyText := oMS.ELSel.OuterText
	KeyWait, RButton, T0.3
	If ErrorLevel
		ClipAdd(CopyText, 1)
	Else
		Clipboard := CopyText, ToolTip("copy", 300) 
	Return

#If isAhkSpy && WinActive("ahk_id" hGui) && ExistSelectedText(CopyText)

^RButton::
RButton::
CopyText:
	ToolTip("copy", 300)
	If (A_ThisHotkey = "^RButton")
		CopyText := CopyCommaParam(CopyText)
	Clipboard := CopyText 
	Return

+RButton:: ClipAdd(CopyText, 1) 
^+RButton:: ClipAdd(CopyText := CopyCommaParam(CopyText), 1) 

#If (isAhkSpy && Sleep != 1 && !isPaused && !DllCall("IsWindowVisible", "Ptr", oOther.hZoom))

+#Up::MouseStep(0, -1)
+#Down::MouseStep(0, 1)
+#Left::MouseStep(-1, 0)
+#Right::MouseStep(1, 0)

#If

	; _________________________________________________ Mode_Win _________________________________________________

Mode_Win:
	If A_GuiControl
		GuiControl, 1:Focus, oDoc
	oBody.createTextRange().execCommand("RemoveFormat")
	GuiControl, TB: -0x0001, But1
	If ThisMode = Win
		oDocEl.scrollLeft := 0
	If (ThisMode = "Hotkey")
		Hotkey_Hook(0)
	Try SetTimer, Loop_%ThisMode%, Off
	ScrollPos[ThisMode,1] := oDocEl.scrollLeft, ScrollPos[ThisMode,2] := oDocEl.scrollTop
	If ThisMode != Win
		HTML_%ThisMode% := oBody.innerHTML
	ThisMode := "Win"
	If (HTML_Win = "")
		Spot_Win(1)
	TitleText := (TitleTextP1 := "AhkSpy - Window") . TitleTextP2
	SendMessage, 0xC, 0, &TitleText, , ahk_id %hGui%
	Write_Win(), oDocEl.scrollLeft := ScrollPos[ThisMode,1], oDocEl.scrollTop := ScrollPos[ThisMode,2]
	If isFindView
		FindSearch(1)

Loop_Win:
	If ((WinActive("ahk_id" hGui) && !ActiveNoPause) || Sleep = 1)
		GoTo Repeat_Loop_Win
	If Spot_Win()
		Write_Win(), StateAllwaysSpot ? Spot_Control() : 0
Repeat_Loop_Win:
	If !isPaused
		SetTimer, Loop_Win, -%RangeTimer%
	Return

Spot_Win(NotHTML = 0) {
	Static PrWinPID, ComLine, WinProcessPath, ProcessBitSize, WinProcessName
	If NotHTML
		GoTo HTML_Win
	MouseGetPos,,,WinID
	If (WinID = hGui || WinID = oOther.hZoom)
		Return HideMarker(), HideAccMarker()
	WinGetTitle, WinTitle, ahk_id %WinID%
	WinTitle := TransformHTML(WinTitle)
	WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_id %WinID%
	WinX2 := WinX + WinWidth, WinY2 := WinY + WinHeight
	WinGetClass, WinClass, ahk_id %WinID%
	WinGet, WinPID, PID, ahk_id %WinID%
	If (WinPID != PrWinPID) {
		GetCommandLineProc(WinPID, ComLine, ProcessBitSize)
		ComLine := TransformHTML(ComLine), PrWinPID := WinPID
		WinGet, WinProcessPath, ProcessPath, ahk_pid %WinPID%
		Loop, %WinProcessPath%
			WinProcessPath = %A_LoopFileLongPath%
		SplitPath, WinProcessPath, WinProcessName
	}
	If (WinClass ~= "(Cabinet|Explore)WClass")
		CLSID := GetCLSIDExplorer(WinID)
	WinGet, WinCountProcess, Count, ahk_pid %WinPID%
	WinGet, WinStyle, Style, ahk_id %WinID%
	WinGet, WinExStyle, ExStyle, ahk_id %WinID%
	WinGet, WinTransparent, Transparent, ahk_id %WinID%
	If WinTransparent !=
		WinTransparent := "`n<span class='param'>Transparent:  </span><span name='MS:'>"  WinTransparent "</span>"
	WinGet, WinTransColor, TransColor, ahk_id %WinID%
	If WinTransColor !=
		WinTransColor := (WinTransparent = "" ? "`n" : DP) "<span class='param'>TransColor:  </span><span name='MS:'>" WinTransColor "</span>"
	WinGet, CountControl, ControlListHwnd, ahk_id %WinID%
	RegExReplace(CountControl, "m`a)$", "", CountControl)
	GetClientPos(WinID, caX, caY, caW, caH)
	caWinRight := WinWidth - caW - caX , caWinBottom := WinHeight - caH - caY
	loop 1000
	{
		StatusBarGetText, SBFieldText, %A_Index%, ahk_id %WinID%
		if ErrorLevel
			Break
		(!sb_fields && sb_fields := []), sb_fields[A_Index] := SBFieldText
	}
	if sb_fields.maxindex()
	{
		while (sb_max := sb_fields.maxindex()) && (sb_fields[sb_max] = "")
			sb_fields.Delete(sb_max)
		for k, v in sb_fields 
			SBText .= "<span class='param'>(" k "):</span> <span name='MS:' id='sb_field_" A_Index "'>" TransformHTML(v "`n") "</span>"
		If SBText !=
			SBText := _T1 "( StatusBarText ) </span>" _BT1 " id='copy_sbtext' name='" sb_max "'> copy " _BT2 _T2 _PRE1 "<span>" SBText "</span></span>" _PRE2
	} 
	DetectHiddenText, % DetectHiddenText
	WinGetText, WinText, ahk_id %WinID%
	If WinText !=
		WinText := _T1 " ( Window Text ) </span><a></a>" _BT1 " id='copy_wintext'> copy " _BT2 _DB _BT1 " id='wintext_hidden'> hidden - " DetectHiddenText " " _BT2 _T2
		. _LPRE  "><pre id='wintextcon'>" TransformHTML(WinText) "</pre>" _PRE2
	MenuText := GetMenu(WinID)  
	CoordMode, Mouse
	MouseGetPos, WinXS, WinYS
	PixelGetColor, ColorRGB, %WinXS%, %WinYS%, RGB
	GuiControl, TB: -Redraw, ColorProgress
	GuiControl, % "TB: +c" SubStr(ColorRGB, 3), ColorProgress
	GuiControl, TB: +Redraw, ColorProgress
	
HTML_Win:
	If w_ShowStyles
		WinStyles := GetStyles(WinStyle, WinExStyle)
	ButtonStyle_ := w_ShowStyles ? "show styles" : "hide styles"

	HTML_Win =
	( Ltrim
	<body id='body'>
	%_T1% ( Title ) </span>%_BT1% id='pause_button'> pause %_BT2%%_DB%%_DB%%_BT1% id='run_zoom'> zoom %_BT2%%_T2%%_BR%
	%_PRE1%<span id='wintitle1' name='MS:'>%WinTitle%</span>%_PRE2%
	%_T1% ( Class ) </span>%_T2%
	%_PRE1%<span id='wintitle2'><span class='param' id='wintitle2_' name='MS:S'>ahk_class </span><span name='MS:'>%WinClass%</span></span>%_PRE2%
	%_T1% ( ProcessName ) </span>%_BT1% id='copy_alltitle'> copy titles %_BT2%%_T2%
	%_PRE1%<span id='wintitle3'><span class='param' name='MS:S' id='wintitle3_'>ahk_exe </span><span name='MS:'>%WinProcessName%</span></span>%_PRE2%
	%_T1% ( ProcessPath ) </span>%_BT1% id='infolder'> in folder %_BT2%%_DB%%_BT1% id='paste_process_path'> paste %_BT2%%_T2%
	%_PRE1%<span><span class='param' name='MS:S'>ahk_exe </span><span id='copy_processpath' name='MS:'>%WinProcessPath%</span></span>%_PRE2%
	%_T1% ( CommandLine ) </span>%_BT1% id='w_command_line'> launch %_BT2%%_DB%%_BT1% id='paste_command_line'> paste %_BT2%%_T2%
	%_PRE1%<span id='c_command_line' name='MS:'>%ComLine%</span>%_PRE2%
	%_T1% ( Position ) </span>%_T2%
	%_PRE1%%_BP1% id='set_button_pos'>Pos:%_BP2%  <span name='MS:'>x%WinX% y%WinY%</span>%_DP%<span name='MS:'>x&sup2;%WinX2% y&sup2;%WinY2%</span>%_DP%%_BP1% id='set_button_pos'>Size:%_BP2%  <span name='MS:'>w%WinWidth% h%WinHeight%</span>%_DP%<span name='MS:'>%WinX%, %WinY%, %WinX2%, %WinY2%</span>%_DP%<span name='MS:'>%WinX%, %WinY%, %WinWidth%, %WinHeight%</span>
	<span class='param'>Client area size:</span>  <span name='MS:'>w%caW% h%caH%</span>%_DP%<span class='param'>left</span> %caX% <span class='param'>top</span> %caY% <span class='param'>right</span> %caWinRight% <span class='param'>bottom</span> %caWinBottom%%_PRE2%
	%_T1% ( Other ) </span>%_T2%
	%_PRE1%<span class='param' name='MS:N'>PID:</span>  <span name='MS:'>%WinPID%</span>%_DP%%ProcessBitSize%<span class='param'>Window count:</span> %WinCountProcess%%_DP%%_BB1% id='process_close'> process close %_BB2%
	<span class='param' name='MS:N'>HWND:</span>  <span name='MS:'>%WinID%</span>%_DP%%_BB1% id='win_close'> win close %_BB2%%_DP%<span class='param'>Control count:</span>  %CountControl%
	<span class='param'>Style:  </span><span id='c_Style' name='MS:'>%WinStyle%</span>%_DP%<span class='param'>ExStyle:  </span><span id='c_ExStyle' name='MS:'>%WinExStyle%</span>%_DP%%_BB1% id='get_styles'> %ButtonStyle_% %_BB2%%WinTransparent%%WinTransColor%%CLSID%%_PRE2%
	<span id=WinStyles>%WinStyles%</span>%SBText%%WinText%%MenuText%<a></a>%_T0%
	</body>

	<style>
	* {
		margin: 0;
		background: none;
		font-family: %FontFamily%;
		font-weight: 500;
	}
	body {
		margin: 0.3em;
		background-color: #%ColorBg%;
		font-size: %FontSize%px; 
	}
	.br {
		height:0.1em;
	}
	.box {
		position: absolute; 
		overflow: hidden;
		width: 100`%;
		height: 1.5em;
		background: transparent;
		left: 0px;
	}
	.hr {
		position: absolute;
		width: 100`%;
		border-bottom: 0.2em dashed red;
		height: 0.5em;
	}
	.line {
		position: absolute;
		width: 100`%;
		top: 1px;
	}
	.con {
		position: absolute;
		left: 30`%;
	}
	.title {
		margin-right: 50px;
		white-space: pre;
		color: #%ColorTitle%; 
	}
	pre {
		margin-bottom: 0.1em;
		margin-top: 0.1em;
		line-height: 1.3em;
	}
	.button {
		position: relative;
		border: 1px dotted;
		border-color: black;
		white-space: pre;
		cursor: hand; 
	}
	.BB {
		display: inline-block;
	}
	.param {
		color: #%ColorParam%;
	}
	.titleparam {
		color: #%ColorTitle%;
	}
	</style>
	)
	oOther.WinPID := WinPID
	oOther.WinID := WinID
	If StateLightMarker && (ThisMode = "Win") && (StateLight = 1 || (StateLight = 3 && GetKeyState("Shift", "P")))
		ShowMarker(WinX, WinY, WinWidth, WinHeight, 5)
	Return 1
}

Write_Win() {
	oBody.innerHTML := HTML_Win  
	If oDocEl.scrollLeft
		oDocEl.scrollLeft := 0
	Return 1
}

	; _________________________________________________ Mode_Control _________________________________________________

Mode_Control:
	If A_GuiControl
		GuiControl, 1:Focus, oDoc
	oBody.createTextRange().execCommand("RemoveFormat")
	GuiControl, TB: -0x0001, But2
	If (ThisMode = "Hotkey")
		Hotkey_Hook(0)
	If ThisMode = Control
		oDocEl.scrollLeft := 0
	Try SetTimer, Loop_%ThisMode%, Off
	ScrollPos[ThisMode,1] := oDocEl.scrollLeft, ScrollPos[ThisMode,2] := oDocEl.scrollTop
	If ThisMode != Control
		HTML_%ThisMode% := oBody.innerHTML
	ThisMode := "Control"
	If (HTML_Control = "")
		Spot_Control(1)
	TitleText := (TitleTextP1 := "AhkSpy - Control") . TitleTextP2
	SendMessage, 0xC, 0, &TitleText, , ahk_id %hGui%
	Write_Control(), oDocEl.scrollLeft := ScrollPos[ThisMode,1], oDocEl.scrollTop := ScrollPos[ThisMode,2]
	If isFindView
		FindSearch(1)

Loop_Control:
	If (WinActive("ahk_id" hGui) && !ActiveNoPause) || Sleep = 1
		GoTo Repeat_Loop_Control
	If Spot_Control()
		Write_Control(), StateAllwaysSpot ? Spot_Win() : 0
Repeat_Loop_Control:
	If !isPaused
		SetTimer, Loop_Control, -%RangeTimer%
	Return

Spot_Control(NotHTML = 0) {
	If NotHTML
		GoTo HTML_Control
	WinGet, ProcessName_A, ProcessName, A
	WinGet, HWND_A, ID, A
	WinGetClass, WinClass_A, A
	CoordMode, Mouse
	MouseGetPos, MXS, MYS, WinID, tControlNN
	CoordMode, Mouse, Window
	MouseGetPos, MXWA, MYWA, , tControlID, 2
	If (WinID = hGui || WinID = oOther.hZoom)
		Return HideMarker(), HideAccMarker()
	CtrlInfo := "", isIE := 0
	ControlNN := tControlNN, ControlID := tControlID
	WinGetPos, WinX, WinY, WinW, WinH, ahk_id %WinID%
	RWinX := MXS - WinX, RWinY := MYS - WinY
	GetClientPos(WinID, caX, caY, caW, caH)
	MXC := RWinX - caX, MYC := RWinY - caY
	PixelGetColor, ColorBGR, %MXS%, %MYS%
	ColorRGB := Format("0x{:06X}", (ColorBGR & 0xFF) << 16 | (ColorBGR & 0xFF00) | (ColorBGR >> 16))
	sColorBGR := SubStr(ColorBGR, 3)
	sColorRGB := SubStr(ColorRGB, 3)
	GuiControl, TB: -Redraw, ColorProgress
	GuiControl, % "TB: +c" sColorRGB, ColorProgress
	GuiControl, TB: +Redraw, ColorProgress 
	WithRespectWin := "`n" _BP1 " id='set_pos'>Relative window:" _BP2 "  <span name='MS:'>"
	. Round(RWinX / WinW, 4) ", " Round(RWinY / WinH, 4) "</span>  <span class='param'>for</span> <span name='MS:'>w" WinW " h" WinH "</span>" _DP
	ControlGetPos, CtrlX, CtrlY, CtrlW, CtrlH,, ahk_id %ControlID%
	CtrlCAX := CtrlX - caX, CtrlCAY := CtrlY - caY
	CtrlX2 := CtrlX+CtrlW, CtrlY2 := CtrlY+CtrlH
	CtrlCAX2 := CtrlX2-caX, CtrlCAY2 := CtrlY2-caY
	WithRespectClient := _BP1 " id='set_pos'>Relative client:" _BP2 "  <span name='MS:'>" Round(MXC / caW, 4) ", " Round(MYC / caH, 4)
		. "</span>  <span class='param'>for</span> <span name='MS:'>w" caW " h" caH "</span>"
	ControlGetText, CtrlText, , ahk_id %ControlID%
	If CtrlText != 
		CtrlText := _T1 " ( Control Text ) </span><a></a>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(CtrlText) _PRE2 
	AccText := AccInfoUnderMouse(MXS, MYS, WinX, WinY, CtrlX, CtrlY)
	If AccText != 
		AccText := _T1 " ( AccInfo ) </span><a></a>" _ButAccViewer _T2 AccText
		
	If ControlNN !=
	{
		rmCtrlX := MXS - WinX - CtrlX, rmCtrlY := MYS - WinY - CtrlY
		ControlNN_Sub := RegExReplace(ControlNN, "S)\d+| ")
		If IsFunc("GetInfo_" ControlNN_Sub)
		{
			CtrlInfo := GetInfo_%ControlNN_Sub%(ControlID, ClassName)
			If CtrlInfo !=
			{
				If isIE
					CtrlInfo = %_T1% ( Info - %ClassName% ) </span><a></a>%_ButiWB2Learner%%_T2%%CtrlInfo%
				Else
					CtrlInfo = %_T1% ( Info - %ClassName% ) </span><a></a>%_T2%%_PRE1%%CtrlInfo%%_PRE2%
			}
		}
		WithRespectControl := _DP "<span name='MS:'>" Round(rmCtrlX / CtrlW, 4) ", " Round(rmCtrlY / CtrlH, 4) "</span>"
	}
	Else
		rmCtrlX := rmCtrlY := ""
	If (!isIE && ThisMode = "Control" && (StateLight = 1 || (StateLight = 3 && GetKeyState("Shift", "P"))))
	{
		StateLightMarker ? ShowMarker(WinX+CtrlX, WinY+CtrlY, CtrlW, CtrlH) : 0
		StateLightAcc ? ShowAccMarker(AccCoord[1], AccCoord[2], AccCoord[3], AccCoord[4]) : 0
	}
	ControlGet, CtrlStyle, Style,,, ahk_id %ControlID%
	ControlGet, CtrlExStyle, ExStyle,,, ahk_id %ControlID%
	WinGetClass, CtrlClass, ahk_id %ControlID%
	ControlGetFocus, CtrlFocus, ahk_id %WinID%
	WinGet, ProcessName, ProcessName, ahk_id %WinID%
	WinGetClass, WinClass, ahk_id %WinID%

HTML_Control:
	HTML_Control =
	( Ltrim
	<body id='body'>
	%_T1% ( Mouse ) </span>%_BT1% id='pause_button'> pause %_BT2%%_DB%%_DB%%_BT1% id='run_zoom'> zoom %_BT2%%_T2%%_BR%
	%_PRE1%%_BP1% id='set_pos'>Screen:%_BP2%  <span name='MS:'>x%MXS% y%MYS%</span>%_DP%%_BP1% id='set_pos'>Window:%_BP2%  <span name='MS:'>x%RWinX% y%RWinY%</span>%_DP%%_BP1% id='set_pos'>Client:%_BP2%  <span name='MS:'>x%MXC% y%MYC%</span>%WithRespectWin%%WithRespectClient%
	<span class='param'>Relative active window:</span>  <span name='MS:'>x%MXWA% y%MYWA%</span>%_DP%<span class='param'>exe</span> <span name='MS:'>%ProcessName_A%</span> <span class='param'>class</span> <span name='MS:'>%WinClass_A%</span> <span class='param'>hwnd</span> <span name='MS:'>%HWND_A%</span>%_PRE2%
	%_T1% ( PixelGetColor ) </span>%_T2%
	%_PRE1%<span class='param'>RGB: </span> <span name='MS:'>%ColorRGB%</span>%_DP%<span name='MS:'>#%sColorRGB%</span>%_DP%<span class='param'>BGR: </span> <span name='MS:'>%ColorBGR%</span>%_DP%<span name='MS:'>#%sColorBGR%</span>%_PRE2%
	%_T1% ( Window ) </span>%_T2%
	%_PRE1%<span><span class='param' name='MS:S'>ahk_class</span> <span name='MS:'>%WinClass%</span></span> <span><span class='param' name='MS:S'>ahk_exe</span> <span name='MS:'>%ProcessName%</span></span> <span><span class='param' name='MS:S'>ahk_id</span> <span name='MS:'>%WinID%</span></span>%_PRE2%
	%_T1% ( Control ) </span>%_T2%
	%_PRE1%<span class='param'>Class NN:</span>  <span name='MS:'>%ControlNN%</span>%_DP%<span class='param'>Win class:</span>  <span name='MS:'>%CtrlClass%</span>
	%_BP1% id='set_button_pos'>Pos:%_BP2%  <span name='MS:'>x%CtrlX% y%CtrlY%</span>%_DP%<span name='MS:'>x&sup2;%CtrlX2% y&sup2;%CtrlY2%</span>%_DP%%_BP1% id='set_button_pos'>Size:%_BP2%  <span name='MS:'>w%CtrlW% h%CtrlH%</span>%_DP%<span name='MS:'>%CtrlX%, %CtrlY%, %CtrlX2%, %CtrlY2%</span>%_DP%<span name='MS:'>%CtrlX%, %CtrlY%, %CtrlW%, %CtrlH%</span>
	<span class='param'>Pos relative client area:</span>  <span name='MS:'>x%CtrlCAX% y%CtrlCAY%</span>%_DP%<span name='MS:'>x&sup2;%CtrlCAX2% y&sup2;%CtrlCAY2%</span>%_DP%<span name='MS:'>%CtrlCAX%, %CtrlCAY%, %CtrlCAX2%, %CtrlCAY2%</span>%_DP%<span name='MS:'>%CtrlCAX%, %CtrlCAY%, %CtrlW%, %CtrlH%</span>
	%_BP1% id='set_pos'>Mouse relative control:%_BP2%  <span name='MS:'>x%rmCtrlX% y%rmCtrlY%</span>%WithRespectControl%%_DP%<span class='param'>Client area:</span>  <span name='MS:'>x%caX% y%caY% w%caW% h%caH%</span>
	<span class='param'>HWND:</span>  <span name='MS:'>%ControlID%</span>%_DP%<span class='param'>Style:</span>  <span name='MS:'>%CtrlStyle%</span>%_DP%<span class='param'>ExStyle:</span>  <span name='MS:'>%CtrlExStyle%</span>
	%_BP1% id='set_button_focus_ctrl'>Focus control:%_BP2%  <span name='MS:'>%CtrlFocus%</span>%_DP%<span class='param'>Cursor type:</span>  <span name='MS:'>%A_Cursor%</span>%_DP%<span class='param'>Caret pos:</span>  <span name='MS:'>x%A_CaretX% y%A_CaretY%</span>%_PRE2%
	%CtrlInfo%%CtrlText%%AccText%
	<a></a>%_T0%
	</body>
	
	<style>
	* {
		margin: 0;
		background: none;
		font-family: %FontFamily%;
		font-weight: 500;
	}
	body {
		margin: 0.3em;
		background-color: #%ColorBg%;
		font-size: %FontSize%px; 
	}
	.br {
		height:0.1em;
	}
	.box {
		position: absolute; 
		overflow: hidden;
		width: 100`%;
		height: 1.5em;
		background: transparent;
		left: 0px;
	}
	.line {
		position: absolute;
		width: 100`%;
		top: 1px;
	}
	.con {
		position: absolute;
		left: 30`%;
	}
	.title {
		margin-right: 50px;
		white-space: pre;
		color: #%ColorTitle%; 
	}
	.hr {
		position: absolute;
		width: 100`%;
		border-bottom: 0.2em dashed red;
		height: 0.5em;
	}
	pre {
		margin-bottom: 0.1em;
		margin-top: 0.1em;
		line-height: 1.3em;
	}
	.button {
		position: relative;
		border: 1px dotted;
		border-color: black;
		white-space: pre;
		cursor: hand; 
	}
	.BB {
		display: inline-block;
	}
	.param {
		color: #%ColorParam%;
	}
	</style>
	)
	oOther.MouseControlID := ControlID
	oOther.MouseWinID := WinID
	Return 1
}

Write_Control() {
	oBody.innerHTML := HTML_Control
	If oDocEl.scrollLeft
		oDocEl.scrollLeft := 0
	Return 1
}

	; _________________________________________________ Get Menu _________________________________________________

GetMenu(hWnd) {
	; Static prhWnd, MenuText
	; If (hWnd = prhWnd)
		; Return MenuText
	; prhWnd := hWnd
	SendMessage, 0x1E1, 0, 0, , ahk_id %hWnd%	;  MN_GETHMENU
	hMenu := ErrorLevel
	If !hMenu || (hMenu + 0 = "")
		Return 
	Return _T1 " ( Menu text ) </span>" _BT1 " id='copy_menutext'> copy " _BT2 _DB 
	. _BT1 " id='menu_idview'> id - " (MenuIdView ? "view" : "hide") " " _BT2 _T2 _LPRE " id='pre_menutext'>" RTrim(GetMenuText(hMenu), "`n")  _PRE2
}

GetMenuText(hMenu, child = 0)
{ 
	Loop, % DllCall("GetMenuItemCount", "Ptr", hMenu)
	{ 
		idx := A_Index - 1
		nSize++ := DllCall("GetMenuString", "Ptr", hMenu, "int", idx, "Uint", 0, "int", 0, "Uint", 0x400)   ;  MF_BYPOSITION
		nSize := (nSize * (A_IsUnicode ? 2 : 1)) 
		VarSetCapacity(sString, nSize)
		DllCall("GetMenuString", "Ptr", hMenu, "int", idx, "str", sString, "int", nSize, "Uint", 0x400)   ;  MF_BYPOSITION
		sString := TransformHTML(sString)
		idn := DllCall("GetMenuItemID", "Ptr", hMenu, "int", idx)
		IdItem := "<span class='param menuitemid' style='display: " (!MenuIdView ? "none" : "inline") ";'>`t`t`t<span name='MS:'>" idn "</span></span>"
		isSubMenu := (idn = -1) && (hSubMenu := DllCall("GetSubMenu", "Ptr", hMenu, "int", idx)) ? 1 : 0
		If isSubMenu
			sContents .= AddTab(child) "<span class='param'>" idx + 1 ":  </span><span name='MS:' class='titleparam'>" sString "</span><span class='param menuitemsub';'>&#8595;</span>" IdItem "`n" 
		Else If (sString = "")
			sContents .= AddTab(child) "<span class='param'>" idx + 1 ":  &#8212; &#8212; &#8212; &#8212; &#8212; &#8212; &#8212;</span>" IdItem "`n" 
		Else
			sContents .= AddTab(child) "<span class='param'>" idx + 1 ":  </span><span name='MS:'>" sString "</span>" IdItem "`n" 
		If isSubMenu
			sContents .= GetMenuText(hSubMenu, ++child), --child 
	} 
	Return sContents 
} 

AddTab(c) {
	loop % c
		Tab .= "<span class='param';'>&#8595;`t</span>"
	Return  Tab  
}

	; _________________________________________________ Get Info Control _________________________________________________

GetInfo_SysListView(hwnd, ByRef ClassNN) {
	ClassNN := "SysListView32"
	ControlGet, ListText, List,,, ahk_id %hwnd%
	ControlGet, RowCount, List, Count,, ahk_id %hwnd%
	ControlGet, ColCount, List, Count Col,, ahk_id %hwnd%
	ControlGet, SelectedCount, List, Count Selected,, ahk_id %hwnd%
	ControlGet, FocusedCount, List, Count Focused,, ahk_id %hwnd%
	Return	"<span class='param' name='MS:N'>Row count:</span> <span name='MS:'>" RowCount "</span>" _DP
			. "<span class='param' name='MS:N'>Column count:</span> <span name='MS:'>" ColCount "</span>`n"
			. "<span class='param' name='MS:N'>Selected count:</span> <span name='MS:'>" SelectedCount "</span>" _DP
			. "<span class='param' name='MS:N'>Focused row:</span> <span name='MS:'>" FocusedCount "</span>" _PRE2
			. _T1 " ( Content ) </span>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(ListText) 
}

GetInfo_SysTreeView(hwnd, ByRef ClassNN) {
	ClassNN := "SysTreeView32"
	SendMessage 0x1105, 0, 0, , ahk_id %hwnd%   ; TVM_GETCOUNT
	ItemCount := ErrorLevel
	Return	"<span class='param' name='MS:N'>Item count:</span> <span name='MS:'>" ItemCount "</span>"
}

GetInfo_ListBox(hwnd, ByRef ClassNN) {
	ClassNN = ListBox 
	Return GetInfo_ComboBox(hwnd, "", 1)
}
GetInfo_TListBox(hwnd, ByRef ClassNN) {
	ClassNN = TListBox
	Return GetInfo_ComboBox(hwnd, "", 1)
}
GetInfo_TComboBox(hwnd, ByRef ClassNN) {
	ClassNN = TComboBox
	Return GetInfo_ComboBox(hwnd, "")
}
GetInfo_ComboBox(hwnd, ByRef ClassNN, ListBox = 0) {
	ClassNN = ComboBox
	ControlGet, ListText, List,,, ahk_id %hwnd%
	SendMessage, (ListBox ? 0x188 : 0x147), 0, 0, , ahk_id %hwnd%   ; 0x188 - LB_GETCURSEL, 0x147 - CB_GETCURSEL
	SelPos := ErrorLevel
	SelPos := SelPos = 0xffffffff || SelPos < 0 ? "NoSelect" : SelPos + 1
	RegExReplace(ListText, "m`a)$", "", RowCount)
	Return	"<span class='param' name='MS:N'>Row count:</span> <span name='MS:'>" RowCount "</span>" _DP
			. "<span class='param' name='MS:N'>Row selected:</span> <span name='MS:'>" SelPos "</span>" _PRE2
			. _T1 " ( Content ) </span>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(ListText) 
}

GetInfo_CtrlNotifySink(hwnd, ByRef ClassNN) {
	ClassNN = CtrlNotifySink
	Return GetInfo_Scintilla(hwnd, "")
}

	;  http://forum.script-coding.com/viewtopic.php?pid=117128#p117128
	;  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645478(v=vs.85).aspx

GetInfo_Edit(hwnd, ByRef ClassNN) {
	ClassNN = Edit
	Return GetInfo_Scintilla(hwnd, "") "`n<span class='param' name='MS:N'>DlgCtrlID:</span> <span name='MS:'>" DllCall("GetDlgCtrlID", Ptr, hwnd) "</span>"
}

GetInfo_Scintilla(hwnd, ByRef ClassNN) {
	ClassNN = Scintilla
	ControlGet, LineCount, LineCount,,, ahk_id %hwnd%
	ControlGet, CurrentCol, CurrentCol,,, ahk_id %hwnd%
	ControlGet, CurrentLine, CurrentLine,,, ahk_id %hwnd%
	ControlGet, Selected, Selected,,, ahk_id %hwnd%
	SendMessage, 0x00B0, , , , ahk_id %hwnd%			;  EM_GETSEL
	EM_GETSEL := ErrorLevel >> 16
	SendMessage, 0x00CE, , , , ahk_id %hwnd%			;  EM_GETFIRSTVISIBLELINE
	EM_GETFIRSTVISIBLELINE := ErrorLevel + 1
	; Control_GetFont(hwnd, FName, FSize)
	Return	"<span class='param' name='MS:N'>Row count:</span> <span name='MS:'>" LineCount "</span>" _DP
			. "<span class='param' name='MS:N'>Selected length:</span> <span name='MS:'>" StrLen(Selected) "</span>"
			. "`n<span class='param' name='MS:N'>Current row:</span> <span name='MS:'>" CurrentLine "</span>" _DP
			. "<span class='param' name='MS:N'>Current column:</span> <span name='MS:'>" CurrentCol "</span>"
			. "`n<span class='param' name='MS:N'>Current select:</span> <span name='MS:'>" EM_GETSEL "</span>" _DP
			. "<span class='param' name='MS:N'>First visible line:</span> <span name='MS:'>" EM_GETFIRSTVISIBLELINE "</span>"
			; . "`n<span class='param'>FontSize:</span> " FSize _DP "<span class='param'>FontName:</span> " FName
}

Control_GetFont(hwnd, byref FontName, byref FontSize) {
	SendMessage 0x31, 0, 0, , ahk_id %hwnd% ; WM_GETFONT
	IfEqual, ErrorLevel, FAIL, Return
	hFont := Errorlevel, VarSetCapacity(LF, szLF := 60 * (A_IsUnicode ? 2 : 1))
	DllCall("GetObject", UInt, hFont, Int, szLF, UInt, &LF)
	hDC := DllCall("GetDC", UInt,hwnd ), DPI := DllCall("GetDeviceCaps", UInt, hDC, Int, 90)
	DllCall("ReleaseDC", Int, 0, UInt, hDC), S := Round((-NumGet(LF, 0, "Int") * 72) / DPI)
	FontName := DllCall("MulDiv", Int, &LF + 28, Int, 1, Int, 1, Str)
	DllCall("SetLastError", UInt, S), FontSize := A_LastError
}

GetInfo_msctls_progress(hwnd, ByRef ClassNN) {
	ClassNN := "msctls_progress32"
	SendMessage, 0x0400+7,"TRUE",,, ahk_id %hwnd%	;  PBM_GETRANGE
	PBM_GETRANGEMIN := ErrorLevel
	SendMessage, 0x0400+7,,,, ahk_id %hwnd%			;  PBM_GETRANGE
	PBM_GETRANGEMAX := ErrorLevel
	SendMessage, 0x0400+8,,,, ahk_id %hwnd%			;  PBM_GETPOS
	PBM_GETPOS := ErrorLevel
	Return	"<span class='param' name='MS:N'>Level:</span> <span name='MS:'>" PBM_GETPOS "</span>" _DP
			. "<span class='param'>Range:  </span><span class='param' name='MS:N'>Min: </span><span name='MS:'>" PBM_GETRANGEMIN "</span>"
			. "  <span class='param' name='MS:N'>Max:</span> <span name='MS:'>" PBM_GETRANGEMAX "</span>"
}

GetInfo_msctls_trackbar(hwnd, ByRef ClassNN) {
	ClassNN := "msctls_trackbar32"
	SendMessage, 0x0400+1,,,, ahk_id %hwnd%			;  TBM_GETRANGEMIN
	TBM_GETRANGEMIN := ErrorLevel
	SendMessage, 0x0400+2,,,, ahk_id %hwnd%			;  TBM_GETRANGEMAX
	TBM_GETRANGEMAX := ErrorLevel
	SendMessage, 0x0400,,,, ahk_id %hwnd%			;  TBM_GETPOS
	TBM_GETPOS := ErrorLevel
	ControlGet, CtrlStyle, Style,,, ahk_id %hwnd%
	(!(CtrlStyle & 0x0200)) ? (TBS_REVERSED := "No")
	: (TBM_GETPOS := TBM_GETRANGEMAX - (TBM_GETPOS - TBM_GETRANGEMIN), TBS_REVERSED := "Yes")
	Return	"<span class='param' name='MS:N'>Level:</span> <span name='MS:'>" TBM_GETPOS "</span>" _DP
			. "<span class='param'>Invert style:</span>" TBS_REVERSED
			. "`n<span class='param'>Range:  </span><span class='param' name='MS:N'>Min: </span><span name='MS:'>" TBM_GETRANGEMIN "</span>" _DP
			. "<span class='param' name='MS:N'>Max:</span> <span name='MS:'>" TBM_GETRANGEMAX "</span>"
}

GetInfo_msctls_updown(hwnd, ByRef ClassNN) {
	ClassNN := "msctls_updown32"
	SendMessage, 0x0400+102,,,, ahk_id %hwnd%		;  UDM_GETRANGE
	UDM_GETRANGE := ErrorLevel
	SendMessage, 0x400+114,,,, ahk_id %hwnd%		;  UDM_GETPOS32
	UDM_GETPOS32 := ErrorLevel
	Return	"<span class='param' name='MS:N'>Level:</span> <span name='MS:'>" UDM_GETPOS32 "</span>" _DP
			. "<span class='param'>Range:  </span><span class='param' name='MS:N'>Min: </span><span name='MS:'>" UDM_GETRANGE >> 16 "</span>"
			. "  <span class='param' name='MS:N'>Max: </span><span name='MS:'>" UDM_GETRANGE & 0xFFFF "</span>"
}

GetInfo_SysTabControl(hwnd, ByRef ClassNN) {
	ClassNN := "SysTabControl32"
	ControlGet, SelTab, Tab,,, ahk_id %hwnd%
	SendMessage, 0x1300+44,,,, ahk_id %hwnd%		;  TCM_GETROWCOUNT
	TCM_GETROWCOUNT := ErrorLevel
	SendMessage, 0x1300+4,,,, ahk_id %hwnd%			;  TCM_GETITEMCOUNT
	TCM_GETITEMCOUNT := ErrorLevel
	Return	"<span class='param' name='MS:N'>Item count:</span> <span name='MS:'>" TCM_GETITEMCOUNT "</span>" _DP
			. "<span class='param' name='MS:N'>Row count:</span> <span name='MS:'>" TCM_GETROWCOUNT "</span>" _DP
			. "<span class='param' name='MS:N'>Selected item:</span> <span name='MS:'>" SelTab "</span>"
}

GetInfo_ToolbarWindow(hwnd, ByRef ClassNN) {
	ClassNN := "ToolbarWindow32"
	SendMessage, 0x0418,,,, ahk_id %hwnd%		;  TB_BUTTONCOUNT
	BUTTONCOUNT := ErrorLevel
	Return	"<span class='param' name='MS:N'>Button count:</span> <span name='MS:'>" BUTTONCOUNT "</span>"
}

	; _________________________________________________ Get Internet Explorer Info _________________________________________________

	;  http://www.autohotkey.com/board/topic/84258-iwb2-learner-iwebbrowser2/

GetInfo_AtlAxWin(hwnd, ByRef ClassNN) {
	ClassNN = AtlAxWin
	Return GetInfo_InternetExplorer_Server(hwnd, "")
}

GetInfo_InternetExplorer_Server(hwnd, ByRef ClassNN) {
	Static IID_IWebBrowserApp := "{0002DF05-0000-0000-C000-000000000046}"
	, ratios := [], IID_IHTMLWindow2 := "{332C4427-26CB-11D0-B483-00C04FD90119}"

	isIE := 1, ClassNN := "Internet Explorer_Server"
	MouseGetPos, , , , hwnd, 3
	If !(pwin := WBGet(hwnd))
		Return
	If !ratios[hwnd]
	{
		ratio := pwin.window.screen.deviceXDPI / pwin.window.screen.logicalXDPI
		Sleep 10 ; при частом запросе deviceXDPI, возвращает пусто
		!ratio && (ratio := 1)
		ratios[hwnd] := ratio
	}
	ratio := ratios[hwnd]
	pelt := pwin.document.elementFromPoint(rmCtrlX / ratio, rmCtrlY / ratio)
	Tag := pelt.TagName
	If (Tag = "IFRAME" || Tag = "FRAME") {
		If pFrame := ComObjQuery(pwin.document.parentWindow.frames[pelt.id], IID_IHTMLWindow2, IID_IHTMLWindow2)
			iFrame := ComObject(9, pFrame, 1)
		Else
			iFrame := ComObj(9, ComObjQuery(pelt.contentWindow, IID_IHTMLWindow2, IID_IHTMLWindow2), 1)
		WB2 := ComObject(9, ComObjQuery(pelt.contentWindow, IID_IWebBrowserApp, IID_IWebBrowserApp), 1)
		If ((Var := WB2.LocationName) != "")
			Frame .= "`n<span class='param' name='MS:N'>Title:  </span><span name='MS:'>" Var "</span>"
		If ((Var := WB2.LocationURL) != "")
			Frame .= "`n<span class='param' name='MS:N'>URL:  </span><span name='MS:'>" Var "</span>"
		If (iFrame.length)
			Frame .= "`n<span class='param' name='MS:N'>Count frames:  </span><span name='MS:'>" iFrame.length "</span>"
		If (Tag != "")
			Frame .= "`n<span class='param' name='MS:N'>TagName:  </span><span name='MS:'>" Tag "</span>"
		If ((Var := pelt.id) != "")
			Frame .= "`n<span class='param' name='MS:N'>ID:  </span><span name='MS:'>" Var "</span>"
		If ((Var := pelt.ClassName) != "")
			Frame .= "`n<span class='param' name='MS:N'>Class:  </span><span name='MS:'>" Var "</span>"
		If ((Var := pelt.sourceIndex) != "")
			Frame .= "`n<span class='param' name='MS:N'>Index:  </span><span name='MS:'>" Var "</span>"
		If ((Var := pelt.name) != "")
			Frame .= "`n<span class='param' name='MS:N'>Name:  </span><span name='MS:'>" TransformHTML(Var) "</span>"

		If ((Var := pelt.OuterHtml) != "")  
			HTML := _T1P " ( Outer HTML ) </span><a></a>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(Var) _PRE2 
		If ((Var := pelt.OuterText) != "")
			Text := _T1P " ( Outer Text ) </span><a></a>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(Var) _PRE2
		If Frame !=
			Frame := _T1 " ( FrameInfo ) </span>" _T2 "<a></a>" _PRE1 Frame _PRE2 HTML Text
			
		_pbrt := pelt.getBoundingClientRect()
		pelt := iFrame.document.elementFromPoint((rmCtrlX / ratio) - _pbrt.left, (rmCtrlY / ratio) - _pbrt.top)
		__pbrt := pelt.getBoundingClientRect(), pbrt := {}
		pbrt.left := __pbrt.left + _pbrt.left, pbrt.right := __pbrt.right + _pbrt.left
		pbrt.top := __pbrt.top + _pbrt.top, pbrt.bottom := __pbrt.bottom + _pbrt.top
	}
	Else
		pbrt := pelt.getBoundingClientRect()

	WB2 := ComObject(9, ComObjQuery(pwin, IID_IWebBrowserApp, IID_IWebBrowserApp), 1)
	
	If ((Location := WB2.LocationName) != "")
		Topic .= "<span class='param' name='MS:N'>Title:  </span><span name='MS:'>" Location "</span>`n"
	If ((URL := WB2.LocationURL) != "")
		Topic .= "<span class='param' name='MS:N'>URL:  </span><span name='MS:'>" URL "</span>"
	If Topic != 
		Topic := _PRE1 Topic _PRE2
		
	If ((Var := pelt.id) != "")
		Info .= "`n<span class='param' name='MS:N'>ID:  </span><span name='MS:'>" Var "</span>"
	If ((Var := pelt.ClassName) != "")
		Info .= "`n<span class='param' name='MS:N'>Class:  </span><span name='MS:'>" Var "</span>"
	If ((Var := pelt.sourceIndex) != "")
		Info .= "`n<span class='param' name='MS:N'>Index:  </span><span name='MS:'>" Var "</span>"
	If ((Var := pelt.name) != "")
		Info .= "`n<span class='param' name='MS:N'>Name:  </span><span name='MS:'>" TransformHTML(Var) "</span>"
		
	If ((Var := pelt.OuterHtml) != "")
		HTML := _T1P " ( Outer HTML ) </span><a></a>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(Var) _PRE2 
	If ((Var := pelt.OuterText) != "")
		Text := _T1P " ( Outer Text ) </span><a></a>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(Var) _PRE2  

	x1 := pbrt.left * ratio, y1 := pbrt.top * ratio
	x2 := pbrt.right * ratio, y2 := pbrt.bottom * ratio
	ObjRelease(pwin), ObjRelease(pelt), ObjRelease(WB2), ObjRelease(iFrame), ObjRelease(pbrt)
	
	If (ThisMode = "Control") && (StateLight = 1 || (StateLight = 3 && GetKeyState("Shift", "P")))
	{
		WinGetPos, sX, sY, , , ahk_id %hwnd%
		StateLightMarker ? ShowMarker(sX + x1, sY + y1, x2 - x1, y2 - y1) : 0
		StateLightAcc ? ShowAccMarker(AccCoord[1], AccCoord[2], AccCoord[3], AccCoord[4]) : 0
	}
	Info := _T1P "<span name='MS:N'> ( Tag name: </span><span name='MS:' style='color: #" ColorFont ";'>"
	. pelt.TagName "</span>" (Frame ? " - (in frame)" : "") " ) </span>" _T2
	. _PRE1  "<span class='param'>Pos: </span><span name='MS:'>x" Round(x1) " y" Round(y1) "</span>"
	. _DP "<span name='MS:'>x&sup2;" Round(x2) " y&sup2;" Round(y2) "</span>"
	. _DP "<span class='param'>Size: </span><span name='MS:'>w" Round(x2 - x1) " h" Round(y2 - y1) "</span>" Info _PRE2

	Return Topic Info HTML Text Frame
}

WBGet(hwnd) {
	Static Msg := DllCall("RegisterWindowMessage", "Str", "WM_HTML_GETOBJECT")
		, IID_IHTMLWindow2 := "{332C4427-26CB-11D0-B483-00C04FD90119}"
	SendMessage, Msg, , , , ahk_id %hwnd%
	DllCall("oleacc\ObjectFromLresult", "Ptr", ErrorLevel, "Ptr", 0, "Ptr", 0, PtrP, pdoc)
	Return ComObj(9, ComObjQuery(pdoc, IID_IHTMLWindow2, IID_IHTMLWindow2), 1), ObjRelease(pdoc)
}

	; _________________________________________________ Get Acc Info _________________________________________________

	;  http://www.autohotkey.com/board/topic/77888-accessible-info-viewer-alpha-release-2012-09-20/

AccInfoUnderMouse(x, y, wx, wy, cx, cy) {
	Static h
	If Not h
		h := DllCall("LoadLibrary","Str","oleacc","Ptr")
	If DllCall("oleacc\AccessibleObjectFromPoint"
		, "Int64", x&0xFFFFFFFF|y<<32, "Ptr*", pacc
		, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild) = 0
	Acc := ComObjEnwrap(9,pacc,1), child := NumGet(varChild,8,"UInt")
	If !IsObject(Acc)
		Return 
	Count := (Var := Acc.accChildCount) != "" ? "<span name='MS:'>" Var "</span>" : "N/A" 
	Var := child ? "Child" _DP "<span class='param' name='MS:N'>Id:  </span><span name='MS:'>" child "</span>"
		. _DP "<span class='param' name='MS:N'>Parent child count:  </span>" Count
		: "Parent" _DP "<span class='param' name='MS:N'>ChildCount:  </span>" Count
	code := _PRE1 "<span class='param'>Type:</span>  " Var _PRE2
	code .= _T1P " ( Position relative ) </span>" _T2 _PRE1 "<span class='param'>Screen: </span>" AccGetLocation(Acc, child)
		. "`n<span class='param'>Mouse: </span><span name='MS:'>x" x - AccCoord[1] " y" y - AccCoord[2] "</span>"
		. _DP "<span class='param'>Window: </span><span name='MS:'>x" AccCoord[1] - wx " y" AccCoord[2] - wy "</span>"
		. (cx != "" ? _DP "<span class='param'>Control: </span><span name='MS:'>x" (AccCoord[1] - wx - cx) " y" (AccCoord[2] - wy - cy) "</span>" : "") _PRE2
	If ((Var := Acc.accName(child)) != "")
		code .= _T1P " ( Name ) </span><a></a>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(Var) _PRE2  
	If ((Var := Acc.accValue(child)) != "") 
		code .= _T1P " ( Value ) </span><a></a>" _BT1 " id='copy_button'> copy " _BT2 _T2 _LPRE ">" TransformHTML(Var) _PRE2  
	If ((Var := AccGetStateText(Var2 := Acc.accState(child))) != "")
		code .= _T1P " ( State ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>"
		. _DP "<span class='param' name='MS:N'>code: </span><span name='MS:'>" Var2 "</span>" _PRE2
	If ((Var := AccRole(Acc, child)) != "") 
		code .= _T1P " ( Role ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>"
		. _DP "<span class='param' name='MS:N'>code: </span><span name='MS:'>" Acc.accRole(child) "</span>" _PRE2 
	If (child &&(Var := AccRole(Acc)) != "")  
		code .= _T1P " ( Role - parent ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>"
		. _DP "<span class='param' name='MS:N'>code: </span><span name='MS:'>" Acc.accRole(0) "</span>" _PRE2 
	If ((Var := Acc.accDefaultAction(child)) != "")  
		code .= _T1P " ( Action ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>" _PRE2
	If ((Var := Acc.accSelection) > 0)  
		code .= _T1P " ( Selection - parent ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>" _PRE2
	If ((Var := Acc.accFocus) > 0)  
		code .= _T1P " ( Focus - parent ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>" _PRE2 
	If ((Var := Acc.accDescription(child)) != "")  
		code .= _T1P " ( Description ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>" _PRE2 
	If ((Var := Acc.accKeyboardShortCut(child)) != "")  
		code .= _T1P " ( ShortCut ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>" _PRE2 
	If ((Var := Acc.accHelp(child)) != "")  
		code .= _T1P " ( Help ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>" _PRE2  
	If ((Var := Acc.AccHelpTopic(child))) 
		code .= _T1P " ( HelpTopic ) </span>" _T2 _PRE1 "<span name='MS:'>" TransformHTML(Var) "</span>" _PRE2  
	Return code
}

AccRole(Acc, ChildId=0) {
	Return ComObjType(Acc, "Name") = "IAccessible" ? AccGetRoleText(Acc.accRole(ChildId)) : ""
}

AccGetRoleText(nRole) {
	nSize := DllCall("oleacc\GetRoleText", "UInt", nRole, "Ptr", 0, "UInt", 0)
	VarSetCapacity(sRole, (A_IsUnicode?2:1)*nSize)
	DllCall("oleacc\GetRoleText", "UInt", nRole, "str", sRole, "UInt", nSize+1)
	Return sRole
}

AccGetStateText(nState) {
	nSize := DllCall("oleacc\GetStateText", "UInt", nState, "Ptr", 0, "UInt", 0)
	VarSetCapacity(sState, (A_IsUnicode?2:1)*nSize)
	DllCall("oleacc\GetStateText", "UInt", nState, "str", sState, "UInt", nSize+1)
	Return sState
}

AccGetLocation(Acc, Child=0) {
	Acc.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), Child)
	Return "<span name='MS:'>x" (AccCoord[1]:=NumGet(x,0,"int")) " y" (AccCoord[2]:=NumGet(y,0,"int")) "</span>"
			. _DP "<span class='param'>Size: </span><span name='MS:'>w" (AccCoord[3]:=NumGet(w,0,"int")) " h" (AccCoord[4]:=NumGet(h,0,"int")) "</span>"
}

	; _________________________________________________ Mode_Hotkey _________________________________________________

Mode_Hotkey:
	Try SetTimer, Loop_%ThisMode%, Off
	If ThisMode = Hotkey
		oDocEl.scrollLeft := 0
	oBody.createTextRange().execCommand("RemoveFormat")
	ScrollPos[ThisMode,1] := oDocEl.scrollLeft, ScrollPos[ThisMode,2] := oDocEl.scrollTop
	If ThisMode != Hotkey
		HTML_%ThisMode% := oBody.innerHTML
	ThisMode := "Hotkey", Hotkey_Hook(!isPaused)
	TitleText := (TitleTextP1 := "AhkSpy - Button") . TitleTextP2
	oDocEl.scrollLeft := ScrollPos[ThisMode,1], oDocEl.scrollTop := ScrollPos[ThisMode,2]
	ShowMarker ? (HideMarker(), HideAccMarker()) : 0
	(HTML_Hotkey != "") ? Write_Hotkey() : Write_HotkeyHTML({Mods:"Waiting pushed buttons..."})
	SendMessage, 0xC, 0, &TitleText, , ahk_id %hGui%
	GuiControl, TB: -0x0001, But3
	WinActivate ahk_id %hGui%
	GuiControl, 1:Focus, oDoc 
	If isFindView
		FindSearch(1)
	Return

Write_HotkeyHTML(K) {
	Static PrHK1, PrHK2, Name

	Mods := K.Mods, KeyName := K.Name
	Prefix := K.Pref, Hotkey := K.HK
	LRMods := K.LRMods, LRPref := TransformHTML(K.LRPref)
	ThisKey := K.TK, VKCode := K.VK, SCCode := K.SC

	If (K.NFP && Mods KeyName != "")
		NotPhysical	:= " " _DP "<span style='color:#" ColorDelimiter "'> Emulated</span>"

	HK1 := K.IsCode ? Hotkey : ThisKey
	HK2 := HK1 = PrHK1 ? PrHK2 : PrHK1, PrHK1 := HK1, PrHK2 := HK2
	HKComm1 := "    `;  """ (StrLen(Name := GetKeyName(HK2)) = 1 ? Format("{:U}", Name) : Name)
	HKComm2 := (StrLen(Name := GetKeyName(HK1)) = 1 ? Format("{:U}", Name) : Name) """"
	
	If K.IsCode
		Comment := "<span class='param' name='MS:S'>    `;  """ KeyName """</span>"
	If (Hotkey != "")
		FComment := "<span class='param' name='MS:S'>    `;  """ Mods KeyName """</span>"

	If (LRMods != "")
	{
		LRMStr := "<span name='MS:'>" LRMods KeyName "</span>"
		If (Hotkey != "")
			LRPStr := "  " _DP "  <span><span name='MS:'>" LRPref Hotkey "::</span><span class='param' name='MS:S'>    `;  """ LRMods KeyName """</span></span>"
	}
	If Prefix !=
		DUMods := (K.MLCtrl ? "{LCtrl Down}" : "") (K.MRCtrl ? "{RCtrl Down}" : "")
			. (K.MLAlt ? "{LAlt Down}" : "") (K.MRAlt ? "{RAlt Down}" : "")
			. (K.MLShift ? "{LShift Down}" : "") (K.MRShift ? "{RShift Down}" : "")
			. (K.MLWin ? "{LWin Down}" : "") (K.MRWin ? "{RWin Down}" : "") . "{" Hotkey "}"
			. (K.MLCtrl ? "{LCtrl Up}" : "") (K.MRCtrl ? "{RCtrl Up}" : "")
			. (K.MLAlt ? "{LAlt Up}" : "") (K.MRAlt ? "{RAlt Up}" : "")
			. (K.MLShift ? "{LShift Up}" : "") (K.MRShift ? "{RShift Up}" : "")
			. (K.MLWin ? "{LWin Up}" : "") (K.MRWin ? "{RWin Up}" : "")

	SendHotkey := Hotkey = "" ? ThisKey : Hotkey

	ControlSend := DUMods = "" ? "{" SendHotkey "}" : DUMods

	If (DUMods != "")
		LRSend := "  " _DP "  <span><span name='MS:'>" SendMode  " " DUMods "</span>" Comment "</span>"
	If SCCode !=
		ThisKeySC := "   " _DP "   <span name='MS:'>" VKCode "</span>   " _DP "   <span name='MS:'>" SCCode "</span>   "
		. _DP "   <span name='MS:'>0x" SubStr(VKCode, 3) "</span>   " _DP "   <span name='MS:'>0x" SubStr(SCCode, 3) "</span>"
	Else
		ThisKeySC := "   " _DP "   <span name='MS:'>0x" SubStr(VKCode, 3) "</span>" 
	
	inp_hotkey := oDoc.getElementById("edithotkey").value, inp_keyname := oDoc.getElementById("editkeyname").value
	
	HTML_Hotkey =
	( Ltrim
	<body id='body'>
	%_T1% ( Pushed buttons ) </span>%_BT1% id='pause_button'> pause %_BT2%%_T2% 
	%_PRE1%<br><span name='MS:'>%Mods%%KeyName%</span>%NotPhysical%<br><br>%LRMStr%<br>%_PRE2%
	%_T1% ( Command syntax ) </span>%_BT1% id='SendCode'> %SendCode% %_BT2%%_DB%%_BT1% id='SendMode'> %SendModeStr% %_BT2%%_T2% 
	%_PRE1%<br><span><span name='MS:'>%Prefix%%Hotkey%::</span>%FComment%</span>%LRPStr%
	<span name='MS:P'>        </span>
	<span><span name='MS:'>%SendMode% %Prefix%{%SendHotkey%}</span>%Comment%</span>  %_DP%  <span><span name='MS:'>ControlSend, ahk_parent, %ControlSend%, WinTitle</span>%Comment%</span>
	<span name='MS:P'>        </span>
	<span><span name='MS:'>%Prefix%{%SendHotkey%}</span>%Comment%</span>%LRSend%
	<span name='MS:P'>        </span>
	<span><span name='MS:'>GetKeyState("%SendHotkey%", "P")</span>%Comment%</span>   %_DP%   <span><span name='MS:'>KeyWait, %SendHotkey%, D T0.5</span>%Comment%</span>
	<span name='MS:P'>        </span>
	<span><span name='MS:'>%HK2% & %HK1%::</span><span class='param' name='MS:S'>%HKComm1% & %HKComm2%</span></span>   %_DP%   <span><span name='MS:'>%HK2%::%HK1%</span><span class='param' name='MS:S'>%HKComm1% &#8250 &#8250 %HKComm2%</span></span>
	<span name='MS:P'>        </span>%_PRE2%
	%_T1% ( Key ) </span>%_BT1% id='numlock'> num %_BT2%%_DB%%_BT1% id='locale_change'> locale %_BT2%%_DB%%_BT1% id='hook_reload'> hook reload %_BT2%%_T2% 
	%_PRE1%<br><span name='MS:'>%ThisKey%</span>   %_DP%   <span name='MS:'>%VKCode%%SCCode%</span>%ThisKeySC%
	
	%_PRE2%
	%_T1% ( Get name or code ) </span>%_BT1% id='paste_keyname'> paste %_BT2%%_T2%
	<br><span id='hotkeybox'>
	%_INPHK% id='edithotkey' value='%inp_hotkey%'><button id='keyname'> &#8250 &#8250 &#8250 </button>%_INPHK% id='editkeyname' value='%inp_keyname%'></input>
	</span> 
	%_PRE1%%_PRE2%
	%_T0% 
	</body>
	
	<style>
	* {
		margin: 0;
		background: none;
		font-family: %FontFamily%;
		font-weight: 500;
	}
	body {
		margin: 0.3em;
		background-color: #%ColorBg%;
		font-size: %FontSize%px; 
	}
	.br {
		height:0.1em;
	}
	.box {
		position: absolute; 
		overflow: hidden;
		width: 100`%;
		height: 1.7em;
		background: transparent;
		left: 0px;
	}
	.line {
		position: absolute;
		width: 100`%;
		top: 1px;
	}
	.con {
		position: absolute;
		left: 30`%;
	}
	.title {
		margin-right: 50px;
		white-space: pre;
		color: #%ColorTitle%; 
	}
	.hr {
		position: absolute;
		width: 100`%;
		border-bottom: 0.2em dashed red;
		height: 0.5em;
	}
	pre {
		margin-bottom: 0.1em;
		margin-top: 0.1em;
		line-height: 1.1em;
	}
	.button {
		position: relative;
		border: 1px dotted;
		border-color: black;
		white-space: pre;
		cursor: hand; 
	}
	.BB {
		display: inline-block;
	}
	.param {
		color: #%ColorParam%;
	}
	#SendCode, #SendMode {
		text-align: center;
		position: absolute;  
	}
	#SendCode { 
		width: 3em; left: 12em;
	}
	#SendMode { 
		width: 5em; left: 16em;
	}
	#hotkeybox {  
		position: relative;
		white-space: pre;
		left: 5px;
	}
	#edithotkey, #keyname, #editkeyname {
		font-size: 1.2em; 
		text-align: center; 
		border: 1px dotted black; 
		display: inline-block;
	} 
	#keyname {
		position: relative;
		background-color: #%ColorParam%;
		top: 0px; left: 2px; width: 3em;
	}
	#editkeyname {
		position: relative;
		left: 4px; top: 0px;
	} 
	</style>
	)
	Write_Hotkey()
}

Write_Hotkey() {
	oBody.innerHTML := HTML_Hotkey 
	If oDocEl.scrollLeft
		oDocEl.scrollLeft := 0
}

	; _________________________________________________ Hotkey Functions _________________________________________________

	;  http://forum.script-coding.com/viewtopic.php?pid=69765#p69765

Hotkey_Init(Func, Options = "") {
	#HotkeyInterval 0
	Hotkey_Arr("Func", Func)
	Hotkey_Arr("Up", !!InStr(Options, "U"))
	Hotkey_MouseAndJoyInit(Options)
	OnExit("Hotkey_SetHook"), Hotkey_SetHook()
	Hotkey_Arr("Hook") ? (Hotkey_Hook(0), Hotkey_Hook(1)) : 0
}

Hotkey_Main(In) {
	Static Prefix := {"LAlt":"<!","LCtrl":"<^","LShift":"<+","LWin":"<#"
	,"RAlt":">!","RCtrl":">^","RShift":">+","RWin":">#"}, K := {}, ModsOnly
	Local IsMod, sIsMod
	IsMod := In.IsMod
	If (In.Opt = "Down") {
		If (K["M" IsMod] != "")
			Return 1
		sIsMod := SubStr(IsMod, 2)
		K["M" sIsMod] := sIsMod "+", K["P" sIsMod] := SubStr(Prefix[IsMod], 2)
		K["M" IsMod] := IsMod "+", K["P" IsMod] := Prefix[IsMod]
	}
	Else If (In.Opt = "Up") {
		sIsMod := SubStr(IsMod, 2)
		K.ModUp := 1, K["M" IsMod] := K["P" IsMod] := ""
		If (K["ML" sIsMod] = "" && K["MR" sIsMod] = "")
			K["M" sIsMod] := K["P" sIsMod] := ""
		If (!Hotkey_Arr("Up") && K.HK != "")
			Return 1
	}
	Else If (In.Opt = "OnlyMods") {
		If !ModsOnly
			Return 0
		K.MCtrl := K.MAlt := K.MShift := K.MWin := K.Mods := ""
		K.PCtrl := K.PAlt := K.PShift := K.PWin := K.Pref := ""
		K.PRCtrl := K.PRAlt := K.PRShift := K.PRWin := ""
		K.PLCtrl := K.PLAlt := K.PLShift := K.PLWin := K.LRPref := ""
		K.MRCtrl := K.MRAlt := K.MRShift := K.MRWin := ""
		K.MLCtrl := K.MLAlt := K.MLShift := K.MLWin := K.LRMods := ""
		Func(Hotkey_Arr("Func")).Call(K)
		Return ModsOnly := 0
	}
	Else If (In.Opt = "GetMod")
		Return !!(K.PCtrl K.PAlt K.PShift K.PWin)
	K.UP := In.UP, K.IsJM := 0, K.Time := In.Time, K.NFP := In.NFP, K.IsMod := IsMod
	K.Mods := K.MCtrl K.MAlt K.MShift K.MWin
	K.LRMods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin 
	K.VK := "vk" In.VK, K.SC := "sc" In.SC, K.TK := GetKeyName(K.VK K.SC) 
	K.TK := K.TK = "" ? K.VK K.SC : (StrLen(K.TK) = 1 ? Format("{:U}", K.TK) : K.TK)
	(IsMod) ? (K.HK := K.Pref := K.LRPref := K.Name := K.IsCode := "", ModsOnly := K.Mods = "" ? 0 : 1)
	: (K.IsCode := (SendCode != "name" && StrLen(K.TK) = 1)  ;	 && !Instr("1234567890-=", K.TK)
	, K.HK := K.IsCode ? K[SendCode] : K.TK
	, K.Name := K.HK = "vkBF" ? "/" : K.TK
	, K.Pref := K.PCtrl K.PAlt K.PShift K.PWin
	, K.LRPref := K.PLCtrl K.PRCtrl K.PLAlt K.PRAlt K.PLShift K.PRShift K.PLWin K.PRWin
	, ModsOnly := 0)
	Func(Hotkey_Arr("Func")).Call(K)
	Return 1

Hotkey_PressMouseRButton: 
	If !WM_CONTEXTMENU() && !Hotkey_Hook(0)
		Return
		
Hotkey_PressJoy:
Hotkey_PressMouse:
	K.NFP := !GetKeyState(A_ThisHotkey, "P")
	K.Time := A_TickCount
	K.Mods := K.MCtrl K.MAlt K.MShift K.MWin
	K.LRMods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin
	K.Pref := K.PCtrl K.PAlt K.PShift K.PWin
	K.LRPref := K.PLCtrl K.PRCtrl K.PLAlt K.PRAlt K.PLShift K.PRShift K.PLWin K.PRWin
	K.HK := K.Name := K.TK := A_ThisHotkey, ModsOnly := K.UP := K.IsCode := 0, K.IsMod := K.SC := ""
	K.IsJM := A_ThisLabel = "Hotkey_PressJoy" ? 1 : 2
	K.VK := A_ThisLabel = "Hotkey_PressJoy" ? "" : Format("vk{:X}", GetKeyVK(A_ThisHotkey))
	Func(Hotkey_Arr("Func")).Call(K)
	Return 1
}

#If Hotkey_Arr("Hook") 
#If Hotkey_Arr("Hook") && GetKeyState("RButton", "P")
#If Hotkey_Arr("Hook") && !Hotkey_Main({Opt:"GetMod"})
#If

Hotkey_MouseAndJoyInit(Options) {
	Static MouseKey := "MButton|WheelDown|WheelUp|WheelRight|WheelLeft|XButton1|XButton2"
	Local S_FormatInteger, Option
	Option := InStr(Options, "M") ? "On" : "Off" 
	Hotkey, IF, Hotkey_Arr("Hook")
	Loop, Parse, MouseKey, |  
		Hotkey, %A_LoopField%, Hotkey_PressMouse, % Option   
	Option := InStr(Options, "L") ? "On" : "Off"
	Hotkey, IF, Hotkey_Arr("Hook") && GetKeyState("RButton"`, "P")
	Hotkey, LButton, Hotkey_PressMouse, % Option
	Option := InStr(Options, "R") ? "On" : "Off"
	Hotkey, IF, Hotkey_Arr("Hook")
	Hotkey, RButton, Hotkey_PressMouseRButton, % Option
	Option := InStr(Options, "J") ? "On" : "Off"
	S_FormatInteger := A_FormatInteger
	SetFormat, IntegerFast, D
	Hotkey, IF, Hotkey_Arr("Hook") && !Hotkey_Main({Opt:"GetMod"})
	Loop, 128
		Hotkey % Ceil(A_Index / 32) "Joy" Mod(A_Index - 1, 32) + 1, Hotkey_PressJoy, % Option
	SetFormat, IntegerFast, %S_FormatInteger%
	Hotkey, IF
}

Hotkey_Hook(Val = 1) {
	Hotkey_Arr("Hook", Val)
	!Val && Hotkey_Main({Opt:"OnlyMods"})
}

Hotkey_Arr(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : (Arr[P[1]] := P[2])
}

	;  http://forum.script-coding.com/viewtopic.php?id=6350

Hotkey_LowLevelKeyboardProc(nCode, wParam, lParam) {
	Static Mods := {"A4":"LAlt","A5":"RAlt","A2":"LCtrl","A3":"RCtrl"
	,"A0":"LShift","A1":"RShift","5B":"LWin","5C":"RWin"}, oMem := []
	, HEAP_ZERO_MEMORY := 0x8, Size := 16, hHeap := DllCall("GetProcessHeap", Ptr)
	Local pHeap, Lp, Ext, VK, SC, SC1, SC2, IsMod, Time, NFP, KeyUp
	Critical
	If !Hotkey_Arr("Hook")
		Return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam)
	pHeap := DllCall("HeapAlloc", Ptr, hHeap, UInt, HEAP_ZERO_MEMORY, Ptr, Size, Ptr)
	DllCall("RtlMoveMemory", Ptr, pHeap, Ptr, lParam, Ptr, Size), oMem.Push(pHeap)
	SetTimer, Hotkey_HookProcWork, -10
	Return nCode < 0 ? DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam) : 1

	Hotkey_HookProcWork:
		While (oMem[1] != "") {
			If Hotkey_Arr("Hook") {
				Lp := oMem[1]
				VK := Format("{:X}", NumGet(Lp + 0, "UInt"))
				Ext := NumGet(Lp + 0, 8, "UInt")
				SC1 := NumGet(Lp + 0, 4, "UInt") 
				NFP := (Ext >> 4) & 1				;  Не физическое нажатие
				KeyUp := Ext >> 7
				; Time := NumGet(Lp + 12, "UInt")
				IsMod := Mods[VK]
				If !SC1
					SC2 := GetKeySC("vk" VK), SC := SC2 = "" ? "" : Format("{:X}", SC2)
				Else
					SC := Format("{:X}", (Ext & 1) << 8 | SC1)
				If !KeyUp
					IsMod ? Hotkey_Main({VK:VK, SC:SC, Opt:"Down", IsMod:IsMod, NFP:NFP, Time:Time, UP:0})
					: Hotkey_Main({VK:VK, SC:SC, NFP:NFP, Time:Time, UP:0})
				Else
					IsMod ? Hotkey_Main({VK:VK, SC:SC, Opt:"Up", IsMod:IsMod, NFP:NFP, Time:Time, UP:1})
					: (Hotkey_Arr("Up") ? Hotkey_Main({VK:VK, SC:SC, NFP:NFP, Time:Time, UP:1}) : 0)
			}
			DllCall("HeapFree", Ptr, hHeap, UInt, 0, Ptr, Lp)
			oMem.RemoveAt(1)
		}
		Return
}

Hotkey_SetHook(On = 1) {
	Static hHook
	If (On = 1 && !hHook)
		hHook := DllCall("SetWindowsHookEx" . (A_IsUnicode ? "W" : "A")
				, "Int", 13   ;  WH_KEYBOARD_LL
				, "Ptr", RegisterCallback("Hotkey_LowLevelKeyboardProc", "Fast")
				, "Ptr", DllCall("GetModuleHandle", "UInt", 0, "Ptr")
				, "UInt", 0, "Ptr")
	Else If (On != 1)
		DllCall("UnhookWindowsHookEx", "Ptr", hHook), hHook := "", Hotkey_Hook(0)
}

	; _________________________________________________ Labels _________________________________________________

GuiSize: 
	If A_Gui != 1
		Return
	Sleep := A_EventInfo
	If Sleep != 1
		ControlsMove(A_GuiWidth, A_GuiHeight)
	Else
		ZoomMsg(1), HideMarker(), HideAccMarker()
	Try SetTimer, Loop_%ThisMode%, % Sleep = 1 || isPaused ? "Off" : "On"
	Return

Exit:
GuiClose:
	oDoc := ""
	DllCall("DeregisterShellHookWindow", "Ptr", A_ScriptHwnd)
	If LastModeSave 
		IniWrite(ThisMode, "LastMode")
	ExitApp

CheckAhkVersion:
	If A_AhkVersion < 1.1.17.00
	{
		MsgBox Requires AutoHotkey_L version 1.1.17.00+
		RunPath("http://ahkscript.org/download/")
		ExitApp
	}
	Return

LaunchHelp:
	If !FileExist(SubStr(A_AhkPath,1,InStr(A_AhkPath,"\",,0,1)) "AutoHotkey.chm")
		Return
	IfWinNotExist AutoHotkey Help ahk_class HH Parent ahk_exe hh.exe
		Run % SubStr(A_AhkPath,1,InStr(A_AhkPath,"\",,0,1)) "AutoHotkey.chm"
	WinActivate
	Minimize()
	Return

DefaultSize:
	If FullScreenMode
	{
		FullScreenMode()
		Gui, 1: Restore
		Sleep 200
	}
	Gui, 1: Show, % "NA w" widthTB "h" HeightStart
	ZoomMsg(6)
	If !MemoryFontSize
		oDoc.getElementById("pre").style.fontSize := FontSize := 15
	Return

Reload:
	Reload
	Return

Suspend:
	isAhkSpy := !isAhkSpy
	Menu, Sys, % !isAhkSpy ? "Check" : "UnCheck", % A_ThisMenuItem
	ZoomMsg(9, !isAhkSpy)
	Return
	
CheckUpdate:
	StateUpdate := IniWrite(!StateUpdate, "StateUpdate")
	Menu, Sys, % (StateUpdate ? "Check" : "UnCheck"), Check updates
	If StateUpdate
		SetTimer, UpdateAhkSpy, -1
	Else
	{
		SetTimer, UpdateAhkSpy, Off
		SetTimer, Upd_Verifi, Off
	}
	Return

SelStartMode:
	Menu, Startmode, UnCheck, Window
	Menu, Startmode, UnCheck, Control
	Menu, Startmode, UnCheck, Button
	Menu, Startmode, UnCheck, Last Mode
	IniWrite({"Window":"Win","Control":"Control","Button":"Hotkey","Last Mode":"LastMode"}[A_ThisMenuItem], "StartMode")
	LastModeSave := (A_ThisMenuItem = "Last Mode")
	Menu, Startmode, Check, % A_ThisMenuItem
	Return

ShowSys(x, y) {
ShowSys:
	ZoomMsg(7, 1)
	Menu, Sys, Show, % x, % y
	ZoomMsg(7, 0)
	Return
}

Sys_Backlight:
	Menu, Sys, UnCheck, % BLGroup[StateLight]
	Menu, Sys, Check, % A_ThisMenuItem
	IniWrite((StateLight := InArr(A_ThisMenuItem, BLGroup)), "StateLight")
	Return

Sys_Acclight:
	StateLightAcc := IniWrite(!StateLightAcc, "StateLightAcc"), HideAccMarker()
	Menu, Sys, % (StateLightAcc ? "Check" : "UnCheck"), Acc object backlight
	Return

Sys_WClight:
	StateLightMarker := IniWrite(!StateLightMarker, "StateLightMarker"), HideMarker()
	Menu, Sys, % (StateLightMarker ? "Check" : "UnCheck"), Window or control backlight
	Return

Sys_Help:
	If A_ThisMenuItem = AutoHotKey official help online
		RunPath("http://ahkscript.org/docs/AutoHotkey.htm")
	Else If A_ThisMenuItem = AutoHotKey russian help online
		RunPath("http://www.script-coding.com/AutoHotkeyTranslation.html")
	Else If A_ThisMenuItem = About
		RunPath("http://forum.script-coding.com/viewtopic.php?pid=72459#p72459")
	Return

Help_OpenUserDir:
	RunPath(A_AppData "\AhkSpy")
	Return

Help_OpenScriptDir:
	SelectFilePath(A_ScriptFullPath)
	Minimize()
	Return

Spot_Together:
	StateAllwaysSpot := IniWrite(!StateAllwaysSpot, "AllwaysSpot")
	Menu, Sys, % (StateAllwaysSpot ? "Check" : "UnCheck"), Spot together (low speed)
	Return

Active_No_Pause:
	ActiveNoPause := IniWrite(!ActiveNoPause, "ActiveNoPause")
	Menu, Sys, % (ActiveNoPause ? "Check" : "UnCheck"), Work with the active window
	ZoomMsg(8, ActiveNoPause)
	(ActiveNoPause && Sleep != 1 && !isPaused) && ZoomMsg(0)
	Return

MemoryPos:
	IniWrite(MemoryPos := !MemoryPos, "MemoryPos")
	Menu, View, % MemoryPos ? "Check" : "UnCheck", Remember position
	SavePos()
	Return

MemorySize:
	IniWrite(MemorySize := !MemorySize, "MemorySize")
	Menu, View, % MemorySize ? "Check" : "UnCheck", Remember size
	SaveSize()
	Return

MemoryFontSize:
	IniWrite(MemoryFontSize := !MemoryFontSize, "MemoryFontSize")
	Menu, View, % MemoryFontSize ? "Check" : "UnCheck", Remember font size
	If MemoryFontSize
		IniWrite(FontSize, "FontSize")
	Return

MemoryZoomSize:
	IniWrite(MemoryZoomSize := !MemoryZoomSize, "MemoryZoomSize")
	Menu, View, % MemoryZoomSize ? "Check" : "UnCheck", Remember zoom size
	ZoomMsg(5, MemoryZoomSize)
	Return

PreOverflowHide:
	IniWrite(PreOverflowHide := !PreOverflowHide, "PreOverflowHide")
	Menu, View, % PreOverflowHide ? "Check" : "UnCheck", Big text overflow hide 
	ChangeCSS("css_PreOverflowHide", PreOverflowHide ? _PreOverflowHideCSS : "")
	Return
	
MoveTitles:
	IniWrite(MoveTitles := !MoveTitles, "MoveTitles")
	Menu, View, % MoveTitles ? "Check" : "UnCheck", Moving titles
	if oJScript.MoveTitles := MoveTitles
		oJScript.shift(0)
	else
		oDocEl.scrollLeft := 0, oJScript.conleft30()
	Return

MemoryStateZoom:
	IniWrite(MemoryStateZoom := !MemoryStateZoom, "MemoryStateZoom")
	Menu, View, % MemoryStateZoom ? "Check" : "UnCheck", Remember state zoom
	IniWrite(oOther.ZoomShow, "ZoomShow")
	Return
	
WordWrap:
	IniWrite(WordWrap := !WordWrap, "WordWrap")
	Menu, View, % WordWrap ? "Check" : "UnCheck", Word wrap
	If WordWrap
		oDocEl.scrollLeft := 0
	oJScript.WordWrap := WordWrap
	ChangeCSS("css_Body", WordWrap ? _BodyWrapCSS : "")
	Return

	; _________________________________________________ Functions _________________________________________________

ShellProc(nCode, wParam) {
	If (nCode = 4)
	{
		If (wParam = hGui)
			(ThisMode = "Hotkey" && !isPaused ? Hotkey_Hook(1) : ""), HideMarker(), HideAccMarker(), CheckHideMarker()
		Else If Hotkey_Arr("Hook")
			Hotkey_Hook(0)
		ZoomMsg(!ActiveNoPause && wParam = hGui ? 1 : Sleep != 1 && !isPaused && ThisMode != "Hotkey" ? 0 : 1)
	}
}

WM_ACTIVATE(wp) {
	Critical
	If (wp & 0xFFFF)
		(ThisMode = "Hotkey" && !isPaused ? Hotkey_Hook(1) : 0), HideMarker(), HideAccMarker(), CheckHideMarker()
	Else If (wp & 0xFFFF = 0 && Hotkey_Arr("Hook"))
		Hotkey_Hook(0)
	ZoomMsg(!ActiveNoPause && (wp & 0xFFFF) ? 1 : Sleep != 1 && !isPaused && ThisMode != "Hotkey" ? 0 : 1)
}

WM_NCLBUTTONDOWN(wp) {
	Static HTMINBUTTON := 8
	If (wp = HTMINBUTTON)
	{
		SetTimer, Minimize, -10
		Return 0
	}
}

WM_LBUTTONDOWN() {
	If A_GuiControl = ColorProgress
	{
		If ThisMode = Hotkey
			oDoc.execCommand("Paste"), ToolTip("Paste", 300)
		Else
		{
			SendInput {LAlt Down}{Escape}{LAlt Up}
			If (Sleep != 1 && !isPaused)
				ZoomMsg(0)
			ToolTip("Alt+Escape", 300)
		}
	}
}

WM_MBUTTONUP(wp) {
	If (A_GuiControl = "ColorProgress")
		Return 0, ToolTip("Zoom", 300), AhkSpyZoomShow()
}

WM_CONTEXTMENU() {
	MouseGetPos, , , wid, cid, 2 
	If (hColorProgress = cid) {
		Gosub, PausedScript
		ToolTip("Pause", 300)
		Return 0
	}
	Else If (cid != hActiveX && wid = hGui) {
		SetTimer, ShowSys, -1
		Return 0
	}
	Return 1
}

WM_WINDOWPOSCHANGED(Wp, Lp) {
	Static PtrAdd := A_PtrSize = 8 ? 8 : 0
	If (NumGet(Lp + 0, 0, "UInt") != hGui)
		Return
	If oOther.ZoomShow 
	{
		DllCall("EndDeferWindowPos", "Ptr", DllCall("DeferWindowPos"
		, "Ptr", DllCall("BeginDeferWindowPos", "Int", 1), "Ptr", oOther.hZoom, "UInt", 0
		, "Int", NumGet(Lp + 0, 8 + PtrAdd, "UInt") + NumGet(Lp + 0, 16 + PtrAdd, "UInt")
		, "Int", NumGet(Lp + 0, 12 + PtrAdd, "UInt"), "Int", 0, "Int", 0
		, "UInt", 0x0011))    ; 0x0010 := SWP_NOACTIVATE | 0x0001 := SWP_NOSIZE 
	}
	If MemoryPos
		SetTimer, SavePos, -400
} 

WM_SIZE() {
	If MemorySize
		SetTimer, SaveSize, -400 
}

ControlsMove(Width, Height) { 
	hDWP := DllCall("BeginDeferWindowPos", "Int", isFindView ? 3 : 2)
	hDWP := DllCall("DeferWindowPos"
	, "Ptr", hDWP, "Ptr", hTBGui, "UInt", 0
	, "Int", (Width - widthTB) // 2.2, "Int", 0, "Int", 0, "Int", 0
	, "UInt", 0x0011)    ; 0x0010 := SWP_NOACTIVATE | 0x0001 := SWP_NOSIZE 
	hDWP := DllCall("DeferWindowPos"
	, "Ptr", hDWP, "Ptr", hActiveX, "UInt", 0
	, "Int", 0, "Int", HeigtButton
	, "Int", Width, "Int", Height - HeigtButton - (isFindView ? 28 : 0)
	, "UInt", 0x0010)    ; 0x0010 := SWP_NOACTIVATE
	If isFindView
		hDWP := DllCall("DeferWindowPos"
		, "Ptr", hDWP, "Ptr", hFindGui, "UInt", 0
		, "Int", (Width - widthTB) // 2.2, "Int", (Height - (Height < HeigtButton * 2 ? -2 : 27))
		, "Int", 0, "Int", 0
		, "UInt", 0x0011)    ; 0x0010 := SWP_NOACTIVATE | 0x0001 := SWP_NOSIZE 
	DllCall("EndDeferWindowPos", "Ptr", hDWP)
}

Minimize() {
	Sleep := 1
	ZoomMsg(1)
	Gui, 1: Minimize
}

ZoomSpot() {
	If (!isPaused && Sleep != 1 && WinActive("ahk_id" hGui))
		(ThisMode = "Control" ? (Spot_Control() (StateAllwaysSpot ? Spot_Win() : 0) Write_Control()) : (Spot_Win() (StateAllwaysSpot ? Spot_Control() : 0) Write_Win()))
}

MsgZoom(wParam, lParam) {
	If (wParam = 1) 
		SetTimer, ZoomSpot, -10 
	Else If (wParam = 2) 
		oOther.ZoomShow := lParam, (MemoryStateZoom && IniWrite(lParam, "ZoomShow"))
	Else If (wParam = 0)
		oOther.hZoom := lParam, ZoomMsg(Sleep != 1 && !isPaused && (!WinActive("ahk_id" hGui) || ActiveNoPause) ? 0	 : 1)
}

ZoomMsg(wParam = -1, lParam = -1) {
	If WinExist("AhkSpyZoom ahk_id" oOther.hZoom)
		PostMessage, % MsgAhkSpyZoom, wParam, lParam, , % "ahk_id" oOther.hZoom
}

AhkSpyZoomShow() {  
	If !WinExist("ahk_id" oOther.hZoom) {
		If A_IsCompiled
			Run "%A_ScriptFullPath%" "Zoom" "%hGui%" "%ActiveNoPause%" "%isPaused%", , , PID
		Else
			Run "%A_AHKPath%" "%A_ScriptFullPath%" "Zoom" "%hGui%" "%ActiveNoPause%" "%isPaused%", , , PID
		WinWait, % "ahk_pid" PID, , 1 
	}
	Else If DllCall("IsWindowVisible", "Ptr", oOther.hZoom) 
		ZoomMsg(3)
	Else
		ZoomMsg(4)
	ZoomMsg(7, isPaused), ZoomMsg(8, ActiveNoPause)
	ZoomMsg(Sleep != 1 && !isPaused && (!WinActive("ahk_id" hGui) || ActiveNoPause) ? 0 : 1)
}

SavePos() {
	If FullScreenMode || !MemoryPos
		Return
	WinGet, Min, MinMax, ahk_id %hGui%
	If (Min = 0)
	{
		WinGetPos, WinX, WinY, , , ahk_id %hGui%
		IniWrite(WinX, "MemoryPosX"), IniWrite(WinY, "MemoryPosY")
	}
}

SaveSize() {
	If FullScreenMode || !MemorySize
		Return
	WinGet, Min, MinMax, ahk_id %hGui%
	If (Min = 0)
	{
		GetClientPos(hGui, _, _, WinWidth, WinHeight)
		IniWrite(WinWidth, "MemorySizeW"), IniWrite(WinHeight, "MemorySizeH")
	}
}

	;  http://forum.script-coding.com/viewtopic.php?pid=87817#p87817
	;  http://www.autohotkey.com/board/topic/93660-embedded-ie-shellexplorer-render-issues-fix-force-it-to-use-a-newer-render-engine/

FixIE() {
	Key := "Software\Microsoft\Internet Explorer\MAIN"
	. "\FeatureControl\FEATURE_BROWSER_EMULATION", ver := 8000
	If A_IsCompiled
		ExeName := A_ScriptName
	Else
		SplitPath, A_AhkPath, ExeName
	RegRead, value, HKCU, %Key%, %ExeName%
	If (value != ver)
		RegWrite, REG_DWORD, HKCU, %Key%, %ExeName%, %ver%
}

RunPath(Link, WorkingDir = "", Option = "") {
	Run %Link%, %WorkingDir%, %Option%
	Minimize()
} 

RunRealPath(Path) {
	SplitPath, Path, , Dir
	Dir := LTrim(Dir, """")
	While !InStr(FileExist(Dir), "D")
		Dir := SubStr(Dir, 1, -1)
	Run, %Path%, %Dir%
}

RunAhkPath(Path) {
	SplitPath, Path, , , Extension
	If Extension = exe
		RunPath(Path)
	Else If (!A_IsCompiled && Extension = "ahk") 
		RunPath("""" A_AHKPath """ """ Path """")
}

ExtraFile(Name, GetNoCompile = 0) {
	Static Dir := A_AppData "\AhkSpy"
	If FileExist(Dir "\" Name ".exe")
		Return Dir "\" Name ".exe" 
	If !A_IsCompiled && FileExist(Dir "\" Name ".ahk")
		Return Dir "\" Name ".ahk"
}

ShowMarker(x, y, w, h, b := 4) { 
	If !oShowMarkers
		ShowMarkersCreate("oShowMarkers", "E14B30")
	(w < 8 || h < 8) && (b := 2)
	ShowMarkers(oShowMarkers, x, y, w, h, b)
}

ShowAccMarker(x, y, w, h, b := 2) { 
	If !oShowAccMarkers
		ShowMarkersCreate("oShowAccMarkers", "26419F")
	ShowMarkers(oShowAccMarkers, x, y, w, h, b)
}

HideMarker() {  
	HideMarkers(oShowMarkers) 
}

HideAccMarker() {
	HideMarkers(oShowAccMarkers)
}

ShowMarkers(arr, x, y, w, h, b) { 
	ShowMarker := 1 
	hDWP := DllCall("BeginDeferWindowPos", "Int", 4)
	for k, v in [[x, y, b, h],[x, y+h-b, w, b],[x+w-b, y, b, h],[x, y, w, b]]
		{
			hDWP := DllCall("DeferWindowPos"
			, "Ptr", hDWP, "Ptr", arr[k], "UInt", -1  ;	-1 := HWND_TOPMOST
			, "Int", v[1], "Int", v[2], "Int", v[3], "Int", v[4]
			, "UInt", 0x0250)    ; 0x0010 := SWP_NOACTIVATE | 0x0040 := SWP_SHOWWINDOW | SWP_NOOWNERZORDER := 0x0200
		}
	DllCall("EndDeferWindowPos", "Ptr", hDWP)
}

HideMarkers(arr) { 
	ShowMarker := 0
	hDWP := DllCall("BeginDeferWindowPos", "Int", 4)
	Loop 4
		hDWP := DllCall("DeferWindowPos"
		, "Ptr", hDWP, "Ptr", arr[A_Index], "UInt", 0
		, "Int", 0, "Int", 0, "Int", 0, "Int", 0
		, "UInt", 0x0083)    ; 0x0080 := SWP_HIDEWINDOW | SWP_NOMOVE := 0x0002 | SWP_NOSIZE := 0x0001
	DllCall("EndDeferWindowPos", "Ptr", hDWP)
}

ShowMarkersCreate(arr, color) {  
	S_DefaultGui := A_DefaultGui, %arr% := {}
	loop 4
	{
		Gui, New
		Gui, Margin, 0, 0
		Gui, -DPIScale  +HWNDHWND -Caption +Owner +0x40000000 +E0x20 -0x80000000 +E0x08000000 +AlwaysOnTop 
		Gui, Color, %color%
		WinSet, TransParent, 250, ahk_id %HWND%
		%arr%[A_Index] := HWND 
		Gui, Show, NA Hide
	}
	Gui, %S_DefaultGui%:Default 
}

CheckHideMarker() {
	Static Try := 0
	SetTimer, CheckHideMarker, -150
	Return

	CheckHideMarker:
		If !(Try := ++Try > 2 ? 0 : Try)
			Return
		WinActive("ahk_id" hGui) ? (HideMarker(), HideAccMarker()) : 0
		SetTimer, CheckHideMarker, -250
		Return
}

SetEditColor(hwnd, BG, FG) {
	Edits[hwnd] := {BG:BG,FG:FG}
	WM_CTLCOLOREDIT(DllCall("GetDC", "Ptr", hwnd), hwnd)
	DllCall("RedrawWindow", "Ptr", hwnd, "Uint", 0, "Uint", 0, "Uint", 0x1|0x4)
}

WM_CTLCOLOREDIT(wParam, lParam) {
	If !Edits.HasKey(lParam)
		Return 0
	hBrush := DllCall("CreateSolidBrush", UInt, Edits[lParam].BG)
	DllCall("SetTextColor", Ptr, wParam, UInt, Edits[lParam].FG)
	DllCall("SetBkColor", Ptr, wParam, UInt, Edits[lParam].BG)
	DllCall("SetBkMode", Ptr, wParam, UInt, 2)
	Return hBrush
}

IniRead(Key, Error := " ") {
	IniRead, Value, %A_AppData%\AhkSpy\Settings.ini, AhkSpy, %Key%, %Error%
	Return Value
}

IniWrite(Value, Key) {
	IniWrite, %Value%, %A_AppData%\AhkSpy\Settings.ini, AhkSpy, %Key%
	Return Value
}

Sleep(time) {
	Sleep time 
}

InArr(Val, Arr) {
	For k, v in Arr 
		If (v == Val)
			Return k
}

TransformHTML(str) {
	Transform, str, HTML, %str%, 3 
	StringReplace, str, str, <br>, , 1
	Return str
}

ExistSelectedText(byref Copy) {
	MouseGetPos, , , , ControlID, 2
	If (ControlID != hActiveX)
		Return 0
	Copy := oDoc.selection.createRange().text
	If Copy is space
		Return 0
	Return 1
}

PausedTitleText() {
	Static i := 0, Str := "           Paused..."
 	If !isPaused
		Return i := 0
	i := i > 20 ? 2 : i + 1
	TitleTextP2 := "     " SubStr(Str, i) . SubStr(Str, 1, i - 1)
	TitleText := TitleTextP1 . TitleTextP2 
	If !FreezeTitleText
		SendMessage, 0xC, 0, &TitleText, , ahk_id %hGui%
	SetTimer, PausedTitleText, -200
}

TitleText(Text, Time = 1000) {
	FreezeTitleText := 1
	StringReplace, Text, Text, `r`n, % Chr(8629), 1
	StringReplace, Text, Text, %A_Tab%, % "      ", 1
	SendMessage, 0xC, 0, &Text, , ahk_id %hGui%
	SetTimer, TitleShow, -%Time%
}

TitleShow:
	SendMessage, 0xC, 0, &TitleText, , ahk_id %hGui%
	FreezeTitleText := 0
	Return

ClipAdd(Text, AddTip = 0) {
	If ClipAdd_Before
		Clipboard := Text ClipAdd_Delimiter Clipboard
	Else
		Clipboard := Clipboard ClipAdd_Delimiter Text
	If AddTip
		ToolTip("add", 300)
}

ClipPaste() {
 	If oMS.ELSel && (oMS.ELSel.OuterText != "" || MS_Cancel())
		oMS.ELSel.innerHTML := TransformHTML(Clipboard), oMS.ELSel.Name := "MS:"
	Else
		oDoc.execCommand("Paste")
	ToolTip("paste", 300)
}

CopyCommaParam(Text) {
 	If !(Text ~= "(x|y|w|h|" Chr(178) ")-*\d+")
		Return Text
	Text := RegExReplace(Text, "i)(x|y|w|h|#|\s|" Chr(178) "|" Chr(9642) ")+", " ")
	Text := TRim(Text, " "), Text := RegExReplace(Text, "(\s|,)+", ", ")
	Return Text
}

	;  http://forum.script-coding.com/viewtopic.php?pid=53516#p53516

; GetCommandLineProc(pid) {
	; ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process WHERE ProcessId = " pid)._NewEnum.next(X)
	; Return Trim(X.CommandLine)
; }

	;  http://forum.script-coding.com/viewtopic.php?pid=111775#p111775

GetCommandLineProc(PID, ByRef Cmd, ByRef Bit) {
	Static PROCESS_QUERY_INFORMATION := 0x400, PROCESS_VM_READ := 0x10, STATUS_SUCCESS := 0

	hProc := DllCall("OpenProcess", UInt, PROCESS_QUERY_INFORMATION|PROCESS_VM_READ, Int, 0, UInt, PID, Ptr)
	if A_Is64bitOS
		DllCall("IsWow64Process", Ptr, hProc, UIntP, IsWow64), Bit := (IsWow64 ? "32" : "64") " bit" _DP
	if (!A_Is64bitOS || IsWow64)
		PtrSize := 4, PtrType := "UInt", pPtr := "UIntP", offsetCMD := 0x40
	else
		PtrSize := 8, PtrType := "Int64", pPtr := "Int64P", offsetCMD := 0x70
	hModule := DllCall("GetModuleHandle", "str", "Ntdll", Ptr)
	if (A_PtrSize < PtrSize) {            ; скрипт 32, целевой процесс 64
		if !QueryInformationProcess := DllCall("GetProcAddress", Ptr, hModule, AStr, "NtWow64QueryInformationProcess64", Ptr)
			failed := "NtWow64QueryInformationProcess64"
		if !ReadProcessMemory := DllCall("GetProcAddress", Ptr, hModule, AStr, "NtWow64ReadVirtualMemory64", Ptr)
			failed := "NtWow64ReadVirtualMemory64"
		info := 0, szPBI := 48, offsetPEB := 8
	}
	else  {
		if !QueryInformationProcess := DllCall("GetProcAddress", Ptr, hModule, AStr, "NtQueryInformationProcess", Ptr)
			failed := "NtQueryInformationProcess"
		ReadProcessMemory := "ReadProcessMemory"
		if (A_PtrSize > PtrSize)            ; скрипт 64, целевой процесс 32
			info := 26, szPBI := 8, offsetPEB := 0
		else                                ; скрипт и целевой процесс одной битности
			info := 0, szPBI := PtrSize * 6, offsetPEB := PtrSize
	}
	if failed  {
		DllCall("CloseHandle", Ptr, hProc)
		Return
	}
	VarSetCapacity(PBI, 48, 0)
	if DllCall(QueryInformationProcess, Ptr, hProc, UInt, info, Ptr, &PBI, UInt, szPBI, UIntP, bytes) != STATUS_SUCCESS  {
		DllCall("CloseHandle", Ptr, hProc)
		Return
	}
	pPEB := NumGet(&PBI + offsetPEB, PtrType)
	DllCall(ReadProcessMemory, Ptr, hProc, PtrType, pPEB + PtrSize * 4, pPtr, pRUPP, PtrType, PtrSize, UIntP, bytes)
	DllCall(ReadProcessMemory, Ptr, hProc, PtrType, pRUPP + offsetCMD, UShortP, szCMD, PtrType, 2, UIntP, bytes)
	DllCall(ReadProcessMemory, Ptr, hProc, PtrType, pRUPP + offsetCMD + PtrSize, pPtr, pCMD, PtrType, PtrSize, UIntP, bytes)
	VarSetCapacity(buff, szCMD, 0)
	DllCall(ReadProcessMemory, Ptr, hProc, PtrType, pCMD, Ptr, &buff, PtrType, szCMD, UIntP, bytes)
	Cmd := StrGet(&buff, "UTF-16")

	DllCall("CloseHandle", Ptr, hProc)
}

SeDebugPrivilege() {
	Static PROCESS_QUERY_INFORMATION := 0x400, TOKEN_ADJUST_PRIVILEGES := 0x20, SE_PRIVILEGE_ENABLED := 0x2

	hProc := DllCall("OpenProcess", UInt, PROCESS_QUERY_INFORMATION, Int, false, UInt, DllCall("GetCurrentProcessId"), Ptr)
	DllCall("Advapi32\OpenProcessToken", Ptr, hProc, UInt, TOKEN_ADJUST_PRIVILEGES, PtrP, token)
	DllCall("Advapi32\LookupPrivilegeValue", Ptr, 0, Str, "SeDebugPrivilege", Int64P, luid)
	VarSetCapacity(TOKEN_PRIVILEGES, 16, 0)
	NumPut(1, TOKEN_PRIVILEGES, "UInt")
	NumPut(luid, TOKEN_PRIVILEGES, 4, "Int64")
	NumPut(SE_PRIVILEGE_ENABLED, TOKEN_PRIVILEGES, 12, "UInt")
	DllCall("Advapi32\AdjustTokenPrivileges", Ptr, token, Int, false, Ptr, &TOKEN_PRIVILEGES, UInt, 0, Ptr, 0, Ptr, 0)
	res := A_LastError
	DllCall("CloseHandle", Ptr, token)
	DllCall("CloseHandle", Ptr, hProc)
	Return res  ; в случае удачи 0
}

	;  http://www.autohotkey.com/board/topic/69254-func-api-getwindowinfo-ahk-l/#entry438372

GetClientPos(hwnd, ByRef left, ByRef top, ByRef w, ByRef h) {
	VarSetCapacity(pwi, 60, 0), NumPut(60, pwi, 0, "UInt")
	DllCall("GetWindowInfo", "Ptr", hwnd, "UInt", &pwi)
	top := NumGet(pwi, 24, "Int") - NumGet(pwi, 8, "Int")
	left := NumGet(pwi, 52, "Int")
	w := NumGet(pwi, 28, "Int") - NumGet(pwi, 20, "Int")
	h := NumGet(pwi, 32, "Int") - NumGet(pwi, 24, "Int")
}

	;  http://forum.script-coding.com/viewtopic.php?pid=81833#p81833

SelectFilePath(FilePath) {
	If !FileExist(FilePath)
		Return
	SplitPath, FilePath,, Dir
	for window in ComObjCreate("Shell.Application").Windows  {
		ShellFolderView := window.Document
		Try If ((Folder := ShellFolderView.Folder).Self.Path != Dir)
			Continue
		Catch
			Continue
		for item in Folder.Items  {
			If (item.Path != FilePath)
				Continue
			ShellFolderView.SelectItem(item, 1|4|8|16)
			WinActivate, % "ahk_id" window.hwnd
			Return
		}
	}
	Run, %A_WinDir%\explorer.exe /select`, "%FilePath%", , UseErrorLevel
}

GetCLSIDExplorer(hwnd) {
	for window in ComObjCreate("Shell.Application").Windows
		If (window.hwnd = hwnd)
			Return (CLSID := window.Document.Folder.Self.Path) ~= "^::\{" ? "`n<span class='param'>CLSID: </span><span name='MS:'>" CLSID "</span>": ""
}

ViewStyles(elem) {
	elem.innerText := (w_ShowStyles := !w_ShowStyles) ? " show styles " : " hide styles "
	If w_ShowStyles
		Styles := GetStyles(oDoc.getElementById("c_Style").innerText, oDoc.getElementById("c_ExStyle").innerText)
	oDoc.getElementById("WinStyles").innerHTML := Styles
	HTML_Win := oBody.innerHTML
}

	;  http://msdn.microsoft.com/en-us/library/windows/desktop/ms632600(v=vs.85).aspx
	;  http://msdn.microsoft.com/en-us/library/windows/desktop/ff700543(v=vs.85).aspx

GetStyles(Style, ExStyle) {
	Static Styles := {"WS_BORDER":"0x00800000", "WS_CAPTION":"0x00C00000", "WS_CHILD":"0x40000000", "WS_CHILDWINDOW":"0x40000000"
		, "WS_CLIPCHILDREN":"0x02000000", "WS_CLIPSIBLINGS":"0x04000000", "WS_DISABLED":"0x08000000", "WS_DLGFRAME":"0x00400000"
		, "WS_GROUP":"0x00020000", "WS_HSCROLL":"0x00100000", "WS_ICONIC":"0x20000000", "WS_MAXIMIZE":"0x01000000"
		, "WS_MAXIMIZEBOX":"0x00010000", "WS_MINIMIZE":"0x20000000", "WS_MINIMIZEBOX":"0x00020000", "WS_POPUP":"0x80000000"
		, "WS_OVERLAPPED":"0x00000000", "WS_SIZEBOX":"0x00040000", "WS_SYSMENU":"0x00080000", "WS_TABSTOP":"0x00010000"
		, "WS_THICKFRAME":"0x00040000", "WS_TILED":"0x00000000", "WS_VISIBLE":"0x10000000", "WS_VSCROLL":"0x00200000"}

		, ExStyles := {"WS_EX_ACCEPTFILES":"0x00000010", "WS_EX_APPWINDOW":"0x00040000", "WS_EX_CLIENTEDGE":"0x00000200"
		, "WS_EX_COMPOSITED":"0x02000000", "WS_EX_CONTEXTHELP":"0x00000400", "WS_EX_CONTROLPARENT":"0x00010000"
		, "WS_EX_DLGMODALFRAME":"0x00000001", "WS_EX_LAYERED":"0x00080000", "WS_EX_LAYOUTRTL":"0x00400000"
		, "WS_EX_LEFT":"0x00000000", "WS_EX_LEFTSCROLLBAR":"0x00004000", "WS_EX_LTRREADING":"0x00000000"
		, "WS_EX_MDICHILD":"0x00000040", "WS_EX_NOACTIVATE":"0x08000000", "WS_EX_NOINHERITLAYOUT":"0x00100000"
		, "WS_EX_NOPARENTNOTIFY":"0x00000004", "WS_EX_NOREDIRECTIONBITMAP":"0x00200000", "WS_EX_RIGHT":"0x00001000"
		, "WS_EX_RIGHTSCROLLBAR":"0x00000000", "WS_EX_RTLREADING":"0x00002000", "WS_EX_STATICEDGE":"0x00020000"
		, "WS_EX_TOOLWINDOW":"0x00000080", "WS_EX_TOPMOST":"0x00000008", "WS_EX_TRANSPARENT":"0x00000020"
		, "WS_EX_WINDOWEDGE":"0x00000100"}

	For K, V In Styles
		Ret .= Style & V ? "<span name='MS:'>" K " := <span class='param' name='MS:'>" V "</span></span>`n" : ""
	For K, V In ExStyles
		RetEx .= ExStyle & V ? "<span name='MS:'>" K " := <span class='param' name='MS:'>" V "</span></span>`n" : ""
	If Ret !=
		Res .= _T1 " ( Styles ) </span>" _T2 _PRE1 Ret _PRE2
	If RetEx !=
		Res .= _T1 " ( ExStyles )</span>" _T2 _PRE1 RetEx _PRE2
	Return Res
}

GetLangName(hWnd) {
	Static LOCALE_SENGLANGUAGE := 0x1001
	Locale := DllCall("GetKeyboardLayout", Ptr, DllCall("GetWindowThreadProcessId", Ptr, hWnd, UInt, 0, Ptr), Ptr) & 0xFFFF
	Size := DllCall("GetLocaleInfo", UInt, Locale, UInt, LOCALE_SENGLANGUAGE, UInt, 0, UInt, 0) * 2
	VarSetCapacity(lpLCData, Size, 0)
	DllCall("GetLocaleInfo", UInt, Locale, UInt, LOCALE_SENGLANGUAGE, Str, lpLCData, UInt, Size)
	Return lpLCData
}

ChangeLocal(hWnd) {
	Static WM_INPUTLANGCHANGEREQUEST := 0x0050, INPUTLANGCHANGE_FORWARD := 0x0002
	SendMessage, WM_INPUTLANGCHANGEREQUEST, INPUTLANGCHANGE_FORWARD, , , % "ahk_id" hWnd
}

ToolTip(text, time = 500) {
	CoordMode, Mouse
	CoordMode, ToolTip
	MouseGetPos, X, Y
	ToolTip, %text%, X-10, Y-45
	SetTimer, HideToolTip, -%time%
	Return 1

	HideToolTip:
		ToolTip
		Return
}

ConfirmAction(Action) {
	If (!isPaused && bool := 1)
		Gosub, PausedScript  
	isConfirm := 1
	bool2 := MsgConfirm(Action, "AhkSpy", hGui) 
	isConfirm := 0
	If bool
		Gosub, PausedScript
	If !bool2 
		Exit
	Return 1
}

MsgConfirm(Info, Title, hWnd) {
	Static IsStart, hMsgBox, Text, Yes, No, WinW, WinH
	If !IsStart && (IsStart := 1) { 
		Gui, MsgBox:+HWNDhMsgBox -DPIScale -SysMenu +Owner%hWnd% +AlwaysOnTop
		Gui, MsgBox:Font, % "s" (A_ScreenDPI = 120 ? 10 : 12)
		Gui, MsgBox:Color, FFFFFF
		Gui, MsgBox:Add, Text, w200 vText r1 Center
		Gui, MsgBox:Font
		Gui, MsgBox:Add, Button, w88 vYes xp+4 y+20 gMsgBoxLabel, Yes
		Gui, MsgBox:Add, Button, w88 vNo x+20 gMsgBoxLabel, No  
		Gui, MsgBox:Show, Hide NA
		Gui, MsgBox:Show, Hide AutoSize 
		WinGetPos, , , WinW, WinH, ahk_id %hMsgBox% 
	}
	Gui, MsgBox:+Owner%hWnd% +AlwaysOnTop
	Gui, %hWnd%:+Disabled
	GuiControl, MsgBox:Text, Text, % Info
	CoordMode, Mouse
	MouseGetPos, X, Y
	x := X - (WinW / 2)
	y := Y - WinH - 10
	Gui, MsgBox: Show, Hide x%x% y%y%, % Title
	Gui, MsgBox: Show, x%x% y%y%, % Title
	GuiControl, MsgBox:+Default, No
	GuiControl, MsgBox:Focus, No
	While (RetValue = "")
		Sleep 30
	Gui, %hWnd%:-Disabled
	Gui, MsgBox: Show, Hide
	Return RetValue

	MsgBoxLabel:
		RetValue := {Yes:1,No:0}[A_GuiControl]
		Return
}

MouseStep(x, y) {
	MouseMove, x, y, 0, R
	If (Sleep != 1 && !isPaused && ThisMode != "Hotkey" && WinActive("ahk_id" hGui))
	{
		(ThisMode = "Control" ? (Spot_Control() (StateAllwaysSpot ? Spot_Win() : 0) Write_Control()) : (Spot_Win() (StateAllwaysSpot ? Spot_Control() : 0) Write_Win()))
		ZoomMsg(2)
	}
}

IsIEFocus() {
	ControlGetFocus, Focus
	Return InStr(Focus, "Internet")
}

NextLink(s = "") {
	curpos := oDocEl.scrollTop, oDocEl.scrollLeft := 0
	If (!curpos && s = "-")
		Return
	While (pos := oDoc.getElementsByTagName("a").item(A_Index-1).getBoundingClientRect().top) != ""
		(s 1) * pos > 0 && (!res || abs(res) > abs(pos)) ? res := pos : ""       ; http://forum.script-coding.com/viewtopic.php?pid=82360#p82360
	If (res = "" && s = "")
		Return
	st := !res ? -curpos : res, co := abs(st) > 150 ? 20 : 10
	Loop % co
		oDocEl.scrollTop := curpos + (st*(A_Index/co))
	oDocEl.scrollTop := curpos + res
}

UpdateAhkSpy(in = 1) {
	Static att, Ver, req
		, url1 := "https://raw.githubusercontent.com/serzh82saratov/AhkSpy/master/Readme.txt"
		, url2 := "https://raw.githubusercontent.com/serzh82saratov/AhkSpy/master/AhkSpy.ahk"
	If !req
		req := ComObjCreate("WinHttp.WinHttpRequest.5.1"), req.Option(6) := 0
	req.open("GET", url%in%, 1), req.send(), att := 0
	SetTimer, Upd_Verifi, -3000
	Return

	Upd_Verifi:
		If (Status := req.Status) = 200
		{
			Text := req.responseText
			If (req.Option(1) = url1)
				Return (Ver := RegExReplace(Text, "i).*?version\s*(.*?)\R.*", "$1")) > AhkSpyVersion ? UpdateAhkSpy(2) : 0
			If (!InStr(Text, "AhkSpyVersion"))
				Return
			If InStr(FileExist(A_ScriptFullPath), "R")
			{
				MsgBox, % 16+262144+8192, AhkSpy, Exist new version %Ver%!`n`nBut the file has an attribute "READONLY".`nUpdate imposible.
				Return
			}
			MsgBox, % 4+32+262144+8192, AhkSpy, Exist new version!`nUpdate v%AhkSpyVersion% to v%Ver%?
			IfMsgBox, No
				Return
			File := FileOpen(A_ScriptFullPath, "w", "UTF-8")
			File.Length := 0, File.Write(Text), File.Close()
			Reload
		}
		Error := (++att = 20 || Status != "")
		SetTimer, % Error ? "UpdateAhkSpy" : "Upd_Verifi", % Error ? -60000 : -3000
		Return
}

TaskbarProgress(state, hwnd, pct = "") {
	static tbl
	if !tbl {
		try tbl := ComObjCreate("{56FDF344-FD6D-11d0-958A-006097C9A090}", "{ea1afb91-9e28-4b86-90e9-9e9f8a5eefaf}")
		catch
			tbl := "error"
	}
	if tbl = error
		Return
	DllCall(NumGet(NumGet(tbl+0)+10*A_PtrSize), "ptr", tbl, "ptr", hwnd, "uint", state)
	if pct !=
		DllCall(NumGet(NumGet(tbl+0)+9*A_PtrSize), "ptr", tbl, "ptr", hwnd, "int64", pct, "int64", 100)
}

HighLight(elem, time = "", RemoveFormat = 1) {
	If (elem.OuterText = "")
		Return
	Try SetTimer, UnHighLight, % "-" time 
	R := oBody.createTextRange()
	(RemoveFormat ? R.execCommand("RemoveFormat") : 0)
	R.collapse(1), R.select()
	R.moveToElementText(elem) 
	R.execCommand("ForeColor", 0, "FFFFFF")
	R.execCommand("BackColor", 0, "3399FF")
	Return

	UnHighLight:
		oBody.createTextRange().execCommand("RemoveFormat")
		Return
}

	; _________________________________________________ FullScreen _________________________________________________

FullScreenMode() {
	Static Max, hFunc
	hwnd := WinExist("ahk_id" hGui)
	If !FullScreenMode
	{
		FullScreenMode := 1
		Menu, Sys, Check, Full screen
		WinGetNormalPos(hwnd, X, Y, W, H)
		WinGet, Max, MinMax, ahk_id %hwnd%
		If Max = 1
			WinSet, Style, -0x01000000	;	WS_MAXIMIZE
		Gui, 1: -ReSize -Caption
		Gui, 1: Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%
		Gui, 1: Maximize
		WinSetNormalPos(hwnd, X, Y, W, H)
		hFunc := Func("ControlsMove").Bind(A_ScreenWidth, A_ScreenHeight)
	}
	Else
	{
		Gui, 1: +ReSize +Caption
		If Max = 1
		{
			WinGetNormalPos(hwnd, X, Y, W, H)
			Gui, 1: Maximize
			WinSetNormalPos(hwnd, X, Y, W, H)
		}
		Else
			Gui, 1: Restore
		Sleep 20
		GetClientPos(hwnd, _, _, Width, Height)
		hFunc := Func("ControlsMove").Bind(Width, Height)
		FullScreenMode := 0
		Menu, Sys, UnCheck, Full screen
	}
	SetTimer, % hFunc, -10
}

WinGetNormalPos(hwnd, ByRef x, ByRef y, ByRef w, ByRef h) {
	VarSetCapacity(wp, 44), NumPut(44, wp)
	DllCall("GetWindowPlacement", "Ptr", hwnd, "Ptr", &wp)
	x := NumGet(wp, 28, "int"), y := NumGet(wp, 32, "int")
	w := NumGet(wp, 36, "int") - x,  h := NumGet(wp, 40, "int") - y
}

WinSetNormalPos(hwnd, x, y, w, h) {
	VarSetCapacity(wp, 44, 0), NumPut(44, wp, 0, "uint")
	DllCall("GetWindowPlacement", "Ptr", hWnd, "Ptr", &wp)
	NumPut(x, wp, 28, "int"), NumPut(y, wp, 32, "int")
	NumPut(w + x, wp, 36, "int"), NumPut(h + y, wp, 40, "int")
	DllCall("SetWindowPlacement", "Ptr", hWnd, "Ptr", &wp)
}

	; _________________________________________________ Find _________________________________________________

FindView() {
	If isFindView
		Return FindHide()
	GuiControlGet, p, 1:Pos, %hActiveX%
	GuiControl, 1:Move, %hActiveX%, % "x" pX " y" pY " w" pW " h" pH - 28
	Gui, F: Show, % "NA x" (pW - widthTB) // 2.2 " h26 y" (pY + pH - 27)
	isFindView := 1 
	GuiControl, F:Focus, Edit1
	FindSearch(1)
}

FindHide() {
	Gui, F: Show, Hide
	GuiControlGet, a, 1:Pos, %hActiveX%
	GuiControl, 1:Move, %hActiveX%, % "x" aX "y" aY "w" aW "h" aH + 28
	isFindView := 0
	GuiControl, Focus, %hActiveX%
}

FindOption(Hwnd) {
	GuiControlGet, p, Pos, %Hwnd%
	If pX =
		Return
	ControlGet, Style, Style,, , ahk_id %Hwnd%
	ControlGetText, Text, , ahk_id %Hwnd%
	DllCall("DestroyWindow", "Ptr", Hwnd)
	Gui, %A_Gui%: Add, Text, % "x" pX " y" pY " w" pW " h" pH " g" A_ThisFunc " " (Style & 0x1000 ? "c2F2F2F +0x0201" : "+Border +0x1201"), % Text
	InStr(Text, "sensitive") ? (oFind.Registr := !(Style & 0x1000)) : (oFind.Whole := !(Style & 0x1000))
	FindSearch(1)
	FindAll()
}

FindNew(Hwnd) {
	ControlGetText, Text, , ahk_id %Hwnd%
	oFind.Text := Text
	hFunc := Func("FindSearch").Bind(1)
	SetTimer, FindAll, -150
	SetTimer, % hFunc, -150
}

FindNext(Hwnd) {
	SendMessage, 0x400+114,,,, ahk_id %Hwnd%		;  UDM_GETPOS32
	Back := !ErrorLevel
	FindSearch(0, Back)
}

FindAll() {
	If (oFind.Text = "")
	{
		GuiControl, F:Text, FindMatches
		Return
	}
	R := oBody.createTextRange() 
	Matches := 0
	R.collapse(1)
	Option := (oFind.Whole ? 2 : 0) ^ (oFind.Registr ? 4 : 0)
	Loop
	{
		F := R.findText(oFind.Text, 1, Option)
		If (F = 0)
			Break
		El := R.parentElement()
		If (El.TagName = "INPUT" || El.className ~= "^(button|title|param)$") && !R.collapse(0)  ;	https://msdn.microsoft.com/en-us/library/ff976065(v=vs.85).aspx
			Continue
		; R.execCommand("BackColor", 0, "EF0FFF")
		; R.execCommand("ForeColor", 0, "FFEEFF")
		R.collapse(0), ++Matches
	}
	GuiControl, F:Text, FindMatches, % Matches ? Matches : ""
}

FindSearch(New, Back = 0) {
	Global hFindEdit
	R := oDoc.selection.createRange()
	sR := R.duplicate()
	R.collapse(New || Back ? 1 : 0)
	If (oFind.Text = "" && !R.select())
		SetEditColor(hFindEdit, 0xFFFFFF, 0x000000)
	Else {
		Option := (Back ? 1 : 0) ^ (oFind.Whole ? 2 : 0) ^ (oFind.Registr ? 4 : 0)
		Loop {
			F := R.findText(oFind.Text, 1, Option)
			If (F = 0) {
				If !A {
					R.moveToElementText(oBody), R.collapse(!Back), A := 1
					Continue
				}
				If New
					sR.collapse(1), sR.select()
				Break
			}
			If (!New && R.isEqual(sR)) {
				If A {
					hFunc := Func("SetEditColor").Bind(hFindEdit, 0xFFFFFF, 0x000000)
					SetTimer, % hFunc, -200
				}
				Break
			}
			El := R.parentElement()
			
			If (El.TagName = "INPUT" || El.className ~= "^(button|title|param)$") && !R.collapse(Back)
				Continue
			R.select(), F := 1
			Break
		}
		If (F != 1)
			SetEditColor(hFindEdit, 0x6666FF, 0x000000)
		Else
			SetEditColor(hFindEdit, 0xFFFFFF, 0x000000)
	}
}
	; _________________________________________________ Mouse hover selection _________________________________________________

MS_Cancel() {
	If oMS.ELSel
		oMS.ELSel.style.backgroundColor := "", oMS.ELSel := ""
}

MS_SelectionCheck() {
	Selection := oDoc.selection.createRange().text != ""
	If Selection
		(!oMS.Selection && MS_Cancel())
	Else If oMS.Selection && MS_IsSelect(EL := oDoc.elementFromPoint(oMS.SCX, oMS.SCY))
		MS_Select(EL)
	oMS.Selection := Selection
}

MS_MouseOver() {
	EL := oMS.EL
	If !MS_IsSelect(EL)
		Return
	MS_Select(EL)
}

MS_IsSelect(EL) {
	If InStr(EL.Name, "MS:")
		Return 1
}

MS_Select(EL) {
	If InStr(EL.Name, ":S")
		oMS.ELSel := EL.ParentElement, oMS.ELSel.style.background := "#" ColorSelMouseHover
	Else If InStr(EL.Name, ":N")
		oMS.ELSel := oDoc.all.item(EL.sourceIndex + 1), oMS.ELSel.style.background := "#" ColorSelMouseHover
	Else If InStr(EL.Name, ":P")
		oMS.ELSel := oDoc.all.item(EL.sourceIndex - 1).ParentElement, oMS.ELSel.style.background := "#" ColorSelMouseHover
	Else
		oMS.ELSel := EL, EL.style.background := "#" ColorSelMouseHover
}

	; _________________________________________________ Load JScripts _________________________________________________

ChangeCSS(id, css) {	;  https://webo.in/articles/habrahabr/68-fast-dynamic-css/ 
	oDoc.getElementById(id).styleSheet.cssText := css
}

LoadJScript() {
	Static onhkinput
	PreOver_ := PreOverflowHide ? _PreOverflowHideCSS : ""
	BodyWrap_ := WordWrap ? _BodyWrapCSS : ""
html =
(
<head>
	<style id='css_ColorBg' type="text/css">.title, .button {background-color: #%ColorBg%;}</style> 
	<style id='css_PreOverflowHide' type="text/css">%PreOver_%</style>
	<style id='css_Body' type="text/css">%BodyWrap_%</style> 
</head>

<script type="text/javascript">
	var prWidth, WordWrap, MoveTitles, key1, key2;
	function shift(scroll) {
		var col, Width, clientWidth, scrollLeft, Offset;
		clientWidth = document.documentElement.clientWidth; 
		if (clientWidth < 0)
			return
		scrollLeft = document.documentElement.scrollLeft;
		Width = (clientWidth + scrollLeft);
		if (scroll && Width == prWidth)
			return
		if (MoveTitles == 1) {
			Offset = ((clientWidth / 100 * 30) + scrollLeft);
			col = document.querySelectorAll('.con');
			for (var i = 0; i < col.length; i++) {
				col[i].style.left = Offset + "px";
			}
		}
		col = document.querySelectorAll('.box');
		for (var i = 0; i < col.length; i++) {
			col[i].style.width = Width + 'px';
		}
		prWidth = Width;
	}
	function conleft30() {
		col = document.querySelectorAll('.con');
		for (var i = 0; i < col.length; i++) {
			col[i].style.left = "30`%";
		} 
	}
	function menuitemdisplay(param) {
		col = document.querySelectorAll('.menuitemid');
		for (var i = 0; i < col.length; i++) {
			col[i].style.display = param;
		} 
	}
	function removemenuitem(parent, selector) {
		col = parent.querySelectorAll(selector);
		for (var i = 0; i < col.length; i++) {  
			parent.removeChild(col[i])  
		} 
	}
	onresize = function() {
		shift(0);
	}
	onscroll = function() {
		if (WordWrap == 1)
			return
		shift(1);
	}
	function OnButtonDown (el) { 
		if (window.event.button != 1)   //  only left button https://msdn.microsoft.com/en-us/library/aa703876(v=vs.85).aspx
			return
		el.style.backgroundColor = "#%ColorSelMouseHover%";
		el.style.color = "#fff";
		el.style.border = "1px solid black";
	}
	function OnButtonUp (el) { 
		el.style.backgroundColor = "";
		el.style.color = (el.name != "pre" ? "#%ColorFont%" : "#%ColorParam%");
		if (window.event.button == 2 && el.parentElement.className == 'BB') 
			document.documentElement.focus();
	}
	function OnButtonOver (el) {
		el.style.zIndex = "2";
		el.style.border = "1px solid black";
	}
	function OnButtonOut (el) {
		el.style.zIndex = "0";
		el.style.backgroundColor = "";
		el.style.color = (el.name != "pre" ? "#%ColorFont%" : "#%ColorParam%");
		el.style.border = "1px dotted black";
	}  
	function Assync (param) {
		setTimeout(param, 1);
	}
	//	alert(value);
</script>

<script id='hkinputevent' type="text/javascript"> 
	function funchkinputevent(el, event) {
		key1 = el, key2 = event;
		hkinputevent.click(); 
	}
</script>
)
oDoc.Write("<!DOCTYPE html><head><meta http-equiv=""X-UA-Compatible"" content=""IE=8""></head>" html)
oDoc.Close()
ComObjConnect(onhkinput := oDoc.getElementById("hkinputevent"), "onhkinput_")
}
	; _________________________________________________ Doc Events _________________________________________________


onhkinput_onclick() {  ;	http://forum.script-coding.com/viewtopic.php?id=8206 
	If (oJScript.key2 = "focus")
		Sleep(1), Hotkey_Hook(0)
	Else If (WinActive("ahk_id" hGui) && !isPaused && ThisMode = "Hotkey")
		Sleep(1), Hotkey_Hook(1)
}

Class Events {  ;	http://forum.script-coding.com/viewtopic.php?pid=82283#p82283
	onclick() {
	Global CopyText
		oevent := oDoc.parentWindow.event.srcElement
		If (oevent.ClassName = "button" || oevent.tagname = "button")
			return ButtonClick(oevent)
		tagname := oevent.tagname
		If (ThisMode = "Hotkey" && !Hotkey_Arr("Hook") && !isPaused && tagname ~= "PRE|SPAN")
			Hotkey_Hook(1)
	}
	ondblclick() {
		oevent := oDoc.parentWindow.event.srcElement
		If (oevent.ClassName = "button" || oevent.tagname = "button")
			return ButtonClick(oevent)
		If (oevent.tagname != "input" && (rng := oDoc.selection.createRange()).text != "" && oevent.isContentEditable)
		{
			While !t
				rng.moveEnd("character", 1), (SubStr(rng.text, 0) = "_" ? rng.moveEnd("word", 1)
					: (rng.moveEnd("character", -1), t := 1))
			While t
				rng.moveStart("character", -1), (SubStr(rng.text, 1, 1) = "_" ? rng.moveStart("word", -1)
					: (rng.moveStart("character", 1), t := 0))
			sel := rng.text, rng.moveEnd("character", StrLen(RTrim(sel)) - StrLen(sel)), rng.select()
		}
	}
    onmouseover() {
		If oMS.Selection
			Return
		oMS.EL := oDoc.parentWindow.event.srcElement
		SetTimer, MS_MouseOver, -50
    }
	onmouseout() {
		MS_Cancel()
    }
	onselectionchange() {
		e := oDoc.parentWindow.event
		oMS.SCX := e.clientX, oMS.SCY := e.clientY
		SetTimer, MS_SelectionCheck, -70
    }
	onselectstart() {
		SetTimer, MS_Cancel, -8
    }
	SendMode() {
		IniWrite(SendMode := {Send:"SendInput",SendInput:"SendPlay",SendPlay:"SendEvent",SendEvent:"Send"}[SendMode], "SendMode")
		SendModeStr := Format("{:L}", SendMode), oDoc.getElementById("SendMode").innerText := " " SendModeStr " "
	}
	SendCode() {
		IniWrite(SendCode := {vk:"sc",sc:"name",name:"vk"}[SendCode], "SendCode")
		oDoc.getElementById("SendCode").innerText := " " SendCode " "
	}
	num_scroll(thisid) {
		(OnHook := Hotkey_Arr("Hook")) ? Hotkey_Hook(0) : 0
		SendInput, {%thisid%}
		(OnHook ? Hotkey_Hook(1) : 0)
		ToolTip(thisid " " (GetKeyState(thisid, "T") ? "On" : "Off"), 500)
	}
}

ButtonClick(oevent) { 
	thisid := oevent.id
	If (thisid = "copy_wintext")
		o := oDoc.getElementById("wintextcon")
		, GetKeyState("Shift", "P") ? ClipAdd(o.OuterText, 1) : (Clipboard := o.OuterText), HighLight(o, 500)
	Else If (thisid = "wintext_hidden")
	{    
		R := oBody.createTextRange(), R.collapse(1), R.select()
		oDoc.getElementById("wintextcon").disabled := 1
		DetectHiddenText, % DetectHiddenText := (DetectHiddenText = "on" ? "off" : "on") 
		IniWrite(DetectHiddenText, "DetectHiddenText")
		If !WinExist("ahk_id" oOther.WinID) && ToolTip("Window not exist", 500)
			Return oDoc.getElementById("wintext_hidden").innerText := " hidden - " DetectHiddenText " "
		WinGetText, WinText, % "ahk_id" oOther.WinID
		oDoc.getElementById("wintextcon").innerHTML := "<pre>" TransformHTML(WinText) "</pre>"
		HTML_Win := oBody.innerHTML
		Sleep 200
		oDoc.getElementById("wintextcon").disabled := 0
		oDoc.getElementById("wintext_hidden").innerText := " hidden - " DetectHiddenText " " 
	}
	Else If (thisid = "menu_idview")
	{   
		IniWrite(MenuIdView := !MenuIdView, "MenuIdView")
		oJScript.menuitemdisplay(!MenuIdView ? "none" : "inline")
		oDoc.getElementById("menu_idview").innerText :=  " id - " (MenuIdView ? "view" : "hide") " "  
	}
	Else If (thisid = "copy_menutext")
	{
		pre_menutext := oDoc.getElementById("pre_menutext")
		preclone := pre_menutext.cloneNode(true)
		oJScript.removemenuitem(preclone, ".menuitemsub")
		If !MenuIdView
			oJScript.removemenuitem(preclone, ".menuitemid") 
		GetKeyState("Shift", "P") ? ClipAdd(preclone.OuterText, 1) : (Clipboard := preclone.OuterText)
		HighLight(pre_menutext, 500), preclone := ""
	}
	Else If (thisid = "copy_button") 
		o := oDoc.all.item(oevent.sourceIndex + 2)
		, GetKeyState("Shift", "P") ? ClipAdd(o.OuterText, 1) : (Clipboard := o.OuterText), HighLight(o, 500)  
	Else If thisid = copy_alltitle
	{ 
		Text := (t:=oDoc.getElementById("wintitle1").OuterText) . (t = "" ? "" : " ")
		. oDoc.getElementById("wintitle2").OuterText " " oDoc.getElementById("wintitle3").OuterText
		GetKeyState("Shift", "P") ? ClipAdd(Text, 1) : (Clipboard := Text)
		HighLight(oDoc.getElementById("wintitle1"), 500)
		HighLight(oDoc.getElementById("wintitle2"), 500, 0), HighLight(oDoc.getElementById("wintitle2_"), 500, 0)
		HighLight(oDoc.getElementById("wintitle3"), 500, 0), HighLight(oDoc.getElementById("wintitle3_"), 500, 0)
	}
	Else If thisid = copy_sbtext
	{  
		Loop % oDoc.getElementById("copy_sbtext").name
			el := oDoc.getElementById("sb_field_" A_Index), HighLight(el, 500, (A_Index = 1)), Text .= el.OuterText "`n"
		Text := RTrim(Text, "`n"), GetKeyState("Shift", "P") ? ClipAdd(Text, 1) : (Clipboard := Text)
	}
	Else If thisid = keyname
	{ 
		edithotkey := oDoc.getElementById("edithotkey"), editkeyname := oDoc.getElementById("editkeyname")
		v_edit := Format("{:L}", edithotkey.value), name := GetKeyName(v_edit)
		If (name = v_edit)
			editkeyname.value := Format("vk{:X}", GetKeyVK(v_edit)) (!(sc := GetKeySC(v_edit)) ? "" : Format("sc{:X}", sc))
		Else
			editkeyname.value := (StrLen(name) = 1 ? (Format("{:U}", name)) : name)
		o := name = "" ? edithotkey : editkeyname
		o.focus(), o.createTextRange().select()
	}
	Else If thisid = hook_reload
	{ 
		Suspend On
		Suspend Off 
		bool := Hotkey_Arr("Hook"), Hotkey_SetHook(0), Hotkey_SetHook(1), Hotkey_Arr("Hook", bool), ToolTip("Ok", 300)
	}
	Else If thisid = pause_button
		Gosub, PausedScript
	Else If thisid = infolder
	{
		If FileExist(FilePath := oDoc.getElementById("copy_processpath").OuterText)
			SelectFilePath(FilePath), Minimize()
		Else
			ToolTip("Not file exist", 500)
	}
	Else If thisid = paste_process_path
		oDoc.getElementById("copy_processpath").innerHTML := TransformHTML(Trim(Trim(Clipboard), """"))
	Else If thisid = w_command_line
		RunRealPath(oDoc.getElementById("c_command_line").OuterText)
	Else If thisid = paste_command_line
		oDoc.getElementById("c_command_line").innerHTML := TransformHTML(Clipboard)
	Else If (thisid = "process_close" && (oOther.WinPID || !ToolTip("Invalid parametrs", 500)) && ConfirmAction("Process close?"))
		Process, Close, % oOther.WinPID
	Else If (thisid = "win_close" && (oOther.WinPID || !ToolTip("Invalid parametrs", 500)) && ConfirmAction("Window close?"))
		WinClose, % "ahk_id" oOther.WinID
	Else If (thisid = "SendCode")
		Events.SendCode()
	Else If (thisid = "SendMode")
		Events.SendMode()
	Else If (thisid = "numlock" || thisid = "scrolllock")
		Events.num_scroll(thisid)
	Else If thisid = locale_change
		ToolTip(ChangeLocal(hActiveX) GetLangName(hActiveX), 500)
	Else If thisid = paste_keyname
		edithotkey := oDoc.getElementById("edithotkey"), edithotkey.value := "", edithotkey.focus()
		, oDoc.execCommand("Paste"), oDoc.getElementById("keyname").click()
	Else If (thisid = "copy_selected" && ExistSelectedText(CopyText) && ToolTip("copy", 500))
		GoSub CopyText
	Else If thisid = get_styles
		ViewStyles(oevent)
	Else If thisid = run_AccViewer
		RunAhkPath(ExtraFile("AccViewer Source"))
	Else If thisid = run_iWB2Learner
		RunAhkPath(ExtraFile("iWB2 Learner"))
	Else If thisid = set_button_pos
	{
		HayStack := oevent.OuterText = "Pos:"
		? oDoc.all.item(oevent.sourceIndex + 1).OuterText " " oDoc.all.item(oevent.sourceIndex + 7).OuterText
		: oDoc.all.item(oevent.sourceIndex - 5).OuterText " " oDoc.all.item(oevent.sourceIndex + 1).OuterText
		RegExMatch(HayStack, "(-*\d+[\.\d+]*).*\s+.*?(-*\d+[\.\d+]*).*\s+.*?(-*\d+[\.\d+]*).*\s+.*?(-*\d+[\.\d+]*)", p)
		If (p1 + 0 = "" || p2 + 0 = "" || p3 + 0 = "" || p4 + 0 = "")
			Return ToolTip("Invalid parametrs", 500)
		If (ThisMode = "Win")
			WinMove, % "ahk_id " oOther.WinID, , p1, p2, p3, p4
		Else
			ControlMove, , p1, p2, p3, p4, % "ahk_id " oOther.MouseControlID
	}
	Else If thisid = set_button_focus_ctrl
	{
		hWnd := oOther.MouseControlID
		ControlFocus, , ahk_id %hWnd%
		WinGetPos, X, Y, W, H, ahk_id %hWnd%
		If (X + Y != "")
			DllCall("SetCursorPos", "Uint", X + W // 2, "Uint", Y + H // 2)
	}
	Else If thisid = set_pos
	{
		thisbutton := oevent.OuterText
		If thisbutton != Screen:
		{
			hWnd := oOther.MouseWinID
			If !WinExist("ahk_id " hwnd)
				Return ToolTip("Window not exist", 500)
			WinGet, Min, MinMax, % "ahk_id " hwnd
			If Min = -1
				Return ToolTip("Window minimize", 500)
			WinGetPos, X, Y, W, H, ahk_id %hWnd%
		}
		If thisbutton = Relative window:
		{
			RegExMatch(oDoc.all.item(oevent.sourceIndex + 1).OuterText, "(-*\d+[\.\d+]*).*\s+.*?(-*\d+[\.\d+]*)", p)
			If (p1 + 0 = "" || p2 + 0 = "")
				Return ToolTip("Invalid parametrs", 500)
			BlockInput, MouseMove
			DllCall("SetCursorPos", "Uint", X + Round(W * p1), "Uint", Y + Round(H * p2))
		}
		Else If thisbutton = Relative client:
		{
			RegExMatch(oDoc.all.item(oevent.sourceIndex + 1).OuterText, "(-*\d+[\.\d+]*).*\s+.*?(-*\d+[\.\d+]*)", p)
			If (p1 + 0 = "" || p2 + 0 = "")
				Return ToolTip("Invalid parametrs", 500)
			GetClientPos(hWnd, caX, caY, caW, caH)
			DllCall("SetCursorPos", "Uint", X + Round(caW * p1) + caX, "Uint", Y + Round(caH * p2) + caY)
		}
		Else
		{
			RegExMatch(oDoc.all.item(oevent.sourceIndex + 1).OuterText, "(-*\d+[\.\d+]*).*\s+.*?(-*\d+[\.\d+]*)", p)
			If (p1 + 0 = "" || p2 + 0 = "")
				Return ToolTip("Invalid parametrs", 500)
			BlockInput, MouseMove
			If thisbutton = Screen:
				DllCall("SetCursorPos", "Uint", p1, "Uint", p2)
			Else If thisbutton = Window:
				DllCall("SetCursorPos", "Uint", X + p1, "Uint", Y + p2)
			Else If thisbutton = Mouse relative control:
			{
				hWnd := oOther.MouseControlID
				If !WinExist("ahk_id " hwnd)
					Return ToolTip("Control not exist", 500)
				WinGetPos, X, Y, W, H, ahk_id %hWnd%
				DllCall("SetCursorPos", "Uint", X + p1, "Uint", Y + p2)
			}
			Else If thisbutton = Client:
			{
				GetClientPos(hWnd, caX, caY, caW, caH)
				DllCall("SetCursorPos", "Uint", X + p1 + caX, "Uint", Y + p2 + caY)
			}
		}
		If isPaused
		{
			BlockInput, MouseMoveOff
			Return
		}
		GoSub, SpotProc
		Sleep 350
		HideMarker(), HideAccMarker()
		BlockInput, MouseMoveOff
	}
	Else If thisid = run_zoom
		AhkSpyZoomShow()
}

	; _________________________________________________ SingleInstance _________________________________________________

SingleInstance(Icon = 0) {
	#NoTrayIcon
	#SingleInstance Off
	DetectHiddenWindows, On
	WinGetTitle, MyTitle, ahk_id %A_ScriptHWND%  
	WinGet, id, List, %MyTitle% ahk_class AutoHotkey
	Loop, %id%
	{
		this_id := id%A_Index%
		If (this_id != A_ScriptHWND)
			WinClose, ahk_id %this_id%
	}
	Loop, %id%
	{
		this_id := id%A_Index%
		If (this_id != A_ScriptHWND)
		{
			Start := A_TickCount 
			While WinExist("ahk_id" this_id)
			{
				If (A_TickCount - Start > 1500)
				{
					MsgBox, 8196, , Could not close the previous instance of this script.  Keep waiting?
					IfMsgBox, Yes
					{
						WinClose, ahk_id %this_id%
						Sleep 200
						WinGet, WinPID, PID, ahk_id %this_id%
						Process, Close, %WinPID%
						Start := A_TickCount + 200
						Continue
					}
					OnExit
					ExitApp
				}
				Sleep 1
			}
		}
	}
	If Icon
		Menu, Tray, Icon
}

	; ________________________________________________________________________________________________________
	; _________________________________________________ Zoom _________________________________________________
	; ________________________________________________________________________________________________________

ShowZoom:
hAhkSpy = %2%
If !WinExist("ahk_id" hAhkSpy)
	ExitApp

ActiveNoPause = %3%
AhkSpyPause = %4%
oZoom.AhkSpyPause := AhkSpyPause

ListLines Off
SetBatchLines,-1
CoordMode, Mouse, Screen
OnExit("ZoomOnClose")

Global oZoom := {}, isZoom := 1, hAhkSpy, MsgAhkSpyZoom, ActiveNoPause
OnMessage(0x0020, "WM_SETCURSOR")
OnMessage(0x201, "LBUTTONDOWN") ; WM_LBUTTONDOWN
OnMessage(0xA1, "LBUTTONDOWN") ; WM_NCLBUTTONDOWN
OnMessage(0xF, "WM_Paint")
ZoomCreate()
OnMessage(MsgAhkSpyZoom := DllCall("RegisterWindowMessage", "Str", "MsgAhkSpyZoom"), "Z_MsgZoom")
PostMessage, % MsgAhkSpyZoom, 0, % oZoom.hGui, , ahk_id %hAhkSpy%
SetWinEventHook("EVENT_OBJECT_DESTROY", 0x8001) 
SetWinEventHook("EVENT_SYSTEM_MINIMIZESTART", 0x0016, 0x0017)
WinGet, Min, MinMax, % "ahk_id " hAhkSpy
If Min != -1
	ZoomShow()
SetTimer, CheckAhkSpy, 200
Return

#If isZoom && oZoom.Show

^+#Up::
^+#Down::
+#WheelUp::
+#WheelDown:: ChangeZoom(InStr(A_ThisHotKey, "Up") ? oZoom.Zoom + 1 : oZoom.Zoom - 1)

#If isZoom && (!oZoom.AhkSpyPause && oZoom.Show && !IsMinimize(hAhkSpy))

+#Up:: Z_MouseStep(0, -1)
+#Down:: Z_MouseStep(0, 1)
+#Left:: Z_MouseStep(-1, 0)
+#Right:: Z_MouseStep(1, 0)

#If

Z_MouseStep(x, y) {
	MouseMove, x, y, 0, R
	If oZoom.Pause 
		oZoom.Pause := 0, Magnify(1), oZoom.Pause := 1   
	PostMessage, % MsgAhkSpyZoom, 1, 0, , ahk_id %hAhkSpy%
}

ZoomCreate() {
	oZoom.Zoom := IniRead("MagnifyZoom", 4)
	oZoom.Mark := IniRead("MagnifyMark", "Cross")
	oZoom.MemoryZoomSize := IniRead("MemoryZoomSize", 0)
	oZoom.GuiMinW := 306
	oZoom.GuiMinH := 351
	FontSize := (A_ScreenDPI = 120 ? 10 : 12)
	If oZoom.MemoryZoomSize
		GuiW := IniRead("MemoryZoomSizeW", oZoom.GuiMinW), GuiH := IniRead("MemoryZoomSizeH", oZoom.GuiMinH)
	Else
		GuiW := oZoom.GuiMinW, GuiH := oZoom.GuiMinH
	Gui Zoom: +AlwaysOnTop -DPIScale +hwndhGui +LabelZoomOn -Caption +E0x08000000  ;	 +Owner%hAhkSpy%
	Gui, Zoom: Color, F0F0F0
	DllCall("SetClassLong", "Ptr", hGui, "int", -26
		, "int", DllCall("GetClassLong", "Ptr", hGui, "int", -26) | 0x20000)
	
	Gui, ZoomTB: +HWNDhTBGui -Caption -DPIScale +Parent%hGui% +E0x08000000 +0x40000000 -0x80000000
	Gui, ZoomTB: Font, s%FontSize%
	Gui, ZoomTB: Add, Slider, hwndhSliderZoom gSliderZoom x8 Range1-50 w152 Center AltSubmit NoTicks, % oZoom.Zoom
	Gui, ZoomTB: Add, Text, hwndhTextZoom Center x+10 yp+3 w36, % oZoom.Zoom
	Gui, ZoomTB: Font
	Gui, ZoomTB: Add, Button, hwndhChangeMark gChangeMark x+10 yp w52, % oZoom.Mark
	Gui, ZoomTB: Add, Button, hwndhZoomHideBut gZoomHide x+10 yp, X
	Gui, ZoomTB: Show, x0 y0
	Gui, ZoomTB: Color, F0F0F0
	
	Gui, Zoom: Show, % "Hide w" GuiW " h" GuiH, AhkSpyZoom
	Gui, Zoom: +MinSize

	Gui, Dev: +HWNDhDev -Caption -DPIScale +Parent%hGui% +Border
	Gui, Dev: Add, Text, hwndhDevCon +0xE ;	SS_BITMAP := 0xE
	Gui, Dev: Show, NA
	Gui, Dev: Color, F0F0F0

	oZoom.hdcSrc := DllCall("GetDC", Ptr, 0, Ptr)
	oZoom.hdcDest := DllCall("GetDC", Ptr, hDevCon, Ptr)
	oZoom.hdcMemory := DllCall("CreateCompatibleDC", "Ptr", 0)
	DllCall("Gdi32.Dll\SetStretchBltMode", "Ptr", oZoom.hdcDest, "Int", 4)
	oZoom.hGui := hGui
	oZoom.hDev := hDev
	oZoom.hDevCon := hDevCon
	oZoom.hTBGui := hTBGui
	
	oZoom.vTextZoom := hTextZoom
	oZoom.vChangeMark := hChangeMark
	oZoom.vZoomHideBut := hZoomHideBut
	oZoom.vSliderZoom := hSliderZoom
	
	SysGet, VirtualScreenWidth, 78
	SysGet, VirtualScreenHeight, 79
	hBM := DllCall("Gdi32.Dll\CreateCompatibleBitmap", "Ptr", oZoom.hdcDest, "Int", VirtualScreenWidth, "Int", VirtualScreenHeight)
	DllCall("Gdi32.Dll\SelectObject", "Ptr", oZoom.hdcMemory, "Ptr", hBM), DllCall("DeleteObject", "Ptr", hBM)
	BitBlt(oZoom.hdcMemory, 0, 0, VirtualScreenWidth, VirtualScreenHeight, oZoom.hdcDest, 0, 0, 0xFF0062)  ;	WHITENESS   
}

Magnify(one = 0) {
	Static New
	If (oZoom.Show && (one || !oZoom.Pause && !oZoom.AhkSpyPause) && oZoom.SIZING != 2)
	{
		MouseGetPos, mX, mY, WinID
		If (WinID != oZoom.hGui && WinID != hAhkSpy)
		{ 
			oZoom.MouseX := mX, oZoom.MouseY := mY
			StretchBlt(oZoom.hdcDest, 0, 0, oZoom.nWidthDest, oZoom.nHeightDest
				, oZoom.hdcSrc, mX - oZoom.nXOriginSrcOffset, mY - oZoom.nYOriginSrcOffset, oZoom.nWidthSrc, oZoom.nHeightSrc) 
			For k, v In oZoom.oMarkers[oZoom.Mark]
				StretchBlt(oZoom.hdcDest, v.x, v.y, v.w, v.h, oZoom.hdcDest, v.x, v.y, v.w, v.h, 0x5A0049)	; PATINVERT 
			If !New
				New := 1
			If one
				Memory()  
		}
		Else If New  
			Memory(), New := 0
	}
	If !oZoom.Pause
		SetTimer, Magnify, -1 
}

SetSize() {
	Static Top := 45, Left := 0, Right := 6, Bottom := 6
	MagnifyOff()
	Width := oZoom.GuiWidth - Left - Right
	Height := oZoom.GuiHeight - Top - Bottom
	Zoom := oZoom.Zoom
	conW := Mod(Width, Zoom) ? Width - Mod(Width, Zoom) + Zoom : Width
	conW := Mod(conW // Zoom, 2) ? conW : conW + Zoom
	conH := Mod(Height, Zoom) ? Height - Mod(Height, Zoom) + Zoom : Height
	conH := Mod(conH // Zoom, 2) ? conH : conH + Zoom 
	conX := (((conW - Width) // 2) + 1) * -1
	conY :=  (((conH - Height) // 2) + 1) * -1
	
	hDWP := DllCall("BeginDeferWindowPos", "Int", 2)
	hDWP := DllCall("DeferWindowPos"                             	; hDWP := DllCall("DeferWindowPos"
	, "Ptr", hDWP, "Ptr", oZoom.hDev, "UInt", 0                  	; , "Ptr", hDWP, "Ptr", oZoom.hDevCon, "UInt", 0
	, "Int", Left, "Int", Top, "Int", Width, "Int", Height		 	; , "Int", conX, "Int", conY, "Int", conW, "Int", conH
	, "UInt", 0x0010)    ; 0x0010 := SWP_NOACTIVATE  			 	; , "UInt", 0x0010)    ; 0x0010 := SWP_NOACTIVATE   
	hDWP := DllCall("DeferWindowPos"
	, "Ptr", hDWP, "Ptr", oZoom.hTBGui, "UInt", 0
	, "Int", (oZoom.GuiWidth - oZoom.GuiMinW) / 2
	, "Int", 0, "Int", 0, "Int", 0
	, "UInt", 0x0011)    ; 0x0010 := SWP_NOACTIVATE | 0x0001 := SWP_NOSIZE 
	DllCall("EndDeferWindowPos", "Ptr", hDWP)
	
	SetWindowPos(oZoom.hDevCon, conX, conY, conW, conH)

	oZoom.nWidthSrc := conW // Zoom
	oZoom.nHeightSrc := conH // Zoom
	oZoom.nXOriginSrcOffset := oZoom.nWidthSrc//2
	oZoom.nYOriginSrcOffset := oZoom.nHeightSrc//2
	oZoom.nWidthDest := conW
	oZoom.nHeightDest := conH
	oZoom.xCenter := conW / 2 - Zoom / 2
	oZoom.yCenter := conH / 2 - Zoom / 2
	
	ChangeMarker()
	
	If !oZoom.Pause
		SetTimer, Magnify, -10
	If oZoom.MemoryZoomSize
		SetTimer, ZoomCheckSize, -100
}

ChangeMarker() {
	Try GoTo % "Marker" oZoom.Mark
	
	MarkerCross:
		oZoom.oMarkers["Cross"] := [{x:0,y:oZoom.yCenter - 1,w:oZoom.nWidthDest,h:1}
		, {x:0,y:oZoom.yCenter + oZoom.Zoom,w:oZoom.nWidthDest,h:1}
		, {x:oZoom.xCenter - 1,y:0,w:1,h:oZoom.nHeightDest}
		, {x:oZoom.xCenter + oZoom.Zoom,y:0,w:1,h:oZoom.nHeightDest}]	
		Return

	MarkerSquare:
		oZoom.oMarkers["Square"] := [{x:oZoom.xCenter - 1,y:oZoom.yCenter,w:oZoom.Zoom + 2,h:1}
		, {x:oZoom.xCenter - 1,y:oZoom.yCenter + oZoom.Zoom + 1,w:oZoom.Zoom + 2,h:1}
		, {x:oZoom.xCenter - 1,y:oZoom.yCenter + 1,w:1,h:oZoom.Zoom}
		, {x:oZoom.xCenter + oZoom.Zoom,y:oZoom.yCenter + 1,w:1,h:oZoom.Zoom}]
		Return
		
	MarkerGrid:
		If (oZoom.Zoom = 1) {
			Gosub MarkerSquare
			Return oZoom.oMarkers["Grid"] := oZoom.oMarkers["Square"]
		}
		oZoom.oMarkers["Grid"] := [{x:oZoom.xCenter - oZoom.Zoom,y:oZoom.yCenter - oZoom.Zoom,w:oZoom.Zoom * 3,h:1}
		, {x:oZoom.xCenter - oZoom.Zoom,y:oZoom.yCenter,w:oZoom.Zoom * 3,h:1}
		, {x:oZoom.xCenter - oZoom.Zoom,y:oZoom.yCenter + oZoom.Zoom,w:oZoom.Zoom * 3,h:1}
		, {x:oZoom.xCenter - oZoom.Zoom,y:oZoom.yCenter + oZoom.Zoom * 2,w:oZoom.Zoom * 3,h:1}
		, {x:oZoom.xCenter - oZoom.Zoom,y:oZoom.yCenter - oZoom.Zoom,w:1,h:oZoom.Zoom * 3}
		, {x:oZoom.xCenter,y:oZoom.yCenter - oZoom.Zoom,w:1,h:oZoom.Zoom * 3}
		, {x:oZoom.xCenter + oZoom.Zoom,y:oZoom.yCenter - oZoom.Zoom,w:1,h:oZoom.Zoom * 3}
		, {x:oZoom.xCenter + oZoom.Zoom * 2,y:oZoom.yCenter - oZoom.Zoom,w:1,h:oZoom.Zoom * 3}]
		Return
}

ZoomCheckSize() {
	Static PrWidth, PrHeight
	If (PrWidth = oZoom.GuiWidth && PrHeight = oZoom.GuiHeight)
		Return
	PrWidth := oZoom.GuiWidth, PrHeight := oZoom.GuiHeight
	IniWrite(PrWidth, "MemoryZoomSizeW"), IniWrite(PrHeight, "MemoryZoomSizeH")  
}

SetWindowPos(hWnd, x, y, w, h, SWP_NOSIZE := 0, SWP_NOREDRAW := 0x0008) {
	Static SWP_ASYNCWINDOWPOS := 0x4000, SWP_DEFERERASE := 0x2000, SWP_NOACTIVATE := 0x0010, SWP_NOCOPYBITS := 0x0100
		, SWP_NOOWNERZORDER := 0x0200, SWP_NOSENDCHANGING := 0x0400  ;	, SWP_NOREDRAW := 0x0008
	DllCall("SetWindowPos"
		, "Ptr", hWnd
		, "Ptr", 0
		, "Int", x
		, "Int", y
		, "Int", w
		, "Int", h
		, "UInt", SWP_ASYNCWINDOWPOS|SWP_DEFERERASE|SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOOWNERZORDER|SWP_NOREDRAW|SWP_NOSENDCHANGING|SWP_NOSIZE)
}

RedrawWindow() {
	DllCall("RedrawWindow", "Ptr", oZoom.hGui, "Uint", 0, "Uint", 0, "Uint", 0x1|0x4)
}

SliderZoom() {
	SetTimer, ChangeZoom, -1
}

ChangeZoom(Val = "")  {
	If Val =
		GuiControlGet, Val, ZoomTB:, % oZoom.vSliderZoom
	If (Val < 1 || Val > 50)
		Return
	MagnifyOff()
	GuiControl, ZoomTB:, % oZoom.vSliderZoom, % oZoom.Zoom := Val
	GuiControl, ZoomTB:, % oZoom.vTextZoom, % oZoom.Zoom
	SetSize()
	Redraw()
	SetTimer, MagnifyZoomSave, -200
}

MagnifyZoomSave() {
	IniWrite(oZoom.Zoom, "MagnifyZoom")
}

ChangeMark()  {
	Static Mark := {"Cross":"Square","Square":"Grid","Grid":"None","None":"Cross","":"None"}
	oZoom.Mark := Mark[oZoom.Mark], ChangeMarker(), Redraw()
	GuiControl, ZoomTB:, % oZoom.vChangeMark, % oZoom.Mark
	GuiControl, ZoomTB:, -0x0001, % oZoom.vChangeMark
	GuiControl, ZoomTB:, Focus, % oZoom.vTextZoom
	SetTimer, MagnifyMarkSave, -300
}

MagnifyMarkSave() {
	IniWrite(oZoom.Mark, "MagnifyMark")
}

Redraw() {
	StretchBlt(oZoom.hdcDest, 0, 0, oZoom.nWidthDest, oZoom.nHeightDest
		, oZoom.hdcMemory, oZoom.nXOriginSrc - oZoom.nXOriginSrcOffset, oZoom.nYOriginSrc - oZoom.nYOriginSrcOffset, oZoom.nWidthSrc, oZoom.nHeightSrc)
	For k, v In oZoom.oMarkers[oZoom.Mark]
		StretchBlt(oZoom.hdcDest, v.x, v.y, v.w, v.h, oZoom.hdcDest, v.x, v.y, v.w, v.h, 0x5A0049)	; PATINVERT
}

ZoomShow() { 
	PostMessage, % MsgAhkSpyZoom, 2, 1, , ahk_id %hAhkSpy% 
	WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_id %hAhkSpy%
	Gui, Zoom:Show, % "NA Hide x" WinX + WinWidth " y" WinY 
	DllCall("AnimateWindow", "Ptr", oZoom.hGui, "Int", 96 , "UInt", 0x0000001)   
	DllCall("DeleteObject", Ptr, oZoom.hBM)
	oZoom.Pause := !(!oZoom.AhkSpyPause && ActiveNoPause || !WinActive("ahk_id" hAhkSpy))
	oZoom.Pause ? 0 : Magnify()
	oZoom.Show := 1
	GuiControl, ZoomTB:, Focus, % oZoom.vTextZoom  
}

ZoomHide() {
	oZoom.Show := 0
	oZoom.Pause := 1
	MagnifyOff()
	DCToStatic(oZoom.hdcDest, oZoom.hDevCon, 0, 0, oZoom.nWidthDest, oZoom.nHeightDest)
	DllCall("AnimateWindow", "Ptr", oZoom.hGui, "Int", 96, "UInt", 0x00010002) 
	PostMessage, % MsgAhkSpyZoom, 2, 0, , ahk_id %hAhkSpy%
	GuiControl, ZoomTB:, -0x0001, % oZoom.vZoomHideBut
	GuiControl, ZoomTB:, Focus, % oZoom.vTextZoom 
}

DCToStatic(hDC, hWnd, X, Y, W, H) {  
	tDC := DllCall("CreateCompatibleDC", UInt, 0) 
	hBM := DllCall("CopyImage", Ptr, DllCall("CreateBitmap", Int, W, Int, H, UInt, 1, UInt, 24
							, UInt, 0), UInt, 0, Int, 0, Int, 0, UInt, 0x2008, UInt) 
	oBM := DllCall("SelectObject", Ptr, tDC, Ptr, hBM) 
	DllCall("BitBlt", Ptr, tDC, UInt, 0, UInt, 0, Int, W, Int, H, Ptr, hDC, UInt, X, UInt, Y, UInt, 0xC000CA|0x40000000) 
	DllCall("SelectObject", Ptr, tDC, Ptr, oBM)
	DllCall("DeleteDC", Ptr, tDC) 
	SendMessage, 0x172, 0, hBM,, ahk_id %hWnd%  ;	STM_SETIMAGE, IMAGE_BITMAP
	oZoom.hBM := hBM
}

Memory() {
	SysGet, VirtualScreenX, 76
	SysGet, VirtualScreenY, 77
	SysGet, VirtualScreenWidth, 78
	SysGet, VirtualScreenHeight, 79
	oZoom.nXOriginSrc := oZoom.MouseX - VirtualScreenX, oZoom.nYOriginSrc := oZoom.MouseY - VirtualScreenY
	hBM := DllCall("Gdi32.Dll\CreateCompatibleBitmap", "Ptr", oZoom.hdcSrc, "Int", VirtualScreenWidth, "Int", VirtualScreenHeight)
	DllCall("Gdi32.Dll\SelectObject", "Ptr", oZoom.hdcMemory, "Ptr", hBM), DllCall("DeleteObject", "Ptr", hBM)
	BitBlt(oZoom.hdcMemory, 0, 0, VirtualScreenWidth, VirtualScreenHeight, oZoom.hdcSrc, VirtualScreenX, VirtualScreenY) 
}

CheckAhkSpy() {
	WinGet, Min, MinMax, % "ahk_id " hAhkSpy
	If Min =
		ExitApp
	If (Min = -1 || (!ActiveNoPause && WinActive("ahk_id" hAhkSpy)))
		oZoom.Pause := 1
} 

IsMinimize(hwnd) {
	WinGet, Min, MinMax, % "ahk_id " hwnd
	If Min = -1
		Return 1
}

SetWinEventHook(EventProc, eventMin, eventMax = 0)  {
	Return DllCall("SetWinEventHook"
				, "UInt", eventMin, "UInt", eventMax := !eventMax ? eventMin : eventMax
				, "Ptr", hmodWinEventProc := 0, "Ptr", lpfnWinEventProc := RegisterCallback(EventProc, "F")
				, "UInt", idProcess := 0, "UInt", idThread := 0
				, "UInt", dwflags := 0x0|0x2, "Ptr")	;	WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster = 0xC000CA) {
	Return DllCall("Gdi32.Dll\BitBlt"
					, "Ptr", dDC
					, "Int", dx
					, "Int", dy
					, "Int", dw
					, "Int", dh
					, "Ptr", sDC
					, "Int", sx
					, "Int", sy
					, "Uint", Raster|0x40000000)
}

StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster = 0xC000CA) {
	Return DllCall("Gdi32.Dll\StretchBlt"
					, "Ptr", dDC
					, "Int", dx
					, "Int", dy
					, "Int", dw
					, "Int", dh
					, "Ptr", sDC
					, "Int", sx
					, "Int", sy
					, "Int", sw
					, "Int", sh
					, "Uint", Raster|0x40000000)  ;	MERGECOPY|CAPTUREBLT
}

	; _________________________________________________ Events _________________________________________________

ZoomOnSize() { 
	If A_EventInfo != 0
		Return 
	oZoom.GuiWidth := A_GuiWidth
	oZoom.GuiHeight := A_GuiHeight
	SetSize()  
}

ZoomOnClose() {
	DllCall("Gdi32.Dll\DeleteDC", "Ptr", oZoom.hdcDest)
	DllCall("Gdi32.Dll\DeleteDC", "Ptr", oZoom.hdcSrc)
	DllCall("Gdi32.Dll\DeleteDC", "Ptr", oZoom.hdcMemory)
	DllCall("DeleteObject", Ptr, oZoom.hBM)
	RestoreCursors()
	ExitApp
}

MagnifyOff() {
	SetTimer, Magnify, Off
}

	; wParam: 0 снять паузу, 1 пауза, 2 однократный зум, 3 hide, 4 show, 5 MemoryZoomSize, 6 MinSize, 7 пауза AhkSpy, 8 ActiveNoPause, 9 Suspend

Z_MsgZoom(wParam, lParam) {   
	If (wParam = 0 && oZoom.Show)
		oZoom.Pause := 0, Magnify()
	Else If wParam = 1 
		MagnifyOff(), oZoom.Pause := 1 
	Else If (wParam = 2 && oZoom.Show)
		Magnify(1)
	Else If wParam = 3
		ZoomHide()
	Else If wParam = 4
		ZoomShow()
	Else If wParam = 5
	{ 
		If (oZoom.MemoryZoomSize := lParam) 
			IniWrite(oZoom.GuiWidth, "MemoryZoomSizeW")
			, IniWrite(oZoom.GuiHeight, "MemoryZoomSizeH") 
	}
	Else If (wParam = 6 && oZoom.Show)
		Gui, Zoom:Show, % "NA w" oZoom.GuiMinW " h" oZoom.GuiMinH
	Else If wParam = 7
		oZoom.AhkSpyPause := lParam
	Else If wParam = 8
		ActiveNoPause := lParam
	Else If wParam = 9
		Suspend % lParam ? "On" : "Off"
}
	
WM_Paint() { 
	If A_GuiControl =
		SetTimer, Redraw, -10 
}

EVENT_OBJECT_DESTROY(hWinEventHook, event, hwnd) { 
	If (hwnd = hAhkSpy)
		ExitApp
} 

EVENT_SYSTEM_MINIMIZESTART(hWinEventHook, event, hwnd) {
	If (hwnd = hAhkSpy)  
		oZoom.Pause := 1
}

	; _________________________________________________ Sizing _________________________________________________

WM_SETCURSOR(W, L, M, H) {
	Static SIZENWSE := DllCall("User32.dll\LoadCursor", "Ptr", NULL, "Int", 32642, "UPtr")
			, SIZENS := DllCall("User32.dll\LoadCursor", "Ptr", NULL, "Int", 32645, "UPtr")
			, SIZEWE := DllCall("User32.dll\LoadCursor", "Ptr", NULL, "Int", 32644, "UPtr")
	If (oZoom.SIZING = 2)
		Return
	If (W = oZoom.hGui)
	{
		MouseGetPos, mX, mY
		WinGetPos, WinX, WinY, WinW, WinH, % "ahk_id " oZoom.hDev
		If (mX > WinX && mY > WinY)
		{
			If (mX < WinX + WinW - 10)
				DllCall("User32.dll\SetCursor", "Ptr", SIZENS), oZoom.SIZINGType := "NS"
			Else If (mY < WinY + WinH - 10)
				DllCall("User32.dll\SetCursor", "Ptr", SIZEWE), oZoom.SIZINGType := "WE"
			Else
				DllCall("User32.dll\SetCursor", "Ptr", SIZENWSE), oZoom.SIZINGType := "NWSE" 
			Return oZoom.SIZING := 1
		}
	}
	Else
		oZoom.SIZING := 0, oZoom.SIZINGType := ""
}

LBUTTONDOWN(W, L, M, H) {
	If oZoom.SIZING
	{
		oZoom.SIZING := 2
		SetSystemCursor("SIZE" oZoom.SIZINGType)
		SetTimer, Sizing, -10
		KeyWait LButton
		SetTimer, Sizing, Off
		RestoreCursors() 
		oZoom.SIZING := 0, oZoom.SIZINGType := ""
	}
}

Sizing() {
	MouseGetPos, mX, mY
	WinGetPos, WinX, WinY, , , % "ahk_id " oZoom.hGui
	If (oZoom.SIZINGType = "NWSE" || oZoom.SIZINGType = "WE")
		Width := " w" (mX - WinX < oZoom.GuiMinW ? oZoom.GuiMinW : mX - WinX)
	If (oZoom.SIZINGType = "NWSE" || oZoom.SIZINGType = "NS")
		Height := " h" (mY - WinY < oZoom.GuiMinH ? oZoom.GuiMinH : mY - WinY)
	Gui, Zoom:Show, % "NA" Width . Height
	SetTimer, Sizing, -1
}

SetSystemCursor(CursorName, cx = 0, cy = 0) {
	Static SystemCursors := {ARROW:32512, IBEAM:32513, WAIT:32514, CROSS:32515, UPARROW:32516, SIZE:32640, ICON:32641, SIZENWSE:32642
					, SIZENESW:32643, SIZEWE:32644 ,SIZENS:32645, SIZEALL:32646, NO:32648, HAND:32649, APPSTARTING:32650, HELP:32651}
    Local CursorHandle, hImage, Name, ID
	If (CursorHandle := DllCall("LoadCursor", Uint, 0, Int, SystemCursors[CursorName]))
		For Name, ID in SystemCursors
			hImage := DllCall("CopyImage", Ptr, CursorHandle, Uint, 0x2, Int, cx, Int, cy, Uint, 0)
			, DllCall("SetSystemCursor", Ptr, hImage, Int, ID)
}

RestoreCursors() { 
	DllCall("SystemParametersInfo", UInt, 0x57, UInt, 0, UInt, 0, UInt, 0)  ;	SPI_SETCURSORS := 0x57
}

	;)
