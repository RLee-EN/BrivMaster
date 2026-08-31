class IC_IriBrivMaster_GUI
{
	static IBM_SYMBOL_ROUTE_JUMP:="▲" ;This file (only) has to be saved as a UTF-8-BOM file to make these symbols work
	static IBM_SYMBOL_ROUTE_STACK:="≡"
	static IBM_SYMBOL_CONTROL_ACTIVE:="●"
	static IBM_SYMBOL_UI_DOWN:="▼"
	static IBM_SYMBOL_UI_CONFIG:="⚙"
	static IBM_SYMBOL_UI_LEFT:="◀"
	static IBM_SYMBOL_UI_CLEAR:="○"
	static IBM_SYMBOL_UI_LIGHT:="⬤"

	__New()
	{
		this.levelDataSet:={}
		this.controlLock:=true
	}

	Init()
	{
		global ;Required for GUI control variables
		this.Theme:=new IBM_Theme()
		this.Wide:=g_IBM_Settings.HUB.IBM_Window_Wide
		g_TabControlX:=g_IBM_Settings.IBM_BM_X
		g_TabControlY:=g_IBM_Settings.IBM_BM_Y
		if(this.Wide)
		{
			g_TabControlHeight:=566
			g_TabControlWidth:=464
		}
		else
		{
			g_TabControlHeight:=750
			g_TabControlWidth:=410
		}
		this.controlLock:=true
		winBGColour:=this.Theme.GetThemeBackgroundColour()
		LVBGColour:=this.Theme.GetThemeListViewBackgroundColour()
		editTextColour:=this.Theme.GetThemeTextColour("EditText") ;Avoid excess UseTheme calls as we swap for edit boxes and surrounding text
		Gui, IBM_Home:New
		Gui, IBM_Home:+Resize -MaximizeBox
		Gui, IBM_Home:Color, %winBGColour%
		Gui, IBM_Home:Font,, Microsoft Sans Serif ;Required as systems may have odd default fonts, e.g. in non-Latin regions
		this.Theme.UseThemeTextColour("IBM_Home")
		groupWidth:=g_TabControlWidth-14 ;2px spacing each side - it seems 10 pixels get lost somewhere in the Tab3 control
		;Buttons for starting, saving etc
		buttonWidth:=25
		buttonSpacing:=15
		Gui, IBM_Home:Add, Picture, xm+5 y+3 h-1 w%buttonWidth% gLaunch_Clicked vLaunchClickButton, %A_LineFile%\..\..\Resources\IC.png
		Gui, IBM_Home:Add, Picture, x+%buttonSpacing% h-1 w%buttonWidth% gReload_Clicked vReloadClickButton, %A_LineFile%\..\..\Resources\Refresh.png
		this.AddToolTip("LaunchClickButton", "Launch Idle Champions")
		this.AddToolTip("ReloadClickButton", "Reload Briv Master Home")
		firstButtonOffset:=groupWidth-buttonWidth*5-buttonSpacing*4-5
		textWidth:=firstButtonOffset-buttonWidth*2-buttonSpacing-25 ;10px each side
		Gui, IBM_Home:Add, Text, x+10 w%textWidth% r2 vIBM_MainButtons_Status
		Gui, IBM_Home:Add, Picture, xm+%firstButtonOffset% yp+0 h-1 w%buttonWidth% gIBM_MainButtons_Start vIBM_MainButtons_Start, %A_LineFile%\..\..\Resources\Play.png
		Gui, IBM_Home:Add, Picture, x+%buttonSpacing% h-1 w%buttonWidth% gIBM_MainButtons_Stop vIBM_MainButtons_Stop, %A_LineFile%\..\..\Resources\Stop.png
		Gui, IBM_Home:Add, Picture, x+%buttonSpacing% h-1 w%buttonWidth% gIBM_MainButtons_Connect vIBM_MainButtons_Connect, %A_LineFile%\..\..\Resources\Connect.png
		Gui, IBM_Home:Add, Picture, x+%buttonSpacing% h-1 w%buttonWidth% gIBM_MainButtons_Save vIBM_MainButtons_Save, %A_LineFile%\..\..\Resources\Save.png
		Gui, IBM_Home:Add, Picture, x+%buttonSpacing% h-1 w%buttonWidth% gIBM_MainButtons_Reset vIBM_MainButtons_Reset, %A_LineFile%\..\..\Resources\Reset.png
		this.AddToolTip("IBM_MainButtons_Start", "Start Gem Farm")
        this.AddToolTip("IBM_MainButtons_Stop", "Stop Gem Farm")
        this.AddToolTip("IBM_MainButtons_Connect", "Reconnect to Gem Farm script")
        this.AddToolTip("IBM_MainButtons_Save", "Save Briv Master settings from all tabs")
		this.AddToolTip("IBM_MainButtons_Reset", "Reset stats")
		;Tab control
		g_TabControlStartHeight:=buttonWidth+7
		Gui, IBM_Home:Add, Tab3, x5 y%g_TabControlStartHeight% w%g_TabControlWidth% h%g_TabControlHeight% vModronTabControl, %g_TabList%
		this.AddTab("Home|Game|Route|Levels")
		this.Theme.UseThemeTitleBar("IBM_Home")
		Gui, IBM_Home:Show, %  "x" . g_TabControlX . " y" . g_TabControlY . " w" . g_TabControlWidth+10 . " h" . g_TabControlHeight+g_TabControlStartHeight+6  . " NA", % "Briv Master Home (Loading...)"

		;++++++++++++++++++HOME TAB++++++++++++++++++
		Gui, IBM_Home:Tab, Home
		;Run control
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 ym+48 w%groupWidth% h10 vIBM_Group_Run_Control, Run Control
		Gui, IBM_Home:Font, w400
		if(this.wide)
			cycleWidth:=120
		else
			cycleWidth:=95
		offlineControlWidth:=groupWidth-cycleWidth-21
		;>Group for offline control options
		Gui, IBM_Home:Add, Groupbox, xs+7 ys+9 w%offlineControlWidth% h38
		;>Pause offline
		Gui, IBM_Home:Add, Text, xp+8 yp+13 0x200 h18, Offline stacking ;0x200 centres vertically
		Gui, IBM_Home:Add, Button, x+10 w45 h18 vIBM_RunControl_Offline_Toggle gIBM_RunControl_Offline_Toggle, Pause
		Gui, IBM_Home:Add, Text, x+10 w10 0x200 h18 vIBM_RunControl_Offline_StatusPause, % IC_IriBrivMaster_GUI.IBM_SYMBOL_CONTROL_ACTIVE
		;>Queue offline
		Gui, IBM_Home:Add, Text, x+10 yp+0 0x200 h18, Queue ;0x200 centres vertically
		Gui, IBM_Home:Add, Button, x+10 w45 h18 vIBM_RunControl_Offline_Queue_Toggle gIBM_RunControl_Offline_Queue_Toggle, Force
		Gui, IBM_Home:Add, Text, x+10 w10 0x200 h18 vIBM_RunControl_Offline_StatusQueue, % IC_IriBrivMaster_GUI.IBM_SYMBOL_CONTROL_ACTIVE
		;>Cycle
		cycleX:=groupWidth-cycleWidth-6
		Gui, IBM_Home:Add, Groupbox, xm+%cycleX% ys+9 w%cycleWidth% h38
		textWidth:=cycleWidth-10
		Gui, IBM_Home:Add, Text, xp+5 yp+13 w%textWidth% 0x200 h18 Center vIBM_RunControl_Cycle, % "Cycle -/-"
		;>RunControl status
		Gui, IBM_Home:Add, Text, xs+10 yp+30,Strategy:
		textWidth:=groupWidth-65
		Gui, IBM_Home:Add, Text, x+2 r2 w%textWidth% vIBM_RunControl_Status, -
		Gui, IBM_Home:Add, Text, xs+10 yp+28 w380 vIBM_RunControl_Stack, Stacking: -
		Gui, IBM_Home:Add, Text, xs+10 yp+16 w380 vIBM_Stats_Loop, Stage: -
		Gui, IBM_Home:Add, Text, xs+10 yp+16 w380 vIBM_Stats_Last_Close, Last close: -
		Gui, IBM_Home:Add, Text, xs+10 yp+16 w188 vIBM_Stats_Current_Area_Run_Time, Area / Run (s): - / -
		if(this.wide)
		{
			textX:=groupWidth/2+10
			Gui, IBM_Home:Add, Text, xs+%textX% yp+0 w188 vIBM_Stats_Current_Briv, SB / Haste stacks: - / -
		}
		else
			Gui, IBM_Home:Add, Text, xs+10 w188 vIBM_Stats_Current_Briv, SB / Haste stacks: - / -
		GuiControlGet, lastItemPos, IBM_Home:Pos,IBM_Stats_Current_Briv ;Used for setting the next box
		groupEnd:=lastItemPosY+lastItemPosH-46 ;The 48 hard coded for xm, +2 for spacing
		GuiControl, IBM_Home:Move, IBM_Group_Run_Control, h%groupEnd%
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Run_Control ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		if(this.Wide)
		{
			statPanelWidth:=groupWidth*0.5-4
			statPanelHeight:=203
			;Stats - Timing
			Gui, IBM_Home:Font, w700
			Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%statPanelWidth% h%statPanelHeight% vIBM_Group_Stats_Timing, Run Timings
			Gui, IBM_Home:Font, w400
			;>Highlights (BPH)
			highLightWidth:=statPanelWidth-10
			this.Theme.UseThemeTextColour("IBM_Home","SpecialText1", 700)
			Gui, IBM_Home:Add, Text, xs+5 ys+20 w%highLightWidth% Center vIBM_Stats_BPH, BPH
			this.Theme.UseThemeTextColour("IBM_Home")
			Gui, IBM_Home:Add, Text, xs+10 y+10 w60, Total runs:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Total_Runs, -
			Gui, IBM_Home:Add, Text, xs+10 y+3 w60, Failed runs:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Fail_Runs, -
			Gui, IBM_Home:Add, Text, xs+10 y+3, Bosses hit (Run / Total):
			Gui, IBM_Home:Add, Text, x+3 w50 vIBM_Stats_Boss_Hits, -
			Gui, IBM_Home:Add, Text, xs+10 y+3, Rollbacks:
			Gui, IBM_Home:Add, Text, x+3 w20 vIBM_Stats_Rollbacks, -
			Gui, IBM_Home:Add, Text, xs+10 y+3, Bad autoprogressions:
			Gui, IBM_Home:Add, Text, x+3 w20 vIBM_Stats_Bad_Auto, -
			this.Theme.UseThemeTextColour("IBM_Home","TableText")
			LVWidth:=groupWidth/2-24
			Gui, IBM_Home:Add, ListView, +Background%LVBGColour% xs+10 y+3 w%LVWidth% 0x2000 LV0x10000 vIBM_Stats_Run_LV Count3 R3 LV0x10 NoSort NoSortHdr, Time|Last|Mean|Fast|Slow ;0x2000 is remove H scroll bar, LV0x10000 is double-buffering to stop flickering, LV0x10 prevents re-ordering of columns
			GuiControl, -Redraw, IBM_Stats_Run_LV
			Gui, IBM_Home:Default
			Gui, ListView, IBM_Stats_Run_LV
			LV_Add(,"Total","--.--","--.--","--.--","--.--")
			LV_Add(,"Active","--.--","--.--","--.--","--.--")
			LV_Add(,"Wait","--.--","--.--","--.--","--.--")
			LV_ModifyCol(1,"AutoHdr")
			LV_ModifyCol(2,"AutoHdr")
			LV_ModifyCol(3,"AutoHdr")
			LV_ModifyCol(4,"AutoHdr")
			LV_ModifyCol(5,"AutoHdr")
			GuiControl, +Redraw, IBM_Stats_Run_LV
			this.Theme.UseThemeTextColour("IBM_Home")		
			;Stats - Rewards
			secondPanelX:=statPanelWidth+9
			Gui, IBM_Home:Font, w700
			Gui, IBM_Home:Add, Groupbox, Section xm+%secondPanelX% y%nextGroupStart% w%statPanelWidth% h%statPanelHeight% vIBM_Group_Stats_Reward, Run Rewards
			Gui, IBM_Home:Font, w400
			;>Highlights (GPH)
			this.Theme.UseThemeTextColour("IBM_Home","SpecialText2", 700)
			Gui, IBM_Home:Add, Text, xs+5 ys+20 w100 w%highLightWidth% Center vIBM_Stats_GPH, GPH
			this.Theme.UseThemeTextColour("IBM_Home")
			;>Gems
			Gui, IBM_Home:Add, Text, xs+10 y+10, Gems gained:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_TotalGems,
			Gui, IBM_Home:Add, Text, xs+10 y+3, Gem hunter:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Gem_Hunter,-
			Gui, IBM_Home:Add, Text, xs+10 y+3, Gem bonus:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Gem_Bonus, -.-`% (-.- GPB)
			;>Reward summary
			Gui, IBM_Home:Add, Text, xs+10 y+3 w75, BSC iLevels/h:
			Gui, IBM_Home:Add, Text, x+3 w130 vIBM_Stats_BSC_Reward, -
			Gui, IBM_Home:Add, Text, xs+10 y+3 w75, Total iLevels/h:
			Gui, IBM_Home:Add, Text, x+3 w130 vIBM_Stats_Total_Reward, -
			;>Chests
			this.Theme.UseThemeTextColour("IBM_Home","TableText")
			Gui, IBM_Home:Add, ListView, +Background%LVBGColour% xs+10 y+3 w%LVWidth% 0x2000 LV0x10000 vIBM_Stats_Chests_LV Count3 R2 LV0x10 NoSort NoSortHdr, Chest|Dropped|Bought|Opened ;0x2000 is remove H scroll bar, LV0x10000 is double-buffering to stop flickering, LV0x10 prevents re-ordering of columns
			GuiControl, -Redraw, IBM_Stats_Chests_LV
			Gui, IBM_Home:Default
			Gui, ListView, IBM_Stats_Chests_LV
			LV_Add(,"Silver","--.--","--.--","--.--","--.--")
			LV_Add(,"Gold","--.--","--.--","--.--","--.--")
			LV_ModifyCol(1,"AutoHdr")
			LV_ModifyCol(2,"AutoHdr")
			LV_ModifyCol(3,"AutoHdr")
			LV_ModifyCol(4,"AutoHdr")
			GuiControl, +Redraw, IBM_Stats_Chests_LV
			this.Theme.UseThemeTextColour("IBM_Home")
			GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Stats_Reward ;Used for setting the next box
			nextGroupStart:=groupPosY+groupPosH+1
		}
		else
		{
			;Stats - Rewards
			Gui, IBM_Home:Font, w700
			Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h188 vIBM_Group_Stats_Reward, Run Rewards
			Gui, IBM_Home:Font, w400
			;>Highlights (BPH/GPH)
			highlightWidth:=FLOOR((groupWidth-21)/2)
			this.Theme.UseThemeTextColour("IBM_Home","SpecialText1", 700)
			Gui, IBM_Home:Add, Text, xs+10 ys+20 w%highlightWidth% Center vIBM_Stats_BPH, BPH
			this.Theme.UseThemeTextColour("IBM_Home","SpecialText2", 700)
			Gui, IBM_Home:Add, Text, x+1 w100 w%highlightWidth% Center vIBM_Stats_GPH, GPH
			this.Theme.UseThemeTextColour("IBM_Home")
			;>Gems
			Gui, IBM_Home:Add, Text, xs+10 y+10, Gems gained:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_TotalGems,
			Gui, IBM_Home:Add, Text, xs+10 y+3, Gem hunter:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Gem_Hunter,-
			Gui, IBM_Home:Add, Text, xs+10 y+3, Gem bonus:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Gem_Bonus, -.-`% (-.- GPB)
			;>Reward summary
			Gui, IBM_Home:Add, Text, xs+10 y+3 w75, BSC iLevels/h:
			Gui, IBM_Home:Add, Text, x+3 w130 vIBM_Stats_BSC_Reward, -
			Gui, IBM_Home:Add, Text, xs+10 y+3 w75, Total iLevels/h:
			Gui, IBM_Home:Add, Text, x+3 w130 vIBM_Stats_Total_Reward, -
			;>Chests
			this.Theme.UseThemeTextColour("IBM_Home","TableText")
			Gui, IBM_Home:Add, ListView, +Background%LVBGColour% xs+10 y+3 w220 0x2000 LV0x10000 vIBM_Stats_Chests_LV Count3 R2 LV0x10 NoSort NoSortHdr, Chest|Dropped|Bought|Opened ;0x2000 is remove H scroll bar, LV0x10000 is double-buffering to stop flickering, LV0x10 prevents re-ordering of columns
			GuiControl, -Redraw, IBM_Stats_Chests_LV
			Gui, IBM_Home:Default
			Gui, ListView, IBM_Stats_Chests_LV
			LV_Add(,"Silver","--.--","--.--","--.--","--.--")
			LV_Add(,"Gold","--.--","--.--","--.--","--.--")
			LV_ModifyCol(1,"AutoHdr")
			LV_ModifyCol(2,"AutoHdr")
			LV_ModifyCol(3,"AutoHdr")
			LV_ModifyCol(4,"AutoHdr")
			GuiControl, +Redraw, IBM_Stats_Chests_LV
			this.Theme.UseThemeTextColour("IBM_Home")
			GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Stats_Reward ;Used for setting the next box
			nextGroupStart:=groupPosY+groupPosH+1
			;Stats - Timing
			Gui, IBM_Home:Font, w700
			Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h179 vIBM_Group_Stats_Timing, Run Timings
			Gui, IBM_Home:Font, w400
			Gui, IBM_Home:Add, Text, xs+10 ys+18 w60, Total runs:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Total_Runs, -
			Gui, IBM_Home:Add, Text, xs+10 y+3 w60, Failed runs:
			Gui, IBM_Home:Add, Text, x+3 w140 vIBM_Stats_Fail_Runs, -
			Gui, IBM_Home:Add, Text, xs+10 y+3, Bosses hit (Run / Total):
			Gui, IBM_Home:Add, Text, x+3 w50 vIBM_Stats_Boss_Hits, -
			Gui, IBM_Home:Add, Text, xs+10 y+3, Rollbacks:
			Gui, IBM_Home:Add, Text, x+3 w20 vIBM_Stats_Rollbacks, -
			Gui, IBM_Home:Add, Text, xs+10 y+3, Bad autoprogressions:
			Gui, IBM_Home:Add, Text, x+3 w20 vIBM_Stats_Bad_Auto, -
			this.Theme.UseThemeTextColour("IBM_Home","TableText")
			Gui, IBM_Home:Add, ListView, +Background%LVBGColour% xs+10 y+3 w220 0x2000 LV0x10000 vIBM_Stats_Run_LV Count3 R3 LV0x10 NoSort NoSortHdr, Time|Last|Mean|Fast|Slow ;0x2000 is remove H scroll bar, LV0x10000 is double-buffering to stop flickering, LV0x10 prevents re-ordering of columns
			GuiControl, -Redraw, IBM_Stats_Run_LV
			Gui, IBM_Home:Default
			Gui, ListView, IBM_Stats_Run_LV
			LV_Add(,"Total","--.--","--.--","--.--","--.--")
			LV_Add(,"Active","--.--","--.--","--.--","--.--")
			LV_Add(,"Wait","--.--","--.--","--.--","--.--")
			LV_ModifyCol(1,"AutoHdr")
			LV_ModifyCol(2,"AutoHdr")
			LV_ModifyCol(3,"AutoHdr")
			LV_ModifyCol(4,"AutoHdr")
			LV_ModifyCol(5,"AutoHdr")
			GuiControl, +Redraw, IBM_Stats_Run_LV
			this.Theme.UseThemeTextColour("IBM_Home")		
			GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Stats_Timing ;Used for setting the next box
			nextGroupStart:=groupPosY+groupPosH+1
		}
		;Chests
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h50 vIBM_Group_Chests, Chests and Daily Platinum
		Gui, IBM_Home:Font, w400
		LVWidth:=groupWidth-66 ;46 for the 2 buttons, 20 for spacing each side
		Gui, IBM_Home:Add, ListView, +Background%LVBGColour% xs+10 ys+20 w%LVWidth% 0x2000 LV0x10000 LV0x10 vIBM_ChestsSnatcher_Status Count10 -Hdr R1, Time|Action|Result ;0x2000 is remove H scroll bar, LV0x10000 is double-buffering to stop flickering
		GuiControl, -Redraw, IBM_ChestsSnatcher_Status
		Gui, IBM_Home:Default
		Gui, ListView, IBM_ChestsSnatcher_Status
		LV_ModifyCol(1,50)
		LV_ModifyCol(2,50)
		GuiControl, +Redraw, IBM_ChestsSnatcher_Status
		;>Chest Log window
		Gui, IBM_ChestSnatcher_Log:New , , Chest & Daily Platinum Log
		Gui, IBM_ChestSnatcher_Log:Margin, 0,0
		Gui, IBM_ChestSnatcher_Log:-Resize -MaximizeBox -Caption +HwndLog_Hwnd
		Gui, IBM_ChestSnatcher_Log:Font,, Microsoft Sans Serif ;Required as systems may have odd default fonts, e.g. in non-Latin regions
		this.IBM_ChestSnatcher_Log_Hwnd:=Log_Hwnd ;Save handle to the log window
		this.Theme.UseThemeTextColour("IBM_ChestSnatcher_Log","TableText") ;No need to reset this to normal text as it only contains the LV
		LVWidth:=groupWidth-19 ;Not sure why this isn't -20
		Gui, IBM_ChestSnatcher_Log:Add, ListView, +Background%LVBGColour% w%LVWidth% 0x2000 LV0x10000 vIBM_ChestsSnatcher_Status_Expanded Count20 R20, Time|Action|Result ;0x2000 is remove H scroll bar, LV0x10000 is double-buffering to stop flickering
		GuiControl, -Redraw, vIBM_ChestsSnatcher_Status_Expanded
		Gui, IBM_ChestSnatcher_Log:Default
		Gui, ListView, vIBM_ChestsSnatcher_Status_Expanded
		LV_ModifyCol(1,50)
		LV_ModifyCol(2,50)
		GuiControl, +Redraw, vIBM_ChestsSnatcher_Status_Expanded
		Gui, IBM_Home:Default
		;>Chest buttons
		buttonX:=groupWidth-51
		Gui, IBM_Home:Add, Button, xs+%buttonX% yp+0 w18 h18 vIBM_ChestsSnatcher_Status_Resize gIBM_ChestsSnatcher_Status_Resize, % IC_IriBrivMaster_GUI.IBM_SYMBOL_UI_DOWN
		Gui, IBM_Home:Add, Button, x+5 w18 h18 vIBM_ChestsSnatcher_Options gIBM_ChestsSnatcher_Options, % IC_IriBrivMaster_GUI.IBM_SYMBOL_UI_CONFIG
		;>Chest options
		Gui, IBM_ChestSnatcher_Options:New , , Chest Options ;Note this window uses an Accept button to accept changes, so that the script does not execute based on partial entry (e.g. with poor timing it could buy 12 chests whilst you were typing 123 into the box)
		Gui, IBM_ChestSnatcher_Options:-Resize -MaximizeBox +HwndOpt_Hwnd
		Gui, IBM_ChestSnatcher_Options:Color, %winBGColour%
		this.Theme.UseThemeTextColour("IBM_ChestSnatcher_Options")
		this.IBM_ChestSnatcher_Opt_Hwnd:=Opt_Hwnd ;Save handle to the options window
		Gui, IBM_ChestSnatcher_Options:Add, Edit, xm+10 w40 +%editTextColour% Number Limit3 vIBM_ChestSnatcher_Options_Min_Buy
		Gui, IBM_ChestSnatcher_Options:Add, Text, x+10 w170 h18 0x200, Gold to buy per call (0 to disable)
		Gui, IBM_ChestSnatcher_Options:Add, Edit, xm+10 w40 +%editTextColour% Number Limit4 vIBM_ChestSnatcher_Options_Open_Gold
		Gui, IBM_ChestSnatcher_Options:Add, Text, x+10 w170 h18 0x200, Gold to open per call (0 to disable)
		Gui, IBM_ChestSnatcher_Options:Add, Edit, xm+10 w40 +%editTextColour% Number Limit4 vIBM_ChestSnatcher_Options_Open_Silver
		Gui, IBM_ChestSnatcher_Options:Add, Text, x+10 w170 h18 0x200, Silver to open per call (0 to disable)
		Gui, IBM_ChestSnatcher_Options:Add, Edit, xm+10 w65 +%editTextColour% Number Limit10 vIBM_ChestSnatcher_Options_Min_Gem
		Gui, IBM_ChestSnatcher_Options:Add, Text, x+10 w100 h18 0x200, Reserve Gems
		Gui, IBM_ChestSnatcher_Options:Add, Edit, xm+10 w40 +%editTextColour% Number Limit8 vIBM_ChestSnatcher_Options_Min_Gold
		Gui, IBM_ChestSnatcher_Options:Add, Text, x+10 w100 h18 0x200, Reserve Gold
		Gui, IBM_ChestSnatcher_Options:Add, Edit, xm+10 w40 +%editTextColour% Number Limit8 vIBM_ChestSnatcher_Options_Min_Silver
		Gui, IBM_ChestSnatcher_Options:Add, Text, x+10 w100 h18 0x200, Reserve Silver
		Gui, IBM_ChestSnatcher_Options:Add, CheckBox, xm+10 h18 0x200 vIBM_ChestSnatcher_Options_Claim, Claim Daily Rewards
		gui, IBM_ChestSnatcher_Options:Add, Button, xm+90 w50 gIBM_ChestSnatcher_Options_OK_Button, Accept
		this.Theme.UseThemeTitleBar("IBM_ChestSnatcher_Options",false)
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Chests ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Game Settings
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h57 vIBM_Group_Game_Settings, Game Settings
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Radio, xs+10 ys+15 h18 w90 vIBM_Game_Settings_Profile_1 gIBM_Game_Settings_Profile
		Gui, IBM_Home:Add, Radio, xp+0 y+0 h18 w90 vIBM_Game_Settings_Profile_2 gIBM_Game_Settings_Profile
		textWidth:=groupWidth-190
		Gui, IBM_Home:Add, Text, x+3 yp-15 h18 w%textWidth% r2 vIBM_Game_Settings_Status, Not checked
		buttonX:=groupWidth-80
		Gui, IBM_Home:Add, Button, xs+%buttonX% yp+0 w47 h18 vIBM_Game_Settings_Fix gIBM_Game_Settings_Fix, Set Now
		Gui, IBM_Home:Add, Button, x+5 w18 h18 vIBM_Game_Settings_Options gIBM_Game_Settings_Options, % IC_IriBrivMaster_GUI.IBM_SYMBOL_UI_CONFIG
		;>Game Settings Options Window
		Gui, IBM_Game_Settings_Options:New , , Game Settings
		Gui, IBM_Game_Settings_Options:Color, %winBGColour%
		Gui, IBM_Game_Settings_Options:-Resize -MaximizeBox +HwndOpt_Hwnd
		Gui, IBM_Game_Settings_Options:Font,, Microsoft Sans Serif ;Required as systems may have odd default fonts, e.g. in non-Latin regions
		this.IBM_Game_Settings_Opt_Hwnd:=Opt_Hwnd ;Save handle to the options window
		this.Theme.UseThemeTextColour("IBM_Game_Settings_Options",,700)
		Gui, IBM_Game_Settings_Options:Add, Text, xm+0 w80 h18 0x200 Center, Profile 1
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w80 h18 0x200 Center, Option
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w80 h18 0x200 Center, Profile 2
		this.Theme.UseThemeTextColour("IBM_Game_Settings_Options",,400)
		Gui, IBM_Game_Settings_Options:Add, Edit, xm+0 w80 Limit12 +%editTextColour% vIBM_Game_Settings_Option_Name_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w80 h18 0x200 Center, Name
		Gui, IBM_Game_Settings_Options:Add, Edit, x+3 w80 Limit12 +%editTextColour% vIBM_Game_Settings_Option_Name_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, Edit, xm+0 w80 +%editTextColour% vIBM_Game_Settings_Option_Framerate_1 Limit4 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w80 h18 0x200 Center, Framerate
		Gui, IBM_Game_Settings_Options:Add, Edit, x+3 w80 +%editTextColour% Limit4 vIBM_Game_Settings_Option_Framerate_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, Edit, xm+0 w80 +%editTextColour% Limit3 vIBM_Game_Settings_Option_Particles_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w80 h18 0x200 Center, % "% Particles"
		Gui, IBM_Game_Settings_Options:Add, Edit, x+3 w80 +%editTextColour% Limit3 vIBM_Game_Settings_Option_Particles_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, Edit, xm+0 w80 +%editTextColour% Limit4 vIBM_Game_Settings_Option_HRes_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w80 h18 0x200 Center, H. Resolution
		Gui, IBM_Game_Settings_Options:Add, Edit, x+3 w80 +%editTextColour% Limit4 vIBM_Game_Settings_Option_HRes_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, Edit, xm+0 w80 +%editTextColour% Limit4 vIBM_Game_Settings_Option_VRes_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w80 h18 0x200 Center, V. Resolution
		Gui, IBM_Game_Settings_Options:Add, Edit, x+3 w80 +%editTextColour% Limit4 vIBM_Game_Settings_Option_VRes_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, CheckBox, xm+32 w28 vIBM_Game_Settings_Option_Fullscreen_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Fullscreen
		Gui, IBM_Game_Settings_Options:Add, CheckBox, x+16 w28 vIBM_Game_Settings_Option_Fullscreen_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, CheckBox, xm+32 w28 vIBM_Game_Settings_Option_CapFPSinBG_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Cap FPS in BG
		Gui, IBM_Game_Settings_Options:Add, CheckBox, x+16 w28 vIBM_Game_Settings_Option_CapFPSinBG_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, CheckBox, xm+32 w28 vIBM_Game_Settings_Option_SaveFeats_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Save Feats
		Gui, IBM_Game_Settings_Options:Add, CheckBox, x+16 w28 vIBM_Game_Settings_Option_SaveFeats_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, Text, xm+29 w34 h18 0x200, 100
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Level Amount
		Gui, IBM_Game_Settings_Options:Add, Text, x+10 w28 h18 0x200, 100

		Gui, IBM_Game_Settings_Options:Add, CheckBox, xm+32 w28 vIBM_Game_Settings_Option_ConsolePortraits_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Console Portraits
		Gui, IBM_Game_Settings_Options:Add, CheckBox, x+16 w28 vIBM_Game_Settings_Option_ConsolePortraits_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, CheckBox, xm+32 w28 vIBM_Game_Settings_Option_NarrowHero_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Narrow Hero Boxes
		Gui, IBM_Game_Settings_Options:Add, CheckBox, x+16 w28 vIBM_Game_Settings_Option_NarrowHero_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, CheckBox, xm+32 w28 vIBM_Game_Settings_Option_AllHero_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Show All Bench Seats
		Gui, IBM_Game_Settings_Options:Add, CheckBox, x+16 w28 vIBM_Game_Settings_Option_AllHero_2 gIBM_Game_Settings_Option_Change

		Gui, IBM_Game_Settings_Options:Add, CheckBox, xm+32 w28 vIBM_Game_Settings_Option_Swap25100_1 gIBM_Game_Settings_Option_Change
		Gui, IBM_Game_Settings_Options:Add, Text, x+3 w120 h18 0x200 Center, Swap x25 and x100
		Gui, IBM_Game_Settings_Options:Add, CheckBox, x+16 w28 vIBM_Game_Settings_Option_Swap25100_2 gIBM_Game_Settings_Option_Change
		this.Theme.UseThemeTitleBar("IBM_Game_Settings_Options",false)
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Game_Settings ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Ellywick non-gemfarming Tool
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h72, % "Ellywick Non-Gemfarm Re-roll Tool"
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, w36 xs+58 ys+20 Center, Knight
		Gui, IBM_Home:Add, Text, w36 x+3 Center, Moon
		Gui, IBM_Home:Add, Text, w36 x+3 Center, Gem
		Gui, IBM_Home:Add, Text, w36 x+3 Center, Fates
		Gui, IBM_Home:Add, Text,  w36 x+3 Center, Flames
		textWidth:=groupWidth-271 ;Status text
		buttonX:=groupWidth-107
		Gui, IBM_Home:Add, Button, xs+%buttonX% yp-3 w45 h18 vIBM_NonGemFarm_Elly_Start gIBM_NonGemFarm_Elly_Start, Start
		Gui, IBM_Home:Add, Button, x+7 w45 h18 vIBM_NonGemFarm_Elly_Stop gIBM_NonGemFarm_Elly_Stop, Stop
		Gui, IBM_Home:Add, Text, w40 xs+10 y+5 h18 0x200, Min:Max
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+10 Number Limit1 vIBM_NonGemFarm_Elly_Min_1
		Gui, IBM_Home:Add, Text, w5 x+0 h18 0x200 Center, :
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+0 Number Limit1 vIBM_NonGemFarm_Elly_Max_1
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+10 Number Limit1 vIBM_NonGemFarm_Elly_Min_2
		Gui, IBM_Home:Add, Text, w5 x+0 h18 0x200 Center, :
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+0 Number Limit1 vIBM_NonGemFarm_Elly_Max_2
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+10 Number Limit1 vIBM_NonGemFarm_Elly_Min_3
		Gui, IBM_Home:Add, Text, w5 x+0 h18 0x200 Center, :
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+0 Number Limit1 vIBM_NonGemFarm_Elly_Max_3
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+10 Number Limit1 vIBM_NonGemFarm_Elly_Min_4
		Gui, IBM_Home:Add, Text, w5 x+0 h18 0x200 Center, :
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+0 Number Limit1 vIBM_NonGemFarm_Elly_Max_4
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+10 Number Limit1 vIBM_NonGemFarm_Elly_Min_5
		Gui, IBM_Home:Add, Text, w5 x+0 h18 0x200 Center, :
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w12 x+0 Number Limit1 vIBM_NonGemFarm_Elly_Max_5
		Gui, IBM_Home:Add, Text, x+15 yp-1 w%textWidth% r2 Right vIBM_NonGemFarm_Elly_Status
		
		;++++++++++++++++++GAME TAB++++++++++++++++++
		Gui, IBM_Home:Tab, Game
		;Game location
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 ym+48 w%groupWidth% h127 vIBM_Group_Game_Location, Game Location
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, w55 xs+5 ys+20 h18 0x200, Executable:
		editWidth:=groupWidth-255
		Gui, IBM_Home:Add, Edit, +%editTextColour% w%editWidth% x+5 vIBM_Game_Exe gIBM_Game_Location_Settings
		this.AddToolTip("IBM_Game_Exe", "The game executable file name, normally IdleDragons.exe")
		Gui, IBM_Home:Add, CheckBox, x+10 h18 0x200 vIBM_Game_Hide_Launcher gIBM_Game_Location_Settings, Hide launcher
		this.AddToolTip("IBM_Game_Hide_Launcher", "Select this option to hide the window created by the launch command. Useful when using an alternative launcher and do not want to see the window it creates. Do not use when launching the game directly")
		buttonX:=groupWidth-83
		Gui, IBM_Home:Add, Button, xs+%buttonX% yp+0 w75 vIBM_Game_Copy_From_Game gIBM_Game_Copy_From_Game, Copy from IC
		editWidth:=groupWidth-74
		Gui, IBM_Home:Add, Text, w55 xs+5 y+5 h18 0x200, Location:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w40 x+5 w%editWidth% r2 vIBM_Game_Path gIBM_Game_Location_Settings
		this.AddToolTip("IBM_Game_Path", "The game install location. Must include the trailing \")
		Gui, IBM_Home:Add, Text, w55 r2 xs+5 y+5 h18, Launch Command:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w40 x+5 w%editWidth% r2 vIBM_Game_Launch gIBM_Game_Location_Settings
		this.AddToolTip("IBM_Game_Launch", "The launch command for the game. This is seperated to allow the use of different launchers")
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Game_Location ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Window settings
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h70 vIBM_Group_Window_Settings, Window Options
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, xs+10 ys+20 h18 0x200, Farm script screen position (x,y):
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w32 x+2 Number Limit4 vIBM_Window_X gIBM_Generic_Setting_Int
		Gui, IBM_Home:Add, Text, x+2 h18 0x200, ,
		Gui, IBM_Home:Add, Edit, +%editTextColour%  w32 x+2 Number Limit4 vIBM_Window_Y gIBM_Generic_Setting_Int
		Gui, IBM_Home:Add, CheckBox, x+15 h18 0x200 vIBM_Window_Hide gIBM_Generic_Setting_Int, Hide
		buttonX:=groupWidth-85
		Gui, IBM_Home:Add, Button, xs+%buttonX% yp+0 w75 r2 vIBM_Theme_Manager_Open gIBM_Theme_Manager_Open,Theme manager
		Gui, IBM_Home:Add, CheckBox, xs+10 ys+44 h18 0x200 vIBM_Window_Wide gIBM_Generic_Hub_Setting_Int, Wide Home layout
		;Theme manager window. Note this is NOT themed, to prevent situations where it is made unusable (e.g. white text in white edit boxes)
		Gui, IBM_Theme_Manager:New,,Theme
		Gui, IBM_Theme_Manager:-Resize -MaximizeBox +HwndOpt_Hwnd
		Gui, IBM_Theme_Manager:Font,, Microsoft Sans Serif ;Required as systems may have odd default fonts, e.g. in non-Latin regions
		this.IBM_Theme_Manager_Hwnd:=Opt_Hwnd ;Save handle to the options window
		
		Gui, IBM_Theme_Manager:Add, Button, xm+5 ym+0 w120 gIBM_Theme_Manager_Load_Light, Load light theme
		Gui, IBM_Theme_Manager:Add, Button, x+15 w120 gIBM_Theme_Manager_Refresh, Update examples
		
		Gui, IBM_Theme_Manager:Add, Button, xm+5 y+5 w120 gIBM_Theme_Manager_Load_Dark, Load dark theme
		Gui, IBM_Theme_Manager:Add, Button, x+15 w120 gIBM_Theme_Manager_Accept, Accept
		
		Gui, IBM_Theme_Manager:Font, w700
		Gui, IBM_Theme_Manager:Add, Groupbox, Section xm+0 y+3 w265 h305, Theme Configuration
		Gui, IBM_Theme_Manager:Font, w400
		
		Gui, IBM_Theme_Manager:Add, Progress, xs+168 ys+15 w45 h255 Disabled BackgroundWhite, 0 ;This exists just to provide a white box for contrast in the examples
		Gui, IBM_Theme_Manager:Add, Progress, xs+214 ys+15 w45 h255 Disabled BackgroundBlack, 0 ;And for black (as text will necessarily be visible against one of the two)
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 ys+18 w100 h18 0x200 Right,Default text
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_DefaultText,% this.Theme.GetThemeHexString("DefaultText")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_DefaultText_Example,Example  Example ;Note the double-space here
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Warning text
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_WarningText,% this.Theme.GetThemeHexString("WarningText")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_WarningText_Example,Example  Example
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Special text 1
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_SpecialText1,% this.Theme.GetThemeHexString("SpecialText1")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_SpecialText1_Example,Example  Example
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Special text 2
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_SpecialText2,% this.Theme.GetThemeHexString("SpecialText2")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_SpecialText2_Example,Example  Example
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Edit box text
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_EditText,% this.Theme.GetThemeHexString("EditText")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_EditText_Example,Example  Example

		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Status good
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_TrafficLightGood,% this.Theme.GetThemeHexString("TrafficLightGood")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_TrafficLightGood_Example,Example  Example

		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Status neutral
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_TrafficLightNeutral,% this.Theme.GetThemeHexString("TrafficLightNeutral")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_TrafficLightNeutral_Example,Example  Example

		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Status evil
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_TrafficLightBad,% this.Theme.GetThemeHexString("TrafficLightBad")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_TrafficLightBad_Example,Example  Example
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Table text
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_TableText,% this.Theme.GetThemeHexString("TableText")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_TableText_Example,Example  Example
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Table background
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_TableBackground,% this.Theme.GetThemeHexString("TableBackground")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_TableBackground_Example,Example  Example
		
		Gui, IBM_Theme_Manager:Add, Text, xs+5 y+5 w100 h18 0x200 Right,Window background
		Gui, IBM_Theme_Manager:Add, Edit, x+10 w45 r1 Limit6 vIBM_Theme_Manager_WindowBackground,% this.Theme.GetThemeHexString("WindowBackground")
		Gui, IBM_Theme_Manager:Add, Text, x+10 h18 0x200 BackgroundTrans vIBM_Theme_Manager_WindowBackground_Example,Example  Example
				
		Gui, IBM_Theme_Manager:Add, CheckBox, xs+10 y+10 h18 0x200 vIBM_Theme_Manager_DarkMode, Use dark mode title bar
		GuiControl,IBM_Theme_Manager:, IBM_Theme_Manager_DarkMode,% this.Theme.Theme.DarkMode
		this.RefreshThemeManagerExamples()
		this.Theme.UseThemeTitleBar("IBM_Theme_Manager",false) ;This is themed since it's simple light/dark
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Window_Settings ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Log
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h49 vIBM_Group_Log, % "Log Options"
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, CheckBox, xs+10 ys+20 h18 0x200 vIBM_Logger_MiniLog gIBM_Generic_Setting_Int, Output mini log
		this.AddToolTip("IBM_Logger_MiniLog", "Select this option to output a small log (MiniLog.json) containing just details of the previous run, for use with monitoring tools etc")
		Gui, IBM_Home:Add, CheckBox, x+15 h18 0x200 vIBM_Logger_ZoneLog gIBM_Generic_Setting_Int,Log zone progression
		this.AddToolTip("IBM_Logger_ZoneLog", "Select this option to include zone progression details in the main log. This massively increases the log size and makes it much less human readable, so should only be turned on when debugging your setup")
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Log ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Offsets
		sideBarWidth:=95 ;Sidebar split used for both offsets and versions
		mainWidth:=groupWidth-sideBarWidth-8
		sideBarOffset:=mainWidth+9
		offsetsHeight:=132
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%mainWidth% h%offsetsHeight% vIBM_Group_Offsets, Offsets
		Gui, IBM_Home:Font, w400
		gameMajor:=g_SF.Memory.ReadBaseGameVersion() ;Major version, e.g. 636.3 will return 636
		gameMinor:=g_SF.Memory.IBM_ReadGameVersionMinor() ;If the game is 636.3, return .3, 637 will return empty as it has no minor version
		if(gameMajor)
		{
			gameVersion:=gameMajor . gameMinor
			colour:=this.Theme.GetThemeTextColour()
		}
		else
		{
			gameVersion:="<Not found>"
			colour:=this.Theme.GetThemeTextColour("WarningText")
		}
		gameVersion:=gameMajor ? gameMajor . gameMinor : "<Not found>"
		Gui, IBM_Home:Add, Text, w200 xs+10 ys+15 h18 0x200 %colour% vIBM_Offsets_Text_Game, % "Game Version: " . gameVersion
		Gui, IBM_Home:Add, Text, w230 xs+10 y+0 h18 0x200 vIBM_Offsets_Text_Platform, % "Platform: " . g_IriBrivMaster.GetPlatformString()

		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Text, w45 xs+10 y+2 h18 0x200, % "Pointers"
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, w180 x+10 h18 0x200 vIBM_Offsets_Text_Pointers_Current, % "Current: " . g_IriBrivMaster.GetPointersVersion()
		Gui, IBM_Home:Add, Text, w180 xp+0 y+0 h18 0x200 vIBM_Offsets_Text_Pointers_GitHub, % "GitHub: <Not checked>"

		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Text, w45 xs+10 y+2 h18 0x200, % "Imports"
		Gui, IBM_Home:Font, w400
		currentImports:=g_SF.Memory.GetImportsVersion()
		comparison:=g_IriBrivMaster.VersionComparison(gameVersion,currentImports)
		if(comparison.GT)
			colour:=this.Theme.GetThemeTextColour("WarningText")
		else
			colour:=this.Theme.GetThemeTextColour()
		Gui, IBM_Home:Add, Text, w180 x+10 %colour% h18 0x200 vIBM_Offsets_Text_Imports_Current, % "Current: " . currentImports
		Gui, IBM_Home:Add, Text, w180 xp+0 y+0 h18 0x200 vIBM_Offsets_Text_Imports_GitHub, % "GitHub: <Not checked>"
		;Offsets - check sidebar
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+%sideBarOffset% ys+0 w%sideBarWidth% h%offsetsHeight%,Offset Check
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Button, xs+10 yp+18 w75 vIBM_Offsets_Check_Now gIBM_Offsets_Check_Now,Check now
		Gui, IBM_Home:Add, Button, xs+10 y+4 w75 vIBM_Offsets_Download gIBM_Offsets_Download, Download
		Gui, IBM_Home:Add, CheckBox, xs+10 y+4 h18 vIBM_Offsets_Check gIBM_Generic_Hub_Setting_Int,On load
		this.AddToolTip("IBM_Offsets_Check", "Check this option to automatically check for updates to Briv Master when the Home is started")
		Gui, IBM_Home:Add, CheckBox, xs+10 y+4 h18 vIBM_Offsets_Lock_Pointers gIBM_Generic_Hub_Setting_Int,Imports only
		this.AddToolTip("IBM_Offsets_Lock_Pointers", "Check this option to only apply new imports when downloading. Use this if you have tweaked the pointers yourself")
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Offsets ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Server
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h50 vIBM_Group_Server, Server
		Gui, IBM_Home:Font, w400
		textWidth:=groupWidth-50
		Gui, IBM_Home:Add, Text, w%textWidth% xs+10 ys+15 r2 vIBM_Server_Text_PS, % "Play Server: " . g_IriBrivMaster.GetPlayServerFriendly()
		buttonX:=groupWidth-62
		Gui, IBM_Home:Add, Button, xs+%buttonX% yp+3 w50 vIBM_Server_Check gIBM_Server_Check, Refresh
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Server ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Versions - core, static
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%mainWidth% h65, Core Version
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, xs+10 ys+15 w10 h18 0x200 vIBM_Version_Status_SH, % IC_IriBrivMaster_GUI.IBM_SYMBOL_UI_LIGHT
		textWidth:=mainWidth-85
		Gui, IBM_Home:Add, Text, x+5 w%textWidth% h18 0x200 vIBM_Version_Text_SH, % "Briv Master: " . g_IriBrivMaster.GetCurrentBMDetails()[1]
		readMeLocation:=A_ScriptDir . "\ReadMe.md"
		if(FileExist(readMeLocation))
		{
			textX:=mainWidth-55
			Gui, IBM_Home:Add, Link, xs+%textX% yp+0 w45 h18 0x200 vIBM_Version_Readme_SH, % "<a href=""" . readMeLocation . """>Readme</a>"
		}
		Gui, IBM_Home:Add, Text, w200 xs+25 yp+20 h18 0x200, % "AHK Version: " . A_AhkVersion

		;Versions - check sidebar
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+%sideBarOffset% ys+0 w%sideBarWidth% h65, Version Check
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Button, xs+10 ys+18 w75 vIBM_Version_Check_Now gIBM_Version_Check_Now, Check now
		Gui, IBM_Home:Add, CheckBox, xs+10 y+4 h18 vIBM_Version_Check gIBM_Generic_Hub_Setting_Int,On load
		this.AddToolTip("IBM_Version_Check", "Select to automatically check for updates when Briv Master Home starts")

		;++++++++++++++++++ROUTE TAB++++++++++++++++++
		Gui, IBM_Home:Tab, Route
		;Combine
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 ym+48 w%groupWidth% h42 vIBM_Group_Start_Strat, Starting Strategy
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, CheckBox, xs+10 ys+15 h18 vIBM_Route_Combine gIBM_Generic_Setting_Int, Combine Thellora and Briv
		this.AddToolTip("IBM_Route_Combine","Combining Thellora and Briv causes them to jump together from zone 1, otherwise only Thellora will jump from zone 1")
		Gui, IBM_Home:Add, CheckBox, x+20 h18 vIBM_Route_Combine_Boss_Avoidance gIBM_Generic_Setting_Int, Avoid Bosses
		this.AddToolTip("IBM_Route_Combine_Boss_Avoidance","When this option is selected and Thellora in present in M, Briv Master will check if Thellora will rush into a boss and attempt to adjust from combine to non-combine or vice versa if doing so will cause her to land on a non-boss zone instead.`nIf using this mode with Feat Swapping and an M jump greater than the E jump, an additional jump's worth of stacks are generated in the prior run if possible") ;TODO: Review 2nd part of this tooltip
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Start_Strat ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Route settings for jump/stacking zones
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h270 vIBM_Group_Route, Route
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, xs+10 ys+16 h18, % "Select zones to jump with the Q formation ("
		textColour:=this.Theme.GetThemeTextColour("TrafficLightGood")
		Gui, IBM_Home:Add, Text, x+0 h18 %textColour%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_JUMP
		Gui, IBM_Home:Add, Text, x+0 h18, % ") and to perform online stacking ("
		textColour:=this.Theme.GetThemeTextColour("TrafficLightBad")
		Gui, IBM_Home:Add, Text, x+0 h18 %textColour%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_STACK
		Gui, IBM_Home:Add, Text, x+0 h18, % ")"
		this.CreateRouteBoxes(35)
		this.RefreshRouteJumpBoxes()
		this.RefreshRouteStackBoxes()
		this.Theme.UseThemeTextColour("IBM_Home")
		if(this.Wide)
		{
			Gui, IBM_Home:Add, Text, xs+400 ys+16 r2 w38 h18 Center, Briv Jumps
			Gui, IBM_Home:Add, Text, xs+402 y+15 h18 0x200, Q:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w20 xs+415 yp+0 Number Limit2 vIBM_Route_BrivJump_Q gIBM_Generic_Setting_Int
			Gui, IBM_Home:Add, Text, xs+402 y+15 h18 0x200, E:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w20 xs+415 yp+0 Number Limit2 vIBM_Route_BrivJump_E gIBM_Generic_Setting_Int
			Gui, IBM_Home:Add, Text, xs+402 y+15 h18 0x200, M:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w20 xs+415 yp+0 Number Limit2 vIBM_Route_BrivJump_M gIBM_Generic_Setting_Int
			Gui, IBM_Home:Add, Button, w40 xs+400 y+20 h22 vIBM_Route_Import_Button gIBM_Route_Import_Button, Import
			Gui, IBM_Home:Add, Button, w40 xs+400 y+10 h22 vIBM_Route_Export_Button gIBM_Route_Export_Button, Export
		}
		else
		{
			Gui, IBM_Home:Add, Text, xs+11 y+5 h18 0x200, Briv Jumps
			Gui, IBM_Home:Add, Text, x+15 h18 0x200, Q:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w20 x+3 Number Limit2 vIBM_Route_BrivJump_Q gIBM_Generic_Setting_Int
			Gui, IBM_Home:Add, Text, x+15 h18 0x200, E:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w20 x+3 Number Limit2 vIBM_Route_BrivJump_E gIBM_Generic_Setting_Int
			Gui, IBM_Home:Add, Text, x+15 h18 0x200, M:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w20 x+3 Number Limit2 vIBM_Route_BrivJump_M gIBM_Generic_Setting_Int
			Gui, IBM_Home:Add, Button, w60 xs+256 yp+0 h22 vIBM_Route_Import_Button gIBM_Route_Import_Button, Import
			Gui, IBM_Home:Add, Button, w60 x+10 h22 vIBM_Route_Export_Button gIBM_Route_Export_Button, Export
		}
		this.AddToolTip("IBM_Route_BrivJump_Q", "The number of additional zones Briv jumps using the Q formation")
		this.AddToolTip("IBM_Route_BrivJump_E", "The number of additional zones Briv jumps using the E formation when feat swapping. Ignored if Briv is not saved in E")
		this.AddToolTip("IBM_Route_BrivJump_M", "The number of additional zones Briv jumps using the M (Modron) formation when feat swapping. Used when combining to determine the initial jump.")
		GuiControlGet, lastItemPos, IBM_Home:Pos,IBM_Route_Export_Button ;Used for setting the next box
		groupEnd:=lastItemPosY+lastItemPosH-nextGroupStart+8
		GuiControl, IBM_Home:Move, IBM_Group_Route, h%groupEnd%
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Route ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Stacking zones
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h75 vIBM_Group_Stacking, Stacking Zones
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, xs+10 ys+20 h18 0x200, Offline:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w31 x+3 yp+0 Number Limit4 vIBM_Offline_Stack_Zone gIBM_Generic_Setting_Int
		this.AddToolTip("IBM_Offline_Stack_Zone","Offline stacking or blank restarts will be performed on or after this zone during normal operation")
		Gui, IBM_Home:Add, Text, x+10 h18 0x200, Min recovery:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w31 x+3 yp+0 Number Limit4 vIBM_OffLine_Stack_Min gIBM_Generic_Setting_Int
		this.AddToolTip("IBM_OffLine_Stack_Min","The minimum zone Briv can farm stacks on; that is the lowest zone that the W formation, excluding Farideh if used, does not kill enemies. Used for recovery")
		Gui, IBM_Home:Add, Text, x+10 h18 0x200, Target online:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w31 x+3 Number Limit4 vIBM_Online_Melf_Min gIBM_Generic_Setting_Int
		this.AddToolTip("IBM_Online_Melf_Min","The farm will stack at the first stack zone greater than or equal to this")
		Gui, IBM_Home:Add, Text, xs+10 y+5 h18 0x200, % "Farideh's ultimate trigger:"
		Gui, IBM_Home:Add, DropDownList, cRed w110 x+3 AltSubmit vIBM_Online_Farideh_Condition gIBM_Generic_Setting_Int, Active enemies|Attacking enemies|Tatyana return
		Gui, IBM_Home:Add, Text, x+3 h18 0x200, with threshold:
		Gui, IBM_Home:Add, Edit, +%editTextColour% x+3 w32 Number Limit4 vIBM_Online_Farideh_Threshold gIBM_Generic_Setting_Int
		this.AddToolTip("IBM_Online_Farideh_Threshold","Use these options to tune Farideh's ultimate usage.`nFor Active enemies and Attacking enemies, this is the number of enemies at which Farideh's ultimate will be used when stacking.`nFor Tatyana return the number of game milliseconds remaining on her return timer after which the ultimate should be used, e.g. 1250ms at x12.5 will result in the ultimate being used 100ms real time before she returns")
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Stacking ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Offline Settings
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h100 vIBM_Group_Offline, Offline Settings
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, xs+10 ys+20 h18 0x200, Platform login:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w40 x+3 Number Limit5 vIBM_OffLine_Delay_Time gIBM_Generic_Setting_Int
		Gui, IBM_Home:Add, Text, x+3 h18 0x200, ms
		this.AddToolTip("IBM_OffLine_Delay_Time", "The time to wait during an offline restart between the previous instance of the game saving, and the new one completing platform login. Set this high enough to consistently trigger stacking, but no higher")
		Gui, IBM_Home:Add, Text, x+15 h18 0x200, Restart sleep:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w30 x+3 Number Limit4 vIBM_OffLine_Sleep_Time gIBM_Generic_Setting_Int
		Gui, IBM_Home:Add, Text, x+3 h18 0x200, ms
		this.AddToolTip("IBM_OffLine_Sleep_Time", "The time to wait between the game closing and launching a new copy. This should only be increased from 0 if the lack of delay causes platform issues")
		Gui, IBM_Home:Add, Text, x+15 h18 0x200, Timeout factor:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w20 x+3 Number Limit2 vIBM_OffLine_Timeout gIBM_Generic_Setting_Int
		this.AddToolTip("IBM_OffLine_Timeout", "Controls the time allowed for the game to start and close. The start time is 10s times this value, and the initial close time is 2s times this value")
		Gui, IBM_Home:Add, Text, xs+10 y+5 h18 0x200, Offline every:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w25 x+3 Number Limit3 vIBM_OffLine_Freq_Edit gIBM_OffLine_Freq_Edit
		Gui, IBM_Home:Add, Text, x+5 h18 0x200, runs
		this.AddToolTip("IBM_OffLine_Freq_Edit", "The frequency of offline runs. A value of 1 disables hybrid stacking and will restart every run if stacks are required")
		Gui, IBM_Home:Add, CheckBox, x+15 h20 0x200 vIBM_Route_Offline_Restore_Window gIBM_Generic_Setting_Int, Restore window
		this.AddToolTip("IBM_Route_Offline_Restore_Window", "Sets the default Restore Window option to be used when the script starts")
		Gui, IBM_Home:Add, CheckBox, xs+10 y+5 h18 0x200 vIBM_OffLine_Blank gIBM_OffLine_Blank, Blank restarts
		this.AddToolTip("IBM_OffLine_Blank", "Blank offline runs do not attempt to stack, and will online stack if needed along with a restart of the game. Use this to clear memory bloat in the game when offline stacking is slower overall than online")
		Gui, IBM_Home:Add, CheckBox, x+10 h18 0x200 vIBM_OffLine_Blank_Stop gIBM_Generic_Setting_Int, Stop progress
		this.AddToolTip("IBM_OffLine_Blank_Stop", "Stop auto progression during blank restarts. Select if restarting the game takes long enough to trigger offline progress")
		if(this.Wide)
		{
			Gui, IBM_Home:Add, CheckBox, x+10 h18 0x200 vIBM_OffLine_Blank_Relay gIBM_OffLine_Blank, Relay restarts
			Gui, IBM_Home:Add, Text, x+10 h18 0x200, Relay start zone:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w25 x+3 Number Limit4 vIBM_OffLine_Blank_Relay_Zones gIBM_OffLine_Blank
		}
		else
		{
			Gui, IBM_Home:Add, CheckBox, xs+10 y+5 h18 0x200 vIBM_OffLine_Blank_Relay gIBM_OffLine_Blank, Relay restarts
			Gui, IBM_Home:Add, Text, x+10 h18 0x200, Relay start zone:
			Gui, IBM_Home:Add, Edit, +%editTextColour% w25 x+3 Number Limit4 vIBM_OffLine_Blank_Relay_Zones gIBM_OffLine_Blank
		}
		this.AddToolTip("IBM_OffLine_Blank_Relay", "Relay blank restarts launch a new instance of the game prior to closing the current one. Not compatible with the Epic Games Launcher")
		this.AddToolTip("IBM_OffLine_Blank_Relay_Zones", "The zone to launch the relay on or after. Regardless of this setting the relay will not start until after Thellora's landing zone")
		GuiControlGet, lastItemPos, IBM_Home:Pos,IBM_OffLine_Blank_Relay ;Used for setting the next box
		groupEnd:=lastItemPosY+lastItemPosH-nextGroupStart+10
		GuiControl, IBM_Home:Move, IBM_Group_Offline, h%groupEnd%
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Offline ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Ellywick Casino
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h50, % "Ellywick's Casino"
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, xs+10 ys+20 h18 0x200, Target Gem cards:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w15 x+2 Number Limit1 vIBM_Casino_Target_Base gIBM_Generic_Setting_Int
		Gui, IBM_Home:Add, Text, x+10 h18 0x200, Maximum redraws:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w15 x+3 Number Limit1 vIBM_Casino_Redraws_Base gIBM_Generic_Setting_Int
		Gui, IBM_Home:Add, Text, x+10 h18 0x200, Minimum cards:
		Gui, IBM_Home:Add, Edit, +%editTextColour% w15 x+3 Number Limit1 vIBM_Casino_MinCards_Base gIBM_Generic_Setting_Int

		;++++++++++++++++++LEVELS TAB++++++++++++++++++
		Gui, IBM_Home:Tab, Levels
		;Levelling Options
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 ym+48 w%groupWidth% h97 vIBM_Group_Level_Options, Levelling Options
		Gui, IBM_Home:Font, w400
		Gui, IBM_Home:Add, Text, xs+10 ys+15 h18 0x200, Max sequential keys
		Gui, IBM_Home:Add, Edit, +%editTextColour% w40 x+5 Number w20 Limit2 vIBM_LevelManager_Input_Max gIBM_LevelManager_Input_Max
		this.AddToolTip("IBM_LevelManager_Input_Max", "The maximum number of key presses to be send to the game in a batch during levelling. Minimum of 2.  Note that during initial levelling all priority champions will be levelled regardless of this setting")
		Gui, IBM_Home:Add, Text, x+15 h18 0x200, Modifier key
		Gui, IBM_Home:Add, DropDownList, x+5 w45 vIBM_Level_Options_Mod_Key gIBM_Generic_Setting_String, Shift|Ctrl|Alt
		this.AddToolTip("IBM_Level_Options_Mod_Key", "The modifier keybind to use for levelling less than 100 levels at a time. Set all champions to multiples of 100 levels if you do not wish to use this feature")
		Gui, IBM_Home:Add, Text, x+5 h18 0x200, for x
		Gui, IBM_Home:Add, DropDownList, x+1 w35 vIBM_Level_Options_Mod_Value gIBM_Generic_Setting_Int, 10|25
		this.AddToolTip("IBM_Level_Options_Mod_Value", "The levelling amount associated with the key selected. This must match the in-game keybind")
		Gui, IBM_Home:Add, CheckBox, xs+10 y+8 h18 0x200 vIBM_Level_Options_Suppress_Front gIBM_Generic_Setting_Int, Suppress Front Column
		this.AddToolTip("IBM_Level_Options_Suppress_Front", "Do not level champions other than Briv in the front column. Used to maximise Briv's stack gain in the Casino. The champion will be levelled opportunistically when the formation is under attack")
		Gui, IBM_Home:Add, CheckBox, x+15 h18 0x200 vIBM_Level_Options_Ghost gIBM_Generic_Setting_Int, Ghost Level
		this.AddToolTip("IBM_Level_Options_Ghost", "During the Casino, level champions that are not part of the formation so long as they will not be placed, either due to all slots being full or the formation being under attack. This option makes it more likely all speed effects will be ready for the first normal zone. Only applied when Thellora is in the M formation")
		Gui, IBM_Home:Add, CheckBox, x+5 h18 0x200 vIBM_Level_Diana_Cheese gIBM_Generic_Setting_Int, Dynamic Diana
		this.AddToolTip("IBM_Level_Diana_Cheese", "Diana can give excess chests after the daily reset. This option will raise her level to 200 for Electrum Chest Scavenger from 3 minutes before the daily reset to 30 minutes after. Her level in the main options should be left at 100")
		Gui, IBM_Home:Add, CheckBox, xs+10 y+8 h18 0x200 vIBM_Level_Options_BrivBoost_Use gIBM_Level_Options_BrivBoost_Use, Briv Level Boost
		this.AddToolTip("IBM_Level_Options_BrivBoost_Use", "When enabled will increase Briv's level during online stacking. Use when Briv's normal level is insufficent for later stack zones")
		Gui, IBM_Home:Add, Text, x+15 h18 0x200, Safety Factor
		Gui, IBM_Home:Add, Edit, +%editTextColour% w20 x+1 Number Limit2 vIBM_LevelManager_Boost_Multi gIBM_Generic_Setting_Int
		this.AddToolTip("IBM_LevelManager_Boost_Multi", "This is how many times greater Briv's HP should be than the incoming damage of 100 enemies. Useful range 8 (fast stacking) to 12 (slower stacking)")
		Gui, IBM_Home:Add, CheckBox, x+15 h18 0x200 vIBM_Level_Recovery_Softcap gIBM_Generic_Setting_Int, Recovery Levelling
		this.AddToolTip("IBM_Level_Recovery_Softcap", "With this option selected, champions will be levelled to their last update when reaching a boss zone in stack conversion recovery, that is when Briv has no stacks and the minimum stack zone has yet to be reached. This can aid killing armoured bosses, but will raise the minimum zone required to gain online stacks")
		GuiControlGet, groupPos, IBM_Home:Pos,IBM_Group_Level_Options ;Used for setting the next box
		nextGroupStart:=groupPosY+groupPosH+1
		;Level manager - headings
		Gui, IBM_Home:Font, w700
		Gui, IBM_Home:Add, Groupbox, Section xm+2 y%nextGroupStart% w%groupWidth% h70 vIBM_LevelManager, Level Manager
		Gui, IBM_Home:Font, w400
		if(this.Wide) ;The refresh button will be placed to the right
		{
			Gui, IBM_Home:Add, Text, xs+7 ys+15 h20 w10 Right 0x200, S
		}
		else
		{
			buttonWidth:=groupWidth-20
			Gui, IBM_Home:Add, Button, w%buttonWidth% xs+10 ys+15 h18 vIBM_LevelManager_Refresh gIBM_LevelManager_Refresh, Refresh
			Gui, IBM_Home:Add, Text, xs+7 y+1 h20 w10 Right 0x200, S
		}
		Gui, IBM_Home:Add, Text, x+5 h20 w85 Left 0x200, Champion
		Gui, IBM_Home:Add, Text, w35 h20 x+1 0x200 vIBM_LevelRow_H_Start, Start
		this.AddToolTip("IBM_LevelRow_H_Start", "Levels used for the first zone")
		Gui, IBM_Home:Add, Text, w52 h20 x+1 0x200 vIBM_LevelRow_H_Priority, Priority
		this.AddToolTip("IBM_LevelRow_H_Priority", "Levelling priority for the first zone. Options with levels beside them will use the selected priority only until that level is reached, at which point it will be treated as 0")
		Gui, IBM_Home:Add, Text, w35 h20 x+1 0x200, Normal
		Gui, IBM_Home:Add, Text, w83 x+4 0x200 h20 Center 0x200, Formations
		Gui, IBM_Home:Add, Text, w61 x+5 0x200 h20 Center 0x200, Feats
		if(this.Wide)
			Gui, IBM_Home:Add, Button, w45 x+8 h18 vIBM_LevelManager_Refresh gIBM_LevelManager_Refresh, Refresh

		;Level manager - create the maximum of 40 rows (4 formations x 10 champions), we will hide what we don't need when populating TODO: Decide if we really need 40 here, it's a complete solution...but also pointlessly overkill. 12 is relatively high (as of 23Aug25)
		this.LevelRow_Priority_Value:=[5,4,3,2,1,0,-1,-2,-3,-4,-5,5,4,3,2,1,5,4,3,2,1]
		this.LevelRow_Priority_Limit:=["","","","","","","","","","","",100,100,100,100,100,200,200,200,200,200]
		loop 40
			this.CreateLevelRow(A_Index)
		this.RefreshLevelRows() ;Also resizes things
		this.controlLock:=false
	}

	RefreshRouteJumpBoxes()
	{
		colourJump:=this.Theme.GetThemeTextColour("TrafficLightGood")
		colourWalk:=this.Theme.GetThemeTextColour("DefaultText")
		loop, 50
		{
			textColour:=g_IBM_Settings["IBM_Route_Zones_Jump",A_Index] ? colourJump : colourWalk
			GuiControl, IBM_Home: +%textColour%, IBM_Route_J_%A_Index%
			GuiControl, , IBM_Route_J_%A_Index%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_JUMP
		}
	}

	RefreshRouteStackBoxes()
	{
		colourStack:=this.Theme.GetThemeTextColour("TrafficLightBad")
		colourNoStack:=this.Theme.GetThemeTextColour("DefaultText")
		loop, 50
		{
			textColour:=g_IBM_Settings["IBM_Route_Zones_Stack",A_Index] ? colourStack : colourNoStack
			GuiControl, IBM_Home: +%textColour%, IBM_Route_S_%A_Index%
			GuiControl, , IBM_Route_S_%A_Index%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_STACK
		}
	}

	CreateRouteBoxes(sectionOffsetY) ;sectionOffsetY is the number of pixels from the top of the current section to start the grid
	{
		global
		rowSpacing:=39
		counter:=1
		loop, 5
		{
			rowOffset:=rowSpacing*(A_Index-1)+sectionOffsetY
			Gui, IBM_Home:Font, s9
			Gui, IBM_Home:Add, Text, w35 xs+7 ys+%rowOffset% h35 Center 0x1000 vIBM_Route_%counter%_Zone, %counter%
			Gui, IBM_Home:Font, s16
			Gui, IBM_Home:Add, Text, xp+2 yp+13 Center BackgroundTrans gIBM_Route_J_Click vIBM_Route_J_%counter%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_JUMP
			Gui, IBM_Home:Add, Text, xp+18 yp+1 Center BackgroundTrans gIBM_Route_S_Click vIBM_Route_S_%counter%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_STACK
			counter++
			loop, 9
			{
				Gui, IBM_Home:Font, s9
				Gui, IBM_Home:Add, Text, w35 x+6 ys+%rowOffset% h35 Center 0x1000 vIBM_Route_%counter%_Zone, %counter%
				Gui, IBM_Home:Font, s16
				Gui, IBM_Home:Add, Text, xp+2 yp+13 Center BackgroundTrans gIBM_Route_J_Click vIBM_Route_J_%counter%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_JUMP
				Gui, IBM_Home:Add, Text, xp+18 yp+1 Center BackgroundTrans gIBM_Route_S_Click vIBM_Route_S_%counter%, % IC_IriBrivMaster_GUI.IBM_SYMBOL_ROUTE_STACK
				counter++
			}
		}
		Gui, IBM_Home:Font
	}

	UpdateGUISettings()
    {
        this.controlLock:=true ;Prevent control g-labels messing things up whilst populating. This is particularly important when one label processes multiple controls, as it can read values out of yet-to-be-populated controls and thus blank that setting

		;BRIV MASTER TAB

		;Chests & Rewards
		this.UpdateChestSnatcherOptions()
		;Game settings
		GuiControl, IBM_Home:, IBM_Game_Settings_Profile_1, % g_IBM_Settings.HUB.IBM_Game_Settings_Option_Profile==1
		GuiControl, IBM_Home:, IBM_Game_Settings_Profile_2, % g_IBM_Settings.HUB.IBM_Game_Settings_Option_Profile!=1
		this.GameSettings_Update()
		this.UpdateNonGemFarmEllySettings(g_IBM_Settings.HUB.IBM_Ellywick_NonGemFarm_Cards) ;TODO: Shouldn't need to have a global passed to it

		;BM GAME TAB

		;Game Location
		GuiControl, IBM_Home:, IBM_Game_Exe, % g_IBM_Settings.IBM_Game_Exe
		GuiControl, IBM_Home:, IBM_Game_Path, % g_IBM_Settings.IBM_Game_Path
		GuiControl, IBM_Home:, IBM_Game_Launch, % g_IBM_Settings.IBM_Game_Launch
		GuiControl, IBM_Home:, IBM_Game_Hide_Launcher, % g_IBM_Settings.IBM_Game_Hide_Launcher
		;Window
		GuiControl, IBM_Home:, IBM_Window_X, % g_IBM_Settings.IBM_Window_X
		GuiControl, IBM_Home:, IBM_Window_Y, % g_IBM_Settings.IBM_Window_Y
		GuiControl, IBM_Home:, IBM_Window_Hide, % g_IBM_Settings.IBM_Window_Hide
		GuiControl, IBM_Home:, IBM_Window_Wide, % g_IBM_Settings.HUB.IBM_Window_Wide
		;Logs
		GuiControl, IBM_Home:, IBM_Logger_Minilog, % g_IBM_Settings.IBM_Logger_Minilog
		GuiControl, IBM_Home:, IBM_Logger_ZoneLog, % g_IBM_Settings.IBM_Logger_ZoneLog
		;Offsets
		GuiControl, IBM_Home:, IBM_Offsets_Check, % g_IBM_Settings.HUB.IBM_Offsets_Check
		GuiControl, IBM_Home:, IBM_Offsets_Lock_Pointers, % g_IBM_Settings.HUB.IBM_Offsets_Lock_Pointers
		;Versions
		GuiControl, IBM_Home:, IBM_Version_Check, % g_IBM_Settings.HUB.IBM_Version_Check

		;BM ROUTE TAB

		;Combine options
		GuiControl, IBM_Home:, IBM_Route_Combine, % g_IBM_Settings.IBM_Route_Combine
		GuiControl, IBM_Home:, IBM_Route_Combine_Boss_Avoidance, % g_IBM_Settings.IBM_Route_Combine_Boss_Avoidance
		;Route
		this.RefreshRouteJumpBoxes()
		this.RefreshRouteStackBoxes()
		;Briv jumps
		GuiControl, IBM_Home:, IBM_Route_BrivJump_Q, % g_IBM_Settings.IBM_Route_BrivJump_Q
		GuiControl, IBM_Home:, IBM_Route_BrivJump_E, % g_IBM_Settings.IBM_Route_BrivJump_E
		GuiControl, IBM_Home:, IBM_Route_BrivJump_M, % g_IBM_Settings.IBM_Route_BrivJump_M
		;Stacking Zone
		GuiControl, IBM_Home:, IBM_Offline_Stack_Zone, % g_IBM_Settings.IBM_Offline_Stack_Zone
		GuiControl, IBM_Home:, IBM_OffLine_Stack_Min, % g_IBM_Settings.IBM_Offline_Stack_Min
		GuiControl, IBM_Home:, IBM_Online_Melf_Min, % g_IBM_Settings.IBM_Online_Melf_Min
		GuiControl, IBM_Home:, IBM_Online_Farideh_Threshold, % g_IBM_Settings.IBM_Online_Farideh_Threshold
		GuiControl, IBM_Home:Choose,IBM_Online_Farideh_Condition, % g_IBM_Settings.IBM_Online_Farideh_Condition
		;Offline settings
		GuiControl, IBM_Home:, IBM_OffLine_Delay_Time, % g_IBM_Settings.IBM_OffLine_Delay_Time
		GuiControl, IBM_Home:, IBM_OffLine_Sleep_Time, % g_IBM_Settings.IBM_OffLine_Sleep_Time
		GuiControl, IBM_Home:, IBM_OffLine_Freq_Edit, % g_IBM_Settings.IBM_OffLine_Freq
		GuiControl, IBM_Home:, IBM_OffLine_Blank, % g_IBM_Settings.IBM_OffLine_Blank
		GuiControl, IBM_Home:, IBM_OffLine_Blank_Relay, % g_IBM_Settings.IBM_OffLine_Blank_Relay
		GuiControl, IBM_Home:, IBM_OffLine_Blank_Stop, % g_IBM_Settings.IBM_OffLine_Blank_Stop
		GuiControl, IBM_Home:, IBM_OffLine_Blank_Relay_Zones, % g_IBM_Settings.IBM_OffLine_Blank_Relay_Zones
		IBM_Offline_Blank_EnableControls(g_IBM_Settings.IBM_OffLine_Blank,g_IBM_Settings.IBM_OffLine_Blank_Relay)
		GuiControl, IBM_Home:, IBM_OffLine_Timeout, % g_IBM_Settings.IBM_OffLine_Timeout
		GuiControl, IBM_Home:, IBM_Route_Offline_Restore_Window, % g_IBM_Settings.IBM_Route_Offline_Restore_Window
		;Ellywick's Casino
		GuiControl, IBM_Home:, IBM_Casino_Target_Base, % g_IBM_Settings.IBM_Casino_Target_Base
		GuiControl, IBM_Home:, IBM_Casino_Redraws_Base, % g_IBM_Settings.IBM_Casino_Redraws_Base
		GuiControl, IBM_Home:, IBM_Casino_MinCards_Base, % g_IBM_Settings.IBM_Casino_MinCards_Base

		;BM LEVELS TAB

		;Levelling options
		GuiControl, IBM_Home:, IBM_LevelManager_Input_Max, % g_IBM_Settings.IBM_LevelManager_Input_Max
		GuiControl, IBM_Home:, IBM_Level_Options_BrivBoost_Use, % g_IBM_Settings.IBM_LevelManager_Boost_Use
		GuiControl, IBM_Home:, IBM_LevelManager_Boost_Multi, % g_IBM_Settings.IBM_LevelManager_Boost_Multi
		IBM_Level_Options_BrivBoost_Enable(g_IBM_Settings.IBM_LevelManager_Boost_Use)
		GuiControl, IBM_Home:, IBM_Level_Options_Suppress_Front, % g_IBM_Settings.IBM_Level_Options_Suppress_Front
		GuiControl, IBM_Home:, IBM_Level_Options_Ghost, % g_IBM_Settings.IBM_Level_Options_Ghost
		GuiControl, IBM_Home:ChooseString, IBM_Level_Options_Mod_Key, % g_IBM_Settings.IBM_Level_Options_Mod_Key
		GuiControl, IBM_Home:ChooseString, IBM_Level_Options_Mod_Value, % g_IBM_Settings.IBM_Level_Options_Mod_Value
		GuiControl, IBM_Home:, IBM_Level_Diana_Cheese, % g_IBM_Settings.IBM_Level_Diana_Cheese
		GuiControl, IBM_Home:, IBM_Level_Recovery_Softcap, % g_IBM_Settings.IBM_Level_Recovery_Softcap
		;Levelling
		this.RefreshLevelRows()

		this.controlLock:=false
    }

	UpdateChestSnatcherOptions() ;ChestSnatcher options in a separate function so that the window can be updated when opened to overwrite unaccepted changes
	{
		GuiControl, IBM_ChestSnatcher_Options:, IBM_ChestSnatcher_Options_Claim, % g_IBM_Settings.HUB.IBM_DailyRewardClaim_Enable
		GuiControl, IBM_ChestSnatcher_Options:, IBM_ChestSnatcher_Options_Min_Gem, % g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Gem
		GuiControl, IBM_ChestSnatcher_Options:, IBM_ChestSnatcher_Options_Min_Gold, % g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Gold
		GuiControl, IBM_ChestSnatcher_Options:, IBM_ChestSnatcher_Options_Min_Silver, % g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Silver
		GuiControl, IBM_ChestSnatcher_Options:, IBM_ChestSnatcher_Options_Min_Buy, % g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Buy
		GuiControl, IBM_ChestSnatcher_Options:, IBM_ChestSnatcher_Options_Open_Gold, % g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Gold
		GuiControl, IBM_ChestSnatcher_Options:, IBM_ChestSnatcher_Options_Open_Silver, % g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Silver
	}

	CreateLevelRow(index)
	{
		global
		rowSpacing:=this.Wide ? 5 : 6
		Gui, IBM_Home:Add, Text, xs+7 y+%rowSpacing% h20 0x200 w10 Right Hidden vIBM_LevelRow_%index%_Seat
		Gui, IBM_Home:Add, Text, x+5 yp+0 h20 0x200 w85 Left Hidden vIBM_LevelRow_%index%_Name
		Gui, IBM_Home:Add, Edit, +%editTextColour% w35 x+1 Number Limit4 Hidden vIBM_LevelRow_%index%_z1
		Gui, IBM_Home:Add, DropDownList, w52 x+1 Hidden AltSubmit hwndIBM_LevelRow_DLL_%index% vIBM_LevelRow_%index%_Priority, 5|4|3|2|1|0||-1|-2|-3|-4|-5|5↓100|4↓100|3↓100|2↓100|1↓100|5↓200|4↓200|3↓200|2↓200|1↓200
		DDLindex:=IBM_LevelRow_DLL_%index%
		DDLHeight:=17.5*this.GetDPIScale()
		PostMessage, 0x0153, -1, %DDLHeight%,, ahk_id %DDLindex% ;Set height (since H200 or R4 is setting height of dropdown list)
		Gui, IBM_Home:Add, Edit, +%editTextColour% w35 x+1 Number Limit4 Hidden vIBM_LevelRow_%index%_min
		Gui, IBM_Home:Font, Bold
		Gui, IBM_Home:Add, Text, w20 x+4 h20 Center Hidden 0x200 0x1000 vIBM_LevelRow_%index%_Q, Q
		Gui, IBM_Home:Add, Text, w20 x+1 h20 Center Hidden 0x200 0x1000 vIBM_LevelRow_%index%_W, W
		Gui, IBM_Home:Add, Text, w20 x+1 h20 Center Hidden 0x200 0x1000 vIBM_LevelRow_%index%_E, E
		Gui, IBM_Home:Add, Text, w20 x+1 h20 Center Hidden 0x200 0x1000 vIBM_LevelRow_%index%_M, M
		Gui, IBM_Home:Font, Normal
		Gui, IBM_Home:Add, Text, x+4 w20 h20 0x200 CENTER Hidden vIBM_LevelRow_%index%_Feats_Selected
		Gui, IBM_Home:Add, Button, x+1 w20 h20 Hidden vIBM_LevelRow_%index%_Feats_Set gIBM_LevelRow_Feats_Set, % IC_IriBrivMaster_GUI.IBM_SYMBOL_UI_LEFT
		Gui, IBM_Home:Add, Button, x+1 w20 h20 Hidden vIBM_LevelRow_%index%_Feats_Clear gIBM_LevelRow_Feats_Clear, % IC_IriBrivMaster_GUI.IBM_SYMBOL_UI_CLEAR
	}

	RefreshLevelRows()
	{
		this.levelDataSet:=g_IriBrivMaster.IBM_GetGUIFormationData() ;Gets formation data, without levels
		If IsObject(this.levelDataSet)
		{
			colourIn:=this.Theme.GetThemeTextColour("TrafficLightGood")
			colourOut:=this.Theme.GetThemeTextColour("DefaultText")
			this.LoadCurrentLevels()
			index:=1
			for seat, seatMembers in this.levelDataSet
			{
				for champID, champData in seatMembers
				{
					lastY:=this.RefreshLevelRow(index,seat,champData,colourIn,colourOut)
					index++
				}
			}
			while (index<=40) ;Hide remaining rows
			{
				this.HideLevelRow(index,colourOut)
				index++
			}
			;Resize group
			if (lastY) ;If the game isn't running this will not be set
			{
				GuiControlGet, initialSize, IBM_Home:Pos, IBM_LevelManager
				updatedHeight:=lastY-initialSizeY+8
				GuiControl, IBM_Home:Move, IBM_LevelManager, h%updatedHeight%
			}
		}
	}

	RefreshLevelRow(index,seat,data,inColour,outColour) ;Single row
	{
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_Seat, %seat%
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_Seat ;TODO: Why are all these Show commands here?
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_Name, % data["Name"]
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_Name
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_z1, % data["z1"]
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_z1
		testString:=data["prio"] . (data["priolimit"] ?  "↓" . data["priolimit"] : "")
		GuiControl, IBM_Home:ChooseString, IBM_LevelRow_%index%_Priority, %testString%
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_Priority
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_min, % data["min"]
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_min
		textColour:=data["Q"] ? inColour : outColour
		GuiControl, IBM_Home: +%textColour%, IBM_LevelRow_%index%_Q
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_Q
		textColour:=data["W"] ? inColour : outColour
		GuiControl, IBM_Home: +%textColour%, IBM_LevelRow_%index%_W
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_W
		textColour:=data["E"] ? inColour : outColour
		GuiControl, IBM_Home: +%textColour%, IBM_LevelRow_%index%_E
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_E
		textColour:=data["M"] ? inColour : outColour
		GuiControl, IBM_Home: +%textColour%, IBM_LevelRow_%index%_M
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_M
		featCount:=data["Feat_List"] ? data["Feat_List"].Count() : 0
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_Feats_Selected, % featCount . (data["Feat_Exclusive"] ? "" : "+")
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_Feats_Selected
		this.UpdateToolTip("IBM_LevelRow_" . index . "_Feats_Selected", this.GetFeatTooltip(data))
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_Feats_Set
		GuiControl, IBM_Home:Show, IBM_LevelRow_%index%_Feats_Clear
		GuiControlGet, placement, IBM_Home:Pos, IBM_LevelRow_%index%_z1
		return placementY+placementH ;Return the botton of the edit box controls, used to size things
	}

	GetFeatTooltip(data)
	{
		featTooltip:=""
		if(data["Feat_List"] AND data["Feat_List"].Count()>0)
		{
			for id,name in data["Feat_List"]
			{
				featTooltip.=name . " (" . id ")`n"
			}
		}
		return featTooltip
	}

	HideLevelRow(index,colourOut) ;Single row
	{
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_Seat, ""
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_Seat
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_Name, ""
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_Name
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_z1, 0
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_z1
		GuiControl, ChooseString, IBM_LevelRow_%index%_Priority, 0
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_Priority
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_min, 0
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_min
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_max, 0
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_max
		GuiControl, IBM_Home: +%colourOut%, IBM_LevelRow_%index%_Q
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_Q
		GuiControl, IBM_Home: +%colourOut%, IBM_LevelRow_%index%_W
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_W
		GuiControl, IBM_Home: +%colourOut%, IBM_LevelRow_%index%_E
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_E
		GuiControl, IBM_Home: +%colourOut%, IBM_LevelRow_%index%_M
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_M
		GuiControl, IBM_Home:, IBM_LevelRow_%index%_Feats_Selected, ""
		this.UpdateToolTip("IBM_LevelRow_" . index . "_Feats_Selected","") ;Remove tooltip
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_Feats_Selected
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_Feats_Set
		GuiControl, IBM_Home:Hide, IBM_LevelRow_%index%_Feats_Clear
	}

	GetLevelRowData() ;Extracts set levels
	{
		currentLevels:=[]
		if(IsObject(this.levelDataSet)) ;Do not refresh here, as the values entered will be based on the data displayed from the last refresh
		{
			index:=1 ;TODO: Switch this to using champData["ListIndex"]
			for seat, seatMembers in this.levelDataSet
			{
				for champID, champData in seatMembers
				{
					GuiControlGet, value,, IBM_LevelRow_%index%_z1
					if value is integer
						currentLevels[champID,"z1"]:=value
					GuiControlGet, value,, IBM_LevelRow_%index%_Priority
					if value is integer
						currentLevels[champID,"prio"]:=this.LevelRow_Priority_Value[value]
						currentLevels[champID,"priolimit"]:=this.LevelRow_Priority_Limit[value]
					GuiControlGet, value,, IBM_LevelRow_%index%_min
					if value is integer
						currentLevels[champID,"min"]:=value
					currentLevels[champID,"Feat_List"]:=champData["Feat_List"]
					currentLevels[champID,"Feat_Exclusive"]:=champData["Feat_Exclusive"]
					index++
				}
			}
		}
		return currentLevels
	}

	LoadCurrentLevels() ;Loads currently saved levels into the main level data set
	{
		;Levels are saved per stategy, then by champ ID
		savedLevels:=g_IBM_Settings["IBM_LevelManager_Levels"]
		for seat, seatMembers in this.levelDataSet
		{
			for champID, champData in seatMembers
			{
				if savedLevels.hasKey(champID)
				{
					champData["z1"]:=savedLevels[champID,"z1"]
					champData["min"]:=savedLevels[champID,"min"]
					champData["prio"]:=savedLevels[champID,"prio"]
					champData["priolimit"]:=savedLevels[champID,"priolimit"]
					champData["Feat_List"]:=savedLevels[champID,"Feat_List"]
					champData["Feat_Exclusive"]:=savedLevels[champID,"Feat_Exclusive"]
				}
				else
				{
					champData["z1"]:=""
					champData["min"]:=""
					champData["prio"]:=0
					champData["priolimit"]:=""
					champData["Feat_List"]:=""
					champData["Feat_Exclusive"]:=false
				}
			}
		}
	}

	ResetStatusText()
	{
		colour:=this.Theme.GetThemeTextColour()
		this.UpdateRunControlDisable("",true) ;"" resets. Not bothering to check if the Home tab is active here as it's not happening automatically
		this.UpdateRunControlForce("",true)
		GuiControl, IBM_Home:Text, IBM_RunControl_Status, Unable to read data from main script
	}

	UpdateRunControlDisable(disableOffline,allowMoveDraw:=true) ;Offline stacking Pause/Resume
	{
		static lastState:=""
		if(lastState==disableOffline)
			return
		lastState:=disableOffline
		if(lastState==1)
		{
			colour:=this.Theme.GetThemeTextColour("TrafficLightBad")
			GuiControl, IBM_Home:+%colour%, IBM_RunControl_Offline_StatusPause ;Note disabled is 'red' here because offline stacking is normally switched on
			GuiControl, IBM_Home:Text, IBM_RunControl_Offline_Toggle, Resume
		}
		else if(lastState==0)
		{
			colour:=this.Theme.GetThemeTextColour("TrafficLightGood")
			GuiControl, IBM_Home:+%colour%, IBM_RunControl_Offline_StatusPause
			GuiControl, IBM_Home:Text, IBM_RunControl_Offline_Toggle, Pause
		}
		else
		{
			colour:=this.Theme.GetThemeTextColour()
			GuiControl, IBM_Home:+%colour%, IBM_RunControl_Offline_StatusPause
			GuiControl, IBM_Home:Text, IBM_RunControl_Offline_Toggle, Pause
		}
		GuiControl, IBM_Home:Enable, IBM_RunControl_Offline_Toggle
		if(allowMoveDraw)
			GuiControl, IBM_Home:MoveDraw,IBM_RunControl_Offline_StatusPause
	}

	UpdateRunControlForce(queueOffline,allowMoveDraw:=true) ;Force Queue
	{
		static lastState:=""
		if(lastState==queueOffline)
			return
		lastState:=queueOffline
		if(lastState==1)
		{
			colour:=this.Theme.GetThemeTextColour("TrafficLightGood")
			GuiControl, IBM_Home:+%colour%, IBM_RunControl_Offline_StatusQueue
			GuiControl, IBM_Home:Text, IBM_RunControl_Offline_Queue_Toggle, Cancel
		}
		else if (lastState==0)
		{
			colour:=this.Theme.GetThemeTextColour("TrafficLightBad")
			GuiControl, IBM_Home:+%colour%, IBM_RunControl_Offline_StatusQueue
			GuiControl, IBM_Home:Text, IBM_RunControl_Offline_Queue_Toggle, Queue
		}
		else
		{
			colour:=this.Theme.GetThemeTextColour()
			GuiControl, IBM_Home:+%colour%, IBM_RunControl_Offline_StatusQueue
			GuiControl, IBM_Home:Text, IBM_RunControl_Offline_Queue_Toggle, Queue
		}
		GuiControl, IBM_Home:Enable, IBM_RunControl_Offline_Queue_Toggle
		if(allowMoveDraw)
			GuiControl, IBM_Home:MoveDraw,IBM_RunControl_Offline_StatusQueue
	}

	UpdateRunStatus(cycleString,statusString,stackString)
	{
		GuiControl, IBM_Home:Text, IBM_RunControl_Cycle, % cycleString
		GuiControl, IBM_Home:Text, IBM_RunControl_Status, % statusString
		GuiControl, IBM_Home:Text, IBM_RunControl_Stack, % stackString
	}

	SetEllyNonGemFarmStatus(statusString)
	{
		GuiControl, IBM_Home:Text, IBM_NonGemFarm_Elly_Status, % statusString
	}

	IBM_ChestsSnatcher_Status_Update(forceLog:=false)
	{
		curMessage:=g_IriBrivMaster.ChestSnatcher.Messages[g_IriBrivMaster.ChestSnatcher.Messages.maxIndex()]
		;Single-item window
		Gui, IBM_Home:Default
		Gui, ListView, IBM_ChestsSnatcher_Status
		GuiControl, -Redraw, IBM_ChestsSnatcher_Status
		LV_Delete(1)
		LV_Add(,curMessage.time,curMessage.action,curMessage.comment)
		GuiControl, +Redraw, IBM_ChestsSnatcher_Status
		;Multi-item window
		if (WinExist("ahk_id " . g_IriBrivMaster_GUI.IBM_ChestSnatcher_Log_Hwnd) OR forceLog)
		{
			Gui, IBM_ChestSnatcher_Log:Default
			Gui, ListView, IBM_ChestsSnatcher_Status_Expanded
			GuiControl, -Redraw, IBM_ChestsSnatcher_Status_Expanded
			count:=g_IriBrivMaster.ChestSnatcher.Messages.count()
			LV_Delete()
			loop %count%
			{
				curMessage:=g_IriBrivMaster.ChestSnatcher.Messages[count-A_Index+1]
				LV_Add(,curMessage.time,curMessage.action,curMessage.comment)
			}
			GuiControl, +Redraw, IBM_ChestsSnatcher_Status_Expanded
			Gui, IBM_Home:Default
		}
	}

	GameSettings_Update()
	{
		loop 2 ;Two profiles
		{
			profileIndex:=A_Index
			GuiControl, IBM_Home:Text, IBM_Game_Settings_Profile_%profileIndex%, % g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profileIndex].Name
			for setting,value in g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profileIndex]
			{
				GuiControl, IBM_Game_Settings_Options:, IBM_Game_Settings_Option_%setting%_%profileIndex%, %value%
			}
		}
	}

	GameSettings_Status(statusText,themeColour,changeString)
	{
		colour:=this.Theme.GetThemeTextColour(themeColour)
		GuiControl, IBM_Home: +%colour%, IBM_Game_Settings_Status
		GuiControl, IBM_Home:Text, IBM_Game_Settings_Status, %statusText%
		this.UpdateToolTip("IBM_Game_Settings_Status", changeString)
	}

	GetDPIScale()
	{
		hdc := DllCall("GetDC", "ptr", 0)
		dpi := DllCall("GetDeviceCaps", "ptr", hdc, "int", 88) ; LOGPIXELSY
		DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)
		return dpi / 96
	}

	ReadNonGemFarmEllySettings()
	{
		cardOptions:=[]
		loop, 5
		{
			GuiControlGet, value,, IBM_NonGemFarm_Elly_Min_%A_Index%
			cardOptions.Push(value+0)
			GuiControlGet, value,, IBM_NonGemFarm_Elly_Max_%A_Index%
			cardOptions.Push(value+0)
		}
		return cardOptions
	}

	UpdateNonGemFarmEllySettings(cardOptions)
	{
		index:=1
		loop, 5
		{
			GuiControl, IBM_Home:, IBM_NonGemFarm_Elly_Min_%A_Index%, % g_IBM_Settings.HUB.IBM_Ellywick_NonGemFarm_Cards[index]
			index++
			GuiControl, IBM_Home:, IBM_NonGemFarm_Elly_Max_%A_Index%, % g_IBM_Settings.HUB.IBM_Ellywick_NonGemFarm_Cards[index]
			index++
		}
	}
	
    AddToolTip(controlVariableName, tipMessage) ;Used to pre-add tooltips before the GUI is shown. Will not be displayed until ApplyTooltips() is called
    {
        if(g_MouseToolTips.ByName.HasKey(controlVariableName))
			g_MouseToolTips.ByName[controlVariableName].Tip:=tipMessage
		else 
		{
			newTip:={}
			newTip.Tip:=tipMessage
			g_MouseToolTips.ByName[controlVariableName]:=newTip
		}
    }

	UpdateToolTip(controlVariableName, tipMessage) ;Used to update a tooltip once the GUI has been shown. Will add if needed
	{
		if(g_MouseToolTips.ByName.HasKey(controlVariableName)) ;Was already set up, and should have had the control handle acquired by ApplyTooltips()
			g_MouseToolTips.ByName[controlVariableName].Tip:=tipMessage
		else 
		{
			GuiControlGet, hControl, Hwnd, %controlVariableName%
			if(hControl)
			{
				newTip:={}
				newTip.Tip:=tipMessage
				g_MouseToolTips.ByName[controlVariableName]:=newTip
				g_MouseToolTips.ByHandle[hControl]:=newTip
			}
		}
	}

	ApplyTooltips() ;Requires that all GUI controls with tooltips have been created, probably by a Gui Show
	{
		for controlName,tipObj in g_MouseToolTips.ByName
		{
			GuiControlGet, hControl, Hwnd, %controlName%
			if(hControl)
			{
				g_MouseToolTips.ByHandle[hControl]:=tipObj
			}
		}
	}

    AddTab(Tabname)
	{
        addedTabs:=Tabname . "|"
        GuiControl,IBM_Home:,ModronTabControl,% addedTabs
        g_TabList.=addedTabs
    }
	
	GetThemeColourEntries()
	{
		colourList:={} ;Create a temporary list of values so we only change the actual settings once we've confirmed all are valid
		for _,name in this.Theme.ThemeList
		{
			GuiControlGet, valueHex, ,IBM_Theme_Manager_%name%
			valueDec:="0x" . valueHex
			if valueDec is not integer
			{
				Msgbox 16,Theme Manager,Colours must be entered as a hexidecimal RGB value
				return ""
			}
			colourList[name]:=valueHex
		}
		return colourList
	}
	
	
	RefreshThemeManagerExamples()
	{
		for _,name in this.Theme.ThemeList
		{
			colour:=this.Theme.GetThemeTextColour(name)
			GuiControl, IBM_Theme_Manager: +%colour%,IBM_Theme_Manager_%name%_Example
		}
	}
	
	LoadStockTheme(themeName)
	{
		for name,value in this.Theme.Stock[themeName]
		{
			if(name=="DarkMode") ;Handle boolean value
				GuiControl, IBM_Theme_Manager:,IBM_Theme_Manager_DarkMode,%value%
			else
				GuiControl, IBM_Theme_Manager:,IBM_Theme_Manager_%name%,%value%
		}
		IBM_Theme_Manager_Refresh() ;TODO: Bit messy going out of the object here - should bring the update code in and just call it from the g-label
	}
}

;Generic g-label handlers

IBM_Generic_Setting_Int() ;Generic g-label for non-hub settings that should be forced to Int
{
	if (g_IriBrivMaster_GUI.controlLock)
		return
	GuiControlGet, value, , %A_GuiControl%
    g_IBM_Settings[A_GuiControl]:=value+0
}

IBM_Generic_Setting_String() ;Generic g-label for non-hub settings that should be forced to String
{
	if (g_IriBrivMaster_GUI.controlLock)
		return
	GuiControlGet, value, , %A_GuiControl%
    g_IBM_Settings[A_GuiControl]:=value . ""
}

IBM_Generic_Hub_Setting_Int() ;Hub version
{
	if (g_IriBrivMaster_GUI.controlLock)
		return
	GuiControlGet, value, , %A_GuiControl%
    g_IBM_Settings.HUB[A_GuiControl]:=value+0
}

/*
IBM_Generic_Hub_Setting_String() ;Hub version - not currently in use as all string entries have their own handlers
{
	if (g_IriBrivMaster_GUI.controlLock)
		return
	GuiControlGet, value, , %A_GuiControl%
    g_IBM_Settings.HUB[A_GuiControl]:=value . ""
}
*/

;Specific g-label handlers

IBM_Theme_Manager_Load_Light()
{
	g_IriBrivMaster_GUI.LoadStockTheme("Light")
}

IBM_Theme_Manager_Load_Dark()
{
	g_IriBrivMaster_GUI.LoadStockTheme("Dark")
}

IBM_Theme_Manager_Accept()
{
	tempList:=g_IriBrivMaster_GUI.GetThemeColourEntries() ;Create a temporary list of values so we only change the actual settings once we've confirmed all are valid
	if(!IsObject(tempList))
		return
	for name,valueHex in tempList
	{
		valueToSave:="0x" . valueHex
		valueToSave+=0 ;Force to int
		g_IBM_Settings["IBM_Theme_Current",name]:=valueToSave
	}
	GuiControlGet, darkModeSelection,, IBM_Theme_Manager_DarkMode
	g_IBM_Settings["IBM_Theme_Current","DarkMode"]:=darkModeSelection+0
	g_IriBrivMaster_GUI.RefreshThemeManagerExamples()
	Msgbox 64,Theme Manager,Theme accepted. To fully apply save settings and restart Briv Master home.
	Gui, IBM_Theme_Manager:Hide
}

IBM_Theme_Manager_Refresh() ;Refreshes the examples so the user can see the results of their changes
{
	tempList:=g_IriBrivMaster_GUI.GetThemeColourEntries() ;Create a temporary list of values so we only change the actual settings once we've confirmed all are valid
	if(!IsObject(tempList))
		return
	for name,valueHex in tempList
	{
		GuiControl, IBM_Theme_Manager: +c%valueHex%,IBM_Theme_Manager_%name%_Example
		GuiControl, IBM_Theme_Manager:MoveDraw,IBM_Theme_Manager_%name%_Example
	}
}

IBM_Theme_Manager_Open()
{
	if WinExist("ahk_id " . g_IriBrivMaster_GUI.IBM_Theme_Manager_Hwnd)
		Gui, IBM_Theme_Manager:Hide
	else
	{
		GuiControlGet, GameSettings, Hwnd, IBM_Group_Window_Settings
		WinGetPos, GameOptX, GameOptY,GameOptW,GameOptH, % "ahk_id " . GameSettings
		Gui, IBM_Theme_Manager:Show, Hide ;Creates the window so we can read the size
		DetectHiddenWindows, On
		WinGetPos, OptionsX,OptionsY,OptionsW,OptionsH, % "ahk_id " . g_IriBrivMaster_GUI.IBM_Theme_Manager_Hwnd
		DetectHiddenWindows, Off
		targetX:=GameOptX + (GameOptW - OptionsW)//2
		targetY:=GameOptY + GameOptH + 1
		Gui, IBM_Theme_Manager:Show, X%targetX% Y%targetY%
	}
}

IBM_LevelRow_Feats_Set()
{
	RegExMatch(A_GuiControl,"IBM_LevelRow_(\d{1,2})_Feats_Set",row)
	for _, seatMembers in g_IriBrivMaster_GUI.levelDataSet
	{
		for champID, champData in seatMembers
		{
			if(champData["ListIndex"]==row1)
			{
				g_IBM_Settings.IBM_LevelManager_Levels:=g_IriBrivMaster_GUI.GetLevelRowData() ;Makes sure new champions are in the data set before we attempt to make changes
				HERO_FEATS:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.FeatHandler.heroFeatSlots[champID].List
				size:=HERO_FEATS.size.Read()
				currentFeats:={}
				messageFeats:=""
				Loop, %size%
				{
					id:=HERO_FEATS[A_Index - 1].ID.Read()
					name:=HERO_FEATS[A_Index - 1].Name.Read()
					if(id) ;heroFeatSlots always has the 4 slots
					{
						currentFeats[id]:=name
						messageFeats.=name . " (" . id . ")`n"
					}
				}
				if (currentFeats.Count()>0)
				{
					message:="Selecting the following feats as required for " . champData["Name"] . ":`n" . messageFeats . message.="`nMake this selection exclusive?"
					Msgbox, 35, Feat Guard, %message% ;3 is Yes/No/Cancel, + 32 for Question icon
					IfMsgBox Yes
					{
						g_IBM_Settings.IBM_LevelManager_Levels[ChampID,"Feat_Exclusive"]:=true
					}
					IfMsgBox No
					{
						g_IBM_Settings.IBM_LevelManager_Levels[ChampID,"Feat_Exclusive"]:=false
					}
					IfMsgBox Cancel
					{
						return
					}
					g_IBM_Settings.IBM_LevelManager_Levels[ChampID,"Feat_List"]:=currentFeats
					g_IriBrivMaster_GUI.RefreshLevelRows()
					return
				}
				else
				{
					message:="No feats are currently equipped on " . champData["Name"] . "`nMake this selection exclusive?"
					g_IBM_Settings.IBM_LevelManager_Levels[ChampID,"Feat_List"]:=""
					Msgbox, 33, Feat Guard, %message% ;1 is OK/Cancel, + 32 for Question icon
					IfMsgBox OK
					{
						g_IBM_Settings.IBM_LevelManager_Levels[ChampID,"Feat_Exclusive"]:=true
						g_IriBrivMaster_GUI.RefreshLevelRows()
						return
					}
					g_IBM_Settings.IBM_LevelManager_Levels[ChampID,"Feat_Exclusive"]:=false
					g_IriBrivMaster_GUI.RefreshLevelRows()
					return
				}
			}
		}
	}
}

IBM_Server_Check()
{
	GuiControl, IBM_Home:Text, IBM_Server_Text_PS, % "Play Server: " . g_IriBrivMaster.GetPlayServerFriendly()
}

IBM_Version_Check_Now()
{
	GuiControl, IBM_Home:Disable, IBM_Version_Check_Now
	g_IriBrivMaster.RunVersionCheck()
	GuiControl, IBM_Home:Enable, IBM_Version_Check_Now
}

IBM_Offsets_Download()
{
	GuiControl, IBM_Home:Disable, IBM_Offsets_Download
	g_IriBrivMaster.DownloadOffsets()
	GuiControl, IBM_Home:Enable, IBM_Offsets_Download
}

IBM_Offsets_Check_Now()
{
	GuiControl, IBM_Home:Disable, IBM_Offsets_Check_Now
	g_IriBrivMaster.CheckOffsetVersions()
	GuiControl, IBM_Home:Enable, IBM_Offsets_Check_Now
}

IBM_LevelRow_Feats_Clear()
{
	RegExMatch(A_GuiControl,"IBM_LevelRow_(\d{1,2})_Feats_Clear",row)
	for _, seatMembers in g_IriBrivMaster_GUI.levelDataSet
	{
		for champID, champData in seatMembers
		{
			if(champData["ListIndex"]==row1)
			{
				g_IBM_Settings.IBM_LevelManager_Levels:=g_IriBrivMaster_GUI.GetLevelRowData() ;Makes sure new champions are in the data set before we attempt to make changes
				savedLevels:=g_IBM_Settings["IBM_LevelManager_Levels"]
				savedLevels[champID,"Feat_List"]:=""
				savedLevels[champID,"Feat_Exclusive"]:=false
			}
		}
	}
	g_IriBrivMaster_GUI.RefreshLevelRows()
}

IBM_MainButtons_Start()
{
    g_IriBrivMaster.Run_Clicked()
}

IBM_MainButtons_Stop()
{
    g_IriBrivMaster.Stop_Clicked()
}

IBM_MainButtons_Connect()
{
    g_IriBrivMaster.Connect_Clicked()
}

IBM_MainButtons_Reset()
{
	GuiControl, IBM_Home: Disable, IBM_MainButtons_Reset
	g_IriBrivMaster.ResetStats()
	g_IriBrivMaster.UpdateStatus() ;NOT UpdateStats(), as that assumes we've already checked the COM object is valid
	GuiControl, IBM_Home: Enable, IBM_MainButtons_Reset
}

IBM_MainButtons_Save()
{
	Gui, IBM_Home:Submit, NoHide
	GuiControl, IBM_Home: Disable, IBM_MainButtons_Save
	g_IBM_Settings.HUB.IBM_Ellywick_NonGemFarm_Cards:=g_IriBrivMaster_GUI.ReadNonGemFarmEllySettings()
	;Level Manager
	if (g_IriBrivMaster_GUI.levelDataSet.Length() > 0) ;Only save if we have some formations loaded (prevents overwritting dates with nothing because we didn't read these in whilst saving other things), and check if we've actually made changes
	{
		haveAdded:=false
		addedString:=""
		heroList:={} ;Used to check for removals later to avoid excessive loops around the seat->hero structure
		for _, seatMembers in g_IriBrivMaster_GUI.levelDataSet
		{
			for heroID, heroData in seatMembers
			{
				heroList[heroID]:=heroData.Name
				if(!g_IBM_Settings.IBM_LevelManager_Levels.hasKey(heroID))
				{
					haveAdded:=true
					addedString.=heroData.Name . " (" . heroID . ")`n"
				}
			}
		}
		haveRemoved:=false
		removedString:=""
		for heroID,heroData in g_IBM_Settings.IBM_LevelManager_Levels
		{
			if(!heroList.hasKey(heroID))
			{
				haveRemoved:=true
				heroName:=g_Heroes[heroID].ReadName() ;The name of the hero is not in current data, and might not be available at all
				removedString.=(heroName ? heroName : "Unable to retrieve champion name") . " (" . heroID . ")`n"
			}
		}
		if(haveAdded OR haveRemoved)
		{
			saveMsg:="The following champion changes have been made in the Level Manager:`n"
			if(haveAdded)
				saveMsg.="`nAdded:`n" . addedString . "`n"
			if(haveRemoved)
				saveMsg.="`nRemoved:`n" . removedString . "`n"
			saveMsg.="`nSave Level Manager changes?"
			Msgbox, 36, Briv Master Level Manager, %saveMsg% ;4 is Yes/No, + 32 for Question icon
			ifMsgBox Yes
				 g_IBM_Settings.IBM_LevelManager_Levels:=g_IriBrivMaster_GUI.GetLevelRowData()
		}
		else
			g_IBM_Settings.IBM_LevelManager_Levels:=g_IriBrivMaster_GUI.GetLevelRowData()
	}
	;Done with levels
	g_IriBrivMaster.SaveSettings()
	GuiControl, IBM_Home: Enable, IBM_MainButtons_Save
}

IBM_Game_Copy_From_Game() ;Copy game location settings from the running game. Note that using WinGet ProcessPath will return odd values for some mounted devices
{
	GuiControlGet, currentExe,, vIBM_Game_Exe
	useExe:="IdleDragons.exe" ;Standard .exe name
	hWnd:=WinExist("ahk_exe " . useExe)
	if(!hWnd)
	{
		useExe:=currentExe
		hWnd:=WinExist("ahk_exe " . useExe)
	}
	if(hWnd) ;A game window exists TODO: We need to make more effort to set up and check memory reads here
	{
		location:=IBM_Game_Copy_From_Game_Location_Helper(useExe) . "\" ;Trailing \ is removed
		if (g_SF.Memory.ReadPlatform()==21) ;21 is the EGS platform code
		{
			Msgbox 36, Briv Master, Use standard Epic Games Store Launcher?`nSelect No for Legendary or Rare ;32 is question, 4 is Yes/No
			IfMsgBox Yes
				launch:="explorer.exe ""com.epicgames.launcher://apps/7e508f543b05465abe3a935960eb70ac%3A48353a502e72433298f25827e03dbff0%3A40cb42e38c0b4a14a1bb133eb3291572?action=launch&silent=true"""
			IfMsgBox No
			{
				Msgbox 36, Briv Master, Select Yes for Legendary, No for Rare.`nYou must add the appropriate path before to the launcher executable manually ;32 is question, 4 is Yes/No
				IfMsgBox Yes
					launch:="legendary.exe launch 40cb42e38c0b4a14a1bb133eb3291572 --skip-version-check"
				IfMsgBox No
					launch:="rare.exe launch 40cb42e38c0b4a14a1bb133eb3291572"
			}
		}
		else
		{
			launch:=location . useExe
		}
		GuiControl, IBM_Home:, IBM_Game_Exe, % useExe
		GuiControl, IBM_Home:, IBM_Game_Path, % location
		GuiControl, IBM_Home:, IBM_Game_Launch, % launch
		IBM_Game_Location_Settings()
	}
	else
		Msgbox 16, Briv Master, Idle Champions not found. If you have changed the executable file name please enter it into the Executable field and try again ;16 is Stop/Error, +0 for just OK
}

IBM_Game_Copy_From_Game_Location_Helper(processName) ;TODO: Should this be in the GUI file?
{
	for gameProcess in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='" . processName . "'")  ;Notepad++ UDF langauge file can't copy with the quoted single quote for some reason
	{
		command:=gameProcess.CommandLine ;For sensible platforms, this will be C:\Games\IdleDragons.exe. EGS is not sensible, and so it will be "C:/Games/IdleDragons.exe" -STUFF". Those forward slashes are not typos...
		SplitPath command, outFile, outPath
		if (outFile!=processName)
		{
			exeLocation:=InStr(command,processName)
			cleanString:=SubStr(command,1,exeLocation + StrLen(processName)-1) ;-1 as InStr returns the location of the 1st character
			cleanString:=StrReplace(cleanString,"""") ;Remove quotes
			cleanString:=StrReplace(cleanString,"/","\") ;Fix slashes
			SplitPath cleanString,, outPath
		}
		return outPath
	}
}

IBM_Game_Location_Settings() ;TODO: Should be able to use the generic Int for this, and the g-label will trigger when IBM_Game_Copy_From_Game() makes changes?
{
	if (g_IriBrivMaster_GUI.controlLock)
		return
	GuiControlGet, value,, IBM_Game_Exe
	g_IriBrivMaster.UpdateSetting("IBM_Game_Exe",value)
	GuiControlGet, value,, IBM_Game_Path
	g_IriBrivMaster.UpdateSetting("IBM_Game_Path",value)
	GuiControlGet, value,, IBM_Game_Launch
	g_IriBrivMaster.UpdateSetting("IBM_Game_Launch",value)
	GuiControlGet, value,, IBM_Game_Hide_Launcher
	g_IriBrivMaster.UpdateSetting("IBM_Game_Hide_Launcher",value+0)
}

IBM_Game_Settings_Profile()
{
	GuiControlGet, value,, IBM_Game_Settings_Profile_1
	profile:=value ? 1 : 2
	g_IBM_Settings.HUB.IBM_Game_Settings_Option_Profile:=profile
	g_IriBrivMaster.GameSettingsCheck()
}

IBM_Game_Settings_Fix()
{
	GuiControlGet, value,, IBM_Game_Settings_Profile_1
	profile:=value ? 1 : 2
	g_IriBrivMaster.GameSettingsCheck(true)
}

IBM_Game_Settings_Options()
{
	if WinExist("ahk_id " . g_IriBrivMaster_GUI.IBM_Game_Settings_Opt_Hwnd)
	{
		Gui, IBM_Game_Settings_Options:Hide
	}
	else
	{
		GuiControlGet, GameSettings, Hwnd, IBM_Group_Game_Settings
		WinGetPos, GameOptX, GameOptY,GameOptW,GameOptH, % "ahk_id " . GameSettings
		Gui, IBM_Game_Settings_Options:Show, Hide ;Creates the window so we can read the size
		DetectHiddenWindows, On
		WinGetPos, OptionsX,OptionsY,OptionsW,OptionsH, % "ahk_id " . g_IriBrivMaster_GUI.IBM_Game_Settings_Opt_Hwnd
		DetectHiddenWindows, Off
		targetX:=GameOptX + (GameOptW - OptionsW)//2
		targetY:=GameOptY + GameOptH + 1
		Gui, IBM_Game_Settings_Options:Show, X%targetX% Y%targetY%
	}
}

IBM_Game_Settings_Option_Change() ;This just updates everything, since we shouldn't be screwing around in the game settings options screen constantly TODO: Should this refresh the profile names in the main window? Probably should...
{
	if (g_IriBrivMaster_GUI.controlLock)
		return
	loop 2 ;Two profiles
	{
		profileIndex:=A_Index
		for setting,_ in g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profileIndex]
		{
			GuiControlGet, value,, IBM_Game_Settings_Option_%setting%_%profileIndex%
			if value is integer ;Mixed types between the name (string) and values (int/bool)
				value:=value+0
			g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profileIndex,setting]:=value
		}
	}
}

IBM_ChestsSnatcher_Status_Resize()
{
	if WinExist("ahk_id " . g_IriBrivMaster_GUI.IBM_ChestSnatcher_Log_Hwnd)
	{
		Gui, IBM_ChestSnatcher_Log:Hide
	}
	else
	{
		g_IriBrivMaster_GUI.IBM_ChestsSnatcher_Status_Update(true) ;Update the list before showing it
		GuiControlGet, StatusList, Hwnd, IBM_ChestsSnatcher_Status
		WinGetPos, StatusListX, StatusListY,,StatusListH, % "ahk_id " . StatusList
		targetX:=StatusListX
		targetY:=StatusListY+StatusListH+1
		Gui, IBM_ChestSnatcher_Log:Show, X%targetX% Y%targetY%
	}
}

IBM_ChestsSnatcher_Options()
{
	if WinExist("ahk_id " . g_IriBrivMaster_GUI.IBM_ChestSnatcher_Opt_Hwnd)
	{
		Gui, IBM_ChestSnatcher_Options:Hide
	}
	else
	{
		g_IriBrivMaster_GUI.UpdateChestSnatcherOptions()
		GuiControlGet, StatusList, Hwnd, IBM_ChestsSnatcher_Status
		WinGetPos, StatusListX, StatusListY,StatusListW,StatusListH, % "ahk_id " . StatusList
		targetX:=StatusListX+StatusListW/2
		targetY:=StatusListY+StatusListH+1
		Gui, IBM_ChestSnatcher_Options:Show, X%targetX% Y%targetY%
	}
}

IBM_ChestSnatcher_Options_OK_Button() ;Applies all the the ChestSnatcher options
{
	GuiControlGet, value,, IBM_ChestSnatcher_Options_Min_Buy
	if (value>g_IriBrivMaster.CONSTANT_serverRateBuy) ;Can't buy more than 250 chests at a time
		value:=g_IriBrivMaster.CONSTANT_serverRateBuy
	g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Buy:=value
	GuiControlGet, value,, IBM_ChestSnatcher_Options_Open_Gold
	if (value>g_IriBrivMaster.CONSTANT_serverRateOpen) ;Can't open more than 1000 at a time
		value:=g_IriBrivMaster.CONSTANT_serverRateOpen
	g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Gold:=value
	GuiControlGet, value,, IBM_ChestSnatcher_Options_Open_Silver
	if (value>g_IriBrivMaster.CONSTANT_serverRateOpen) ;Can't open more than 1000 at a time
		value:=g_IriBrivMaster.CONSTANT_serverRateOpen
	g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Silver:=value
	GuiControlGet, value,, IBM_ChestSnatcher_Options_Min_Gem
	g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Gem:=value
	GuiControlGet, value,, IBM_ChestSnatcher_Options_Min_Gold
	g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Gold:=value
	GuiControlGet, value,, IBM_ChestSnatcher_Options_Min_Silver
	g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Silver:=value
	GuiControlGet, value,, IBM_ChestSnatcher_Options_Claim
	g_IBM_Settings.HUB.IBM_DailyRewardClaim_Enable:=value
	Gui, IBM_ChestSnatcher_Options:Hide
}

IBM_OffLine_Blank() ;Handle the cascade of enabled/disabled options for Blank->Relay
{
	if (g_IriBrivMaster_GUI.controlLock)
		return
	GuiControlGet, blankOn,, IBM_OffLine_Blank
	g_IriBrivMaster.UpdateSetting("IBM_OffLine_Blank",blankOn+0)
	GuiControlGet, relayOn,, IBM_OffLine_Blank_Relay
	g_IriBrivMaster.UpdateSetting("IBM_OffLine_Blank_Relay",relayOn+0)
	GuiControlGet, value,, IBM_OffLine_Blank_Relay_Zones
	g_IriBrivMaster.UpdateSetting("IBM_OffLine_Blank_Relay_Zones",value+0)
	IBM_Offline_Blank_EnableControls(blankOn,relayOn)
}

IBM_Offline_Blank_EnableControls(relay, relayZones)
{
	if (relay)
	{
		GuiControl, IBM_Home:Enable, IBM_OffLine_Blank_Relay
		GuiControl, IBM_Home:Enable, IBM_OffLine_Blank_Stop
	}
	else
	{
		GuiControl, IBM_Home:Disable, IBM_OffLine_Blank_Relay
		GuiControl, IBM_Home:Disable, IBM_OffLine_Blank_Stop
	}
	if (relay AND relayZones)
		GuiControl, IBM_Home:Enable, IBM_OffLine_Blank_Relay_Zones
	else
		GuiControl, IBM_Home:Disable, IBM_OffLine_Blank_Relay_Zones
}

IBM_OffLine_Freq_Edit()
{
	GuiControlGet, value,, IBM_OffLine_Freq_Edit
	if (value<1)
		value:=1
	g_IriBrivMaster.UpdateSetting("IBM_OffLine_Freq",value)
}

IBM_NonGemFarm_Elly_Start()
{
	g_IriBrivMaster.IBM_Elly_StartNonGemFarm()
}

IBM_NonGemFarm_Elly_Stop()
{
	g_IriBrivMaster.IBM_Elly_StopNonGemFarm()
}

IBM_LevelManager_Input_Max()
{
	GuiControlGet, value,, IBM_LevelManager_Input_Max
	if (value<2)
		value:=2 ;Due to potential use of modifier keys this must be at least 2
	g_IriBrivMaster.UpdateSetting("IBM_LevelManager_Input_Max",value)
}

IBM_Level_Options_BrivBoost_Use()
{
	GuiControlGet, value,, IBM_Level_Options_BrivBoost_Use
	IBM_Level_Options_BrivBoost_Enable(value)
	g_IriBrivMaster.UpdateSetting("IBM_LevelManager_Boost_Use",value)
}

IBM_Level_Options_BrivBoost_Enable(enableControl)
{
	if (enableControl)
	{
		GuiControl, IBM_Home:Enable, IBM_LevelManager_Boost_Multi
	}
	else
	{
		GuiControl, IBM_Home:Disable, IBM_LevelManager_Boost_Multi
	}
}

IBM_Route_Import_Button() ;TODO: Provide some instructions...
{
	InputBox routeString, Route Import,,,,100,,,,, ;InputBox, OutputVar , Title, Prompt, Hide, Width, Height, X, Y, Locale, Timeout, Default
	g_IriBrivMaster.ParseRouteImportString(routeString)
}

IBM_Route_Export_Button() ;TODO: Provide some instructions...
{
	InputBox _, Route Export,,,,100,,,,, % g_IriBrivMaster.GetRouteExportString() ;InputBox, OutputVar , Title, Prompt, Hide, Width, Height, X, Y, Locale, Timeout, Default
}

IBM_Route_J_Click()
{
	RegExMatch(A_GuiControl,"_(\d+)$",index)
	g_IriBrivMaster.UpdateRouteSetting("IBM_Route_Zones_Jump",index1) ;index1 is the first submatch...AHK is cursed
	g_IriBrivMaster_GUI.RefreshRouteJumpBoxes()
}

IBM_Route_S_Click()
{
	RegExMatch(A_GuiControl,"_(\d+)$",index)
	g_IriBrivMaster.UpdateRouteSetting("IBM_Route_Zones_Stack",index1) ;index1 is the first submatch...AHK is still cursed
	g_IriBrivMaster_GUI.RefreshRouteStackBoxes()
}

IBM_RunControl_Offline_Toggle()
{
	GuiControl, IBM_Home:Disable, IBM_RunControl_Offline_Pause
	g_IriBrivMaster.SetControl_OfflineStacking(true)
}

IBM_RunControl_Offline_Queue_Toggle()
{
	GuiControl, IBM_Home:Disable, IBM_RunControl_Offline_Queue
	g_IriBrivMaster.SetControl_QueueOffline(true)
}

IBM_LevelManager_Refresh() ;UI refresh button
{
	g_IriBrivMaster_GUI.RefreshLevelRows()
}

class IBM_Theme
{
    __new(themeSettings:="")
	{
		this.defaultFontSize:=8
		if(themeSettings)
			this.Theme:=themeSettings
		else
			this.Theme:=g_IBM_Settings["IBM_Theme_Current"] ;TODO: Create colour strings for these up front? E.g. turn 255 into c0000FF? Need to consider backgrounds, although those are only needed once per window anyway
		this.ThemeList:=["DefaultText","WarningText","SpecialText1","SpecialText2","EditText","TrafficLightBad","TrafficLightNeutral","TrafficLightGood","TableText","TableBackground","WindowBackground"]
		this.Stock:={}
		this.Stock["Light"]:={"DefaultText":"000000","WarningText":"F18500","SpecialText1":"0000FF","SpecialText2":"008000","TableText":"000000","EditText":"000000","TableBackground":"FFFFFF","WindowBackground":"F0F0F0","TrafficLightBad":"F00000","TrafficLightGood":"00F000","TrafficLightNeutral":"FFC000","DarkMode":false}
		this.Stock["Dark"]:={"DefaultText":"C0C0C0","WarningText":"F18500","SpecialText1":"8888FF","SpecialText2":"88FF88","TableText":"E0E0E0","EditText":"333333","TableBackground":"555555","WindowBackground":"333333","TrafficLightBad":"F00000","TrafficLightGood":"00F000","TrafficLightNeutral":"FFC000","DarkMode":true}
	}
	
    UseThemeTextColour(guiName, textType:="DefaultText", weight:=400) ;Sets the colour/weight for subsequent text based on the theme
    {
        textColor:=Format("{:#x}", this.Theme[textType])
        Gui, %guiName%:Font, % "c" . textColor . " w" . weight . " s" . this.defaultFontSize
    }
	
	GetThemeTextColour(textType:="DefaultText") ;Returns the colour value, including the 'c' prefix, for a theme colour. Needed when changing text colour dynamically
    {
        return "c" . Format("{:#x}", this.Theme[textType])
    }

	GetThemeBackgroundColour()
    {
        return Format("{:#x}", this.Theme["WindowBackground"]) ;No 'c' prefix here
    }

	GetThemeListViewBackgroundColour()
    {
		return Format("{:#x}", this.Theme["TableBackground"]) ;No 'c' prefix here
    }

    UseThemeTitleBar(guiName) ;Sets the window title bar to dark if theme is a dark theme. GUI must be shown before calling.
    {
        if(this.Theme.DarkMode)
        {
            if (A_OSVersion>="10.0.17763" AND SubStr(A_OSVersion, 1, 3)="10.")
            {
                attr:=19
                if (A_OSVersion>="10.0.18985")
                    attr:=20
                Gui, %guiName%: +hwndGuiID
                DllCall("dwmapi\DwmSetWindowAttribute", "ptr", GuiID, "int", attr, "int*", true, "int", 4)             
            }
        }
    }
	
	GetThemeHexString(colourName:="DefaultText") ;Returns the actual hex, without a c prefix or 0x prefix, e.g. pure red would give "FF0000"
	{
		return Format("{:06X}", this.Theme[colourName]) ;Uppercase X so we get uppercase letters
	}
}