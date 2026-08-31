#Requires AutoHotkey 1.1.37+ <1.2
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetWinDelay, 32 ; Sets the delay that will occur after each windowing command, such as WinActivate. (Default is 100)
SetControlDelay, 0 ; Sets the delay that will occur after each control-modifying command. -1 for no delay, 0 for smallest possible delay. The default delay is 20.
SetBatchLines, -1 ; How fast a script will run (affects CPU utilization).(Default setting is 10ms - prevent the script from using any more than 50% of an idle CPU's time. This allows scripts to run quickly while still maintaining a high level of cooperation with CPU sensitive tasks such as games and video capture/playback.
ListLines Off
Process, Priority,, Normal
CoordMode, Mouse, Client

global g_TabList:=""
global g_MouseTooltips:={}
g_MouseTooltips.ByName:={}
g_MouseTooltips.ByHandle:={}
global g_TabControlHeight
global g_TabControlStartHeight
global g_TabControlWidth
global g_TabControlX
global g_TabControlY

try
{
	Menu Tray, Icon, %A_LineFile%\..\Resources\IBM.ico
}

#include %A_LineFile%\..\BrivMaster\IC_BrivMaster_SharedFunctions.ahk
#include %A_LineFile%\..\BrivMaster\IC_BrivMaster_Home.ahk
#include %A_LineFile%\..\BrivMaster\IC_BrivMaster_GUI.ahk
#include %A_LineFile%\..\BrivMaster\IC_BrivMaster_Heroes.ahk
#include %A_LineFile%\..\Lib\IC_BrivMaster_JSON.ahk
#include %A_LineFile%\..\Lib\IC_BrivMaster_Zlib.ahk

global g_ServerCall:={}
global g_SF:={} ;Must be instantiated after settings are loaded
global g_IriBrivMaster:=New IC_IriBrivMaster_Component()
global g_IriBrivMaster_GUI:=New IC_IriBrivMaster_GUI
global g_Heroes:={}
global g_IBM_Settings:={}
global g_InputManager:=New IC_BrivMaster_InputManager_Class()
global g_IBM:={} ;Nasty hack for the input manager expecting the current HWnd to be in g_IBM.GameMaster.Hwnd, which is needed for the Elly tool TODO: Make this less horrible. Possibly by actually having g_IBM used for IBM things?!
global g_IriBrivMaster_StartFunctions:={}
global g_IriBrivMaster_StopFunctions:={}

g_IriBrivMaster.Init()

GuiControl, IBM_Home:MoveDraw, ModronTabControl, % "w" . g_TabControlWidth . " h" . g_TabControlHeight
Gui, IBM_Home:Show, % "x" . g_TabControlX . " y" . g_TabControlY . " w" . g_TabControlWidth+10 . " h" . g_TabControlHeight+g_TabControlStartHeight+6 . " NA", % "Briv Master Home"
g_IriBrivMaster_GUI.ApplyTooltips() ;Must be after controls are created by Gui, Show
OnMessage(0x200, "CheckControlForTooltip") ;WM_MOUSEMOVE for tooltip tracking

ClearButtonStatusMessage()
{
    g_IriBrivMaster.LEGACY_UpdateStatus("")
}

Reload_Clicked()
{
    Reload
    return
}

Launch_Clicked()
{
	programLoc:=g_IBM_Settings.IBM_Game_Launch
    try
    {
		if (g_IBM_Settings.IBM_Game_Hide_Launcher)
			Run, %programLoc%,,Hide, openPID
		else
			Run, %programLoc%,,,openPID
    }
    catch
    {
        MsgBox, 48,Briv Master, Unable to launch game`nVerify the game location is set properly in the Briv Master settings
    }
	if (g_SF.GetProcessName(openPID)==g_IBM_Settings.IBM_Game_Exe) ;If we launch the game .exe directly (e.g. Steam) the Run PID will be the game, but for things like EGS it will not so we need to find it
		g_SF.PID:=openPID
    else
	{
		Process, Exist, % g_IBM_Settings.IBM_Game_Exe
		g_SF.PID:=ErrorLevel
	}
	Process, Priority, % g_SF.PID, Realtime ;Raises IC's priority
}

IBM_HomeGuiClose()
{
    MsgBox 36,Briv Master Home,Are you sure you want to `exit? ;4 for Yes/No, 32 for Question Mark
    IfMsgBox Yes
        ExitApp
    IfMsgBox No
        return True
}

CheckControlForTooltip() ;Shows a tooltip if the control with mouseover has a tooltip associated with it
{
	MouseGetPos,,,,hControl,2 ;Get the Hwnd
	if(g_MouseToolTips.ByHandle.HasKey(hControl))
	{
		ToolTip % g_MouseToolTips.ByHandle[hControl].Tip
		SetTimer, HideToolTip, -3000
		return
	}
	ToolTip
}

HideToolTip()
{
    ToolTip
}