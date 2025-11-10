#include %A_LineFile%\..\IC_BrivMaster_Functions.ahk
#include %A_LineFile%\..\IC_BrivMaster_Overrides.ahk
#include %A_LineFile%\..\IC_BrivMaster_GUI.ahk
#include %A_LineFile%\..\IC_BrivMaster_Memory.ahk
;#include %A_LineFile%\..\IC_BrivMaster_SharedFunctions.ahk

SH_UpdateClass.AddClassFunctions(GameObjectStructure, IC_BrivMaster_GameObjectStructure_Add) ;Required so that the Ellywick tool can work in the same way as the main script. TODO: Might not be needed if Aug25 SH update is applied and has built-in methods for this
SH_UpdateClass.AddClassFunctions(g_SF.Memory, IC_BrivMaster_MemoryFunctions_Class) ;Make memory overrides available as well TODO: This doesn't actually work?

; Naming convention in Script Hub is that simple global variables should start with ``g_`` to make it easy to know that a global variable is what is being used.
global g_IriBrivMaster := new IC_IriBrivMaster_Component
global g_IriBrivMaster_GUI := new IC_IriBrivMaster_GUI
global g_IBM_Settings:={}

global g_IriBrivMaster_ModLoc := A_LineFile . "\..\IC_BrivMaster_Mods.ahk"
global g_IriBrivMaster_StartFunctions := {}
global g_IriBrivMaster_StopFunctions := {}

g_IriBrivMaster.Init()
g_IriBrivMaster.ResetModFile()

ClearButtonStatusMessage()
{
    g_IriBrivMaster.LEGACY_UpdateStatus("")
}

Gui, ICScriptHub:Submit, NoHide

Class IC_IriBrivMaster_Component
{
	Settings := ""
	TimerFunction := ObjBindMethod(this, "UpdateStatus")
	;ChestSnatcherTimer := ObjBindMethod(this, "ChestSnatcher")
	SharedRunData:=""
	CONSTANT_serverRateOpen:=1000 ;For chests TODO: Make a table of this stuff?
	CONSTANT_serverRateBuy:=250
	ServerCallFailCount:=0 ;Track the number of failed calls, so we can refresh the user data / servercall, but avoid doing so because one call happened to fail (e.g. at 20:00 UK the new game day starting tends to result in fails)
	MemoryReadFailCount:=0 ;Separate tracker for memory reads, as these are expected to fail during resets etc (TODO: We could combine and just add different numbers, e.g. 5 for a call fail or 1 for a memory read fail?)
	CONSTANT_goldCost:=500
	CONSTANT_silverCost:=50

	;START STUFF COPIED FROM IC_BrivGemFarm_Component.ahk

	Run_Clicked()
    {
        try
        {
            this.Connect_Clicked()
            SharedData := ComObjActive(this.GemFarmGUID)
            SharedData.ShowGui()
        }
        catch
        {
            g_SF.Hwnd := WinExist("ahk_exe " . g_IBM_Settings["ExeName"])
            g_SF.Memory.OpenProcessReader()
            scriptLocation := A_LineFile . "\..\IC_BrivMaster_Run.ahk"
            GuiControl, ICScriptHub:Choose, ModronTabControl, Stats
            for k,v in g_IriBrivMaster_StartFunctions
            {
                v.Call()
            }
            GuidCreate := ComObjCreate("Scriptlet.TypeLib")
            this.GemFarmGUID := guid := GuidCreate.Guid
            Run, %A_AhkPath% "%scriptLocation%" "%guid%"
        }
        this.TestGameVersion()
    }

    UpdateGUIDFromLast()
    {
        this.GemFarmGUID := g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_IBM_GemFarm.json")
    }

    TestGameVersion()
    {
        gameVersion := g_SF.Memory.ReadGameVersion()
        importsVersion := _MemoryManager.is64bit ? g_ImportsGameVersion64 . g_ImportsGameVersionPostFix64 : g_ImportsGameVersion32 . g_ImportsGameVersionPostFix32
        GuiControl, ICScriptHub: +cF18500, IBM_Import_Warning,
        if (gameVersion == "")
            GuiControl, ICScriptHub:, IBM_Import_Warning, % "⚠ Warning: Memory Read Failure. Check for updated Imports."
        else if( gameVersion > 100 AND gameVersion <= 999 AND gameVersion != importsVersion )
            GuiControl, ICScriptHub:, IBM_Import_Warning, % "⚠ Warning: Game version (" . gameVersion . ") does not match Imports version (" . importsVersion . ")."
        else
            GuiControl, ICScriptHub:, IBM_Import_Warning, % ""
    }

    Stop_Clicked()
    {
        for k,v in g_IriBrivMaster_StopFunctions
        {
            this.LEGACY_UpdateStatus("Stopping Addon Function: " . v)
            v.Call()
        }
        this.LEGACY_UpdateStatus("Closing Gem Farm")
        try
        {
            SharedRunData := ComObjActive(this.GemFarmGUID)
            SharedRunData.Close()
        }
        catch, err
        {
            ; When the Close() function is called "0x800706BE - The remote procedure call failed." is thrown even though the function successfully executes.
            if(err.Message != "0x800706BE - The remote procedure call failed.")
                this.LEGACY_UpdateStatus("Gem Farm not running")
            else
                this.LEGACY_UpdateStatus("Gem Farm Stopped")
        }
    }

    Connect_Clicked()
    {
        this.LEGACY_UpdateStatus("Connecting to Gem Farm...")
        this.UpdateGUIDFromLast()
        Try
        {
            ComObjActive(this.GemFarmGUID)
        }
        Catch
        {
            this.LEGACY_UpdateStatus("Gem Farm not running")
            return
        }
        g_SF.Hwnd := WinExist("ahk_exe " . g_IBM_Settings[ "ExeName"])
        g_SF.Memory.OpenProcessReader()
        for k,v in g_IriBrivMaster_StartFunctions
        {
            v.Call()
        }
    }

    ResetModFile()
    {
        IfExist, %g_IriBrivMaster_ModLoc%
            FileDelete, %g_IriBrivMaster_ModLoc%
        FileAppend, `;This file is automatically generated by the Briv Master addon`n, %g_IriBrivMaster_ModLoc%
    }

    LEGACY_UpdateStatus(msg)
    {
        GuiControl, ICScriptHub:, IBM_MainButtons_Status, % msg
        if (msg=="")
			return
		SetTimer, ClearButtonStatusMessage,-3000
    }

	;END STUFF COPIED FROM IC_BrivGemFarm_Component.ahk

	Init()
    {
        ; Read settings
		g_SF.Memory.GetChampIDToIndexMap() ;This is normally in the effect key handler, which is unhelpful for us, so having to call manually. TODO: Put somewhere sensible

		this.GemFarmGUID:=g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_IBM_GemFarm.json") ;TODO: Should be IC_IriBrivMaster_Component property? Probably best placed in .Init() - done, still needs further thought?

		g_IriBrivMaster_GUI.Init()
        this.LoadSettings()
		g_IBM_Settings:=this.settings ;TODO: This is a hack to make the settings available via the hub, needed due to the override of g_SF.Memory.OpenProcessReader()
		this.ResetStats() ;Before we initiate the timers
		g_IriBrivMaster_StartFunctions.Push(ObjBindMethod(this, "Start"))
        g_IriBrivMaster_StopFunctions.Push(ObjBindMethod(this, "Stop"))
		this.NextDailyClaimCheck:=A_TickCount + 300000 ;Wait 5min before making the first check, to avoid spamming calls whilst testing things
		this.ServerCallFailCount:=0
		this.MemoryReadFailCount:=0
		this.ChestSnatcher_Messages:={}
		this.GameSettingFileLocation:=""
		this.NextGameSettingsCheck:=A_TickCount + 60000 ;Wait 1min, as we'll likely be starting the script right away which will check for us
		this.CurrentGems:=0 ;Gem/Chest data used over multiple elements of this class
		this.Chests:={}
		this.Chests.CurrentSilver:=0
		this.Chests.CurrentGold:=0
		this.Chests.OpenedSilver:=0
		this.Chests.OpenedGold:=0
		this.Chests.OpenedSilver:=0
		this.Chests.OpenedGold:=0
    }

	; Returns an object with default values for all settings.
    GetNewSettings()
    {
        settings := {}
        settings.IBM_Chest_UseSmart := true
        settings.IBM_Chests_TimePercent := 90
        settings.IBM_Offline_Stack_Zone:=500
		settings.IBM_Offline_Stack_Min:=300
		settings.IBM_OffLine_Flames_Use := false
        settings.IBM_OffLine_Flames_Zones := [500,500,500,500,500]
		settings.IBM_Route_Combine := 0
		settings.IBM_Route_Combine_Boss_Avoidance := 1
		settings.IBM_DailyRewardClaim_Enable := false
        settings.IBM_LevelManager_Levels[0,58,"z1"]:=200
        settings.IBM_LevelManager_Levels[0,58,"min"]:=200
        settings.IBM_LevelManager_Levels[1,58,"z1"]:=200
        settings.IBM_LevelManager_Levels[1,58,"min"]:=200
		settings.IBM_Route_Zones_Jump:=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		settings.IBM_Route_Zones_Stack:=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		settings.IBM_Online_Use_Melf:=false
		settings.IBM_Online_Melf_Min:=349
		settings.IBM_Online_Melf_Max:=800
		settings.IBM_Online_Ultra_Enabled:=false
		settings.IBM_LevelManager_Defaults_Min:=false ;False is the lower option
		settings.IBM_LevelManager_Input_Max:=5
		settings.IBM_LevelManager_Boost_Use:=false
		settings.IBM_LevelManager_Boost_Multi:=8
		settings.IBM_Route_BrivJump_Q:=4
		settings.IBM_Route_BrivJump_E:=0
		settings.IBM_Route_BrivJump_M:=4
		settings.IBM_Casino_Target_Melf:=3
		settings.IBM_Casino_Redraws_Melf:=1
		settings.IBM_Casino_MinCards_Melf:=0
		settings.IBM_Casino_Target_Base:=3
		settings.IBM_Casino_Redraws_Base:=1
		settings.IBM_Casino_MinCards_Base:=0
		settings.IBM_Casino_Target_InFlight:=1
		settings.IBM_OffLine_Delay_Time:=15000
		settings.IBM_OffLine_Sleep_Time:=0
		settings.IBM_Level_Options_Mod_Key:="Shift"
		settings.IBM_Level_Options_Mod_Value:=10
		settings.IBM_Route_Offline_Restore_Window:=true
		settings.IBM_OffLine_Freq:=1
		settings.IBM_OffLine_Blank:=0
		settings.IBM_OffLine_Blank_Relay:=0
		settings.IBM_OffLine_Blank_Relay_Zones:=400
		settings.IBM_Level_Options_Limit_Tatyana:=false
		settings.IBM_Level_Options_Suppress_Front:=true
		settings.IBM_Level_Options_Ghost:=true
		settings.IBM_ChestSnatcher_Options_Min_Gem:=500000
		settings.IBM_ChestSnatcher_Options_Min_Gold:=500
		settings.IBM_ChestSnatcher_Options_Min_Silver:=500
		settings.IBM_ChestSnatcher_Options_Min_Buy:=250
		settings.IBM_ChestSnatcher_Options_Open_Gold:=0 ;TODO: These were set to 0 to prevent accidents when changing from using the main script settings, in the future update to more practical defauls
		settings.IBM_ChestSnatcher_Options_Open_Silver:=0
		settings.IBM_Game_Settings_Option_Profile:=1
		settings.IBM_Game_Settings_Option_Set:={1:{Name:"Profile 1",Framerate:600,Particles:0,HRes:1920,VRes:1080,Fullscreen:false,CapFPSinBG:false,SaveFeats:false,ConsolePortraits:false,NarrowHero:true,AllHero:true,Swap25100:false},2:{Name:"Profile 2",Framerate:600,Particles:0,HRes:1920,VRes:1080,Fullscreen:false,CapFPSinBG:false,SaveFeats:false,ConsolePortraits:false,NarrowHero:true,AllHero:true,Swap25100:false}}
		settings.IBM_Game_Exe:="IdleDragons.exe"
		settings.IBM_Game_Path:="" ;Path and Launch command are user dependant so can't have a default
		settings.IBM_Game_Launch:=""
		settings.IBM_Game_Hide_Launcher:=false
		settings.IBM_OffLine_Timeout:=5
		settings.IBM_Window_X:=0
		settings.IBM_Window_Y:=900 ;To keep the window on-screen at 1080
		settings.IBM_Window_Hide:=false
		settings.IBM_Level_Diana_Cheese:=false
		settings.IBM_Window_Dark_Icon:=false
        return settings
    }

	SaveSettings()
    {
        settings := this.Settings
        g_SF.WriteObjectToJSON(IC_BrivMaster_SharedData_Class.SettingsPath, settings)
        ; Apply settings to BrivGemFarm
		if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
		{
			this.SharedRunData.IBM_UpdateSettingsFromFile()
		}
		g_IBM_Settings:=this.settings ;TODO: This is a hack to make the g_BrivUserSettingsFromAddons values available via the hub, needed due to the override of g_SF.Memory.OpenProcessReader()
		this.LEGACY_UpdateStatus("Settings saved")
    }

	RefreshComObject()
	{
		try ; avoid thrown errors when comobject is not available.
		{
			this.SharedRunData := ComObjActive(this.GemFarmGUID)
		}
		catch
		{
			this.SharedRunData:=""
			return false
		}
		return true
	}

	Start()
    {
        g_SF.ResetServerCall() ;The process reader should have been set up by the main the script, but it doesn't instantiate the g_ServerCall object
		fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, 600, 0
		this.SharedRunData:="" ;Reset this on start
		if (this.RefreshComObject())
        {
			this.SharedRunData.IBM_BuyChests:=0 ;Cancel any orders open as the hub starts
        }
		this.ChestSnatcher_AddMessage("General","Awaiting first order")
		this.SoftResetStats() ;Soft reset so we don't discard totals etc but also don't pick up a part run
		this.UpdateStatus()
		this.GameSettingsCheck()
    }

    Stop()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, Off
		g_IriBrivMaster_GUI.ResetStatusText()
    }

	SoftResetStats()
	{
		this.Stats.StartUpStage:=0
		this.Stats.LastRun:=-1

		this.Stats.StacksSB:=""
		this.Stats.StacksHaste:=""

		this.Stats.PreviousRunEndTime:=""
		this.Stats.PreviousZoneStartTime:=""
		this.Stats.LastZone:=""
	}

	ResetStats()
	{
		this.Stats:={}

		this.SoftResetStats()

		this.Stats.Total:={}
		this.Stats.Total.Fast:=""
		this.Stats.Total.Slow:=""
		this.Stats.Total.TotalTime:=0
		this.Stats.Active:={}
		this.Stats.Active.Fast:=""
		this.Stats.Active.Slow:=""
		this.Stats.Active.TotalTime:=0
		this.Stats.Reset:={}
		this.Stats.Reset.Fast:=""
		this.Stats.Reset.Slow:=""
		this.Stats.Reset.TotalTime:=0

		this.Stats.FailTotalTime:=0 ;We could add the rest to this?

		this.Stats.TotalRuns:=0
		this.Stats.FailRuns:=0
		this.Stats.BossKills:=0
		this.Stats.StartTime:=""

		this.Stats.Chests:={}
		this.Stats.Chests.SilverStart:=""
		this.Stats.Chests.GoldStart:=""
		this.Stats.StartGems:=""

		this.Stats.GHActive:=-1 ;-1=not set, 0=Seen only inactive, 1=Seen only active, 2=Seen both

		if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
		{
			this.SharedRunData.IBM_ResetRunStats()
		}

		GuiControl, ICScriptHub:, IBM_Stats_Group, % "Run Stats"
		GuiControl, -Redraw, IBM_Stats_Run_LV
		Gui, ICScriptHub:Default
		Gui, ListView, IBM_Stats_Run_LV
		LV_Modify(1,,"Total","--.--","--.--","--.--","--.--")
		LV_Modify(2,,"Active","--.--","--.--","--.--","--.--")
		LV_Modify(3,,"Reset","--.--","--.--","--.--","--.--")
		LV_ModifyCol(1,"AutoHdr")
		LV_ModifyCol(2,"AutoHdr")
		LV_ModifyCol(3,"AutoHdr")
		LV_ModifyCol(4,"AutoHdr")
		LV_ModifyCol(5,"AutoHdr")
		GuiControl, +Redraw, IBM_Stats_Run_LV
		GuiControl, ICScriptHub:, IBM_Stats_Total_Runs, 0
		GuiControl, ICScriptHub:, IBM_Stats_Total_Time, 0s (0h)
		GuiControl, ICScriptHub:, IBM_Stats_Fail_Runs, 0
		GuiControl, ICScriptHub:, IBM_Stats_Fail_Time, 0s
		GuiControl, ICScriptHub:, IBM_Stats_Chests, Gold: - / - / - Silver: - / - / -

		GuiControl, ICScriptHub:, IBM_Stats_BPH, BPH: --.--
		GuiControl, ICScriptHub:, IBM_Stats_GPH, GPH: --.--
		GuiControl, ICScriptHub:, IBM_Stats_TotalGems, 0
		GuiControl, ICScriptHub:, IBM_Stats_GPB, -.-
		GuiControl, ICScriptHub:, IBM_Stats_Gem_Bonus, -.-`%
		GuiControl, ICScriptHub:, IBM_Stats_BSC_Reward, --.-- (Bosses: --.--, Gems: --.--)
		GuiControl, ICScriptHub:, IBM_Stats_Total_Reward, --.-- (Bosses: --.--, Gems: --.--)
		GuiControl, ICScriptHub:+cBlack, IBM_Stats_Gem_Hunter
		GuiControl, ICScriptHub:MoveDraw,IBM_Stats_Gem_Hunter ;Required to update the colour as we don't change the text

		GuiControl, ICScriptHub:, IBM_Stats_Current_Area_Run_Time, - / -
		GuiControl, ICScriptHub:, IBM_Stats_Loop, -
		GuiControl, ICScriptHub:, IBM_Stats_Current_Briv, - / -
		GuiControl, ICScriptHub:, IBM_Stats_Last_Close, -
		GuiControl, ICScriptHub:, IBM_Stats_Boss_Hits, - / -
        GuiControl, ICScriptHub:, IBM_Stats_Rollbacks, 0
        GuiControl, ICScriptHub:, IBM_Stats_Bad_Auto, 0
	}

	UpdateStats(dirty)
	{
		static CONSTANT_baseGPB:=9.02 ;TODO: Read blessings so this correctly reflects those? Seems a bit of a waste of CPU cycles admittedly...just do it at startup? Would then have to deal with the memory read not being available at that point
		static CONSTANT_silversPerBoss:=0.05361
		static CONSTANT_goldPerBoss:=0.00423
		static CONSTANT_BSCPerSilver:=0.10356
		static CONSTANT_BSCPerGold:=1.00522
		static CONSTANT_BountiesPerGold:=167.81838
		static CONSTANT_BountiesPerEventPack:=7500
		static CONSTANT_TotalRewardPerEventPack:=18.63041867

		;Run stats
		if (dirty AND this.SharedRunData.RunLogResetNumber!=-1) ;-1 means unset by main script, or in the process of updating
		{
			if (this.SharedRunData.RunLogResetNumber!=this.Stats.LastRun)
			{
				if (this.Stats.StartUpStage==0) ;At startup we need to detect a run, then the run changing to the next, which will be the 1st full run of the script, and read gems/chests/etc at that point, but not report until that 1st full run completes; i.e. RunLogResetNumber changes to the 2nd full run
				{
					this.Stats.LastRun:=this.SharedRunData.RunLogResetNumber
					this.Stats.StartUpStage:=1
					GuiControl, ICScriptHub:, IBM_Stats_Group, % "Run Stats (Waiting for first full run to start)"
					LogData:=AHK_JSON.Load(this.SharedRunData.RunLog)
					this.Stats.PreviousRunEndTime:=LogData.Run.End ;Include this so it is available for run timing
				}
				else if (this.Stats.StartUpStage==1) ;The run number has changed to a 2nd real number - this is the start of 1st run we are timing
				{
					this.Stats.LastRun:=this.SharedRunData.RunLogResetNumber
					this.Stats.StartUpStage:=2
					GuiControl, ICScriptHub:, IBM_Stats_Group, % "Run Stats (Waiting for first full run to complete)"
					silvers:=g_SF.Memory.ReadChestCountByID(1)
					if(silvers!="")
					{
						this.Chests.CurrentSilver:=silvers
						this.Stats.Chests.SilverStart:=silvers
					}
					golds:=g_SF.Memory.ReadChestCountByID(2)
					if(golds!="")
					{
						this.Chests.CurrentGold:=golds
						this.Stats.Chests.GoldStart:=golds
					}
					this.Chests.PurchasedSilver:=0	;Reset here as this is the point we are measuring from
					this.Chests.OpenedSilver:=0
					this.Chests.PurchasedGold:=0
					this.Chests.OpenedGold:=0
					gems:=g_SF.Memory.ReadGems()
					if(gems!="")
					{
						this.CurrentGems:=gems
						this.Stats.StartGems:=gems
					}
					LogData:=AHK_JSON.Load(this.SharedRunData.RunLog)
					this.Stats.PreviousRunEndTime:=LogData.Run.End ;Include this so it is available for run timing
				}
				else
				{
					LogData:=AHK_JSON.Load(this.SharedRunData.RunLog)
					this.Stats.LastRun:=LogData.Run.ResetNumber

					totalDuration:=LogData.Run.End - LogData.Run.Start
					activeTime:=LogData.Run.ResetReached - LogData.Run.Start
					resetTime:=LogData.Run.End - LogData.Run.ResetReached
					this.StatsUpdateFastSlow(this.Stats.Total,totalDuration)
					if LogData.Run.HasKey("ResetReached") ;Failed runs may not have a reset value
					{
						this.StatsUpdateFastSlow(this.Stats.Active,activeTime)
						this.StatsUpdateFastSlow(this.Stats.Reset,resetTime)
					}
					this.Stats.TotalRuns++
					this.Stats.PreviousRunEndTime:=LogData.Run.End
					Gui, ICScriptHub:Default
					Gui, ListView, IBM_Stats_Run_LV
					GuiControl, -Redraw, IBM_Stats_Run_LV
					LV_Modify(1,,"Total",ROUND(totalDuration/1000,2),ROUND((this.Stats.Total.TotalTime/this.Stats.TotalRuns)/1000,2),ROUND(this.Stats.Total.Fast/1000,2),ROUND(this.Stats.Total.Slow/1000,2))
					LV_Modify(2,,"Active",ROUND(activeTime/1000,2),ROUND((this.Stats.Active.TotalTime/this.Stats.TotalRuns)/1000,2),ROUND(this.Stats.Active.Fast/1000,2),ROUND(this.Stats.Active.Slow/1000,2))
					LV_Modify(3,,"Reset",ROUND(resetTime/1000,2),ROUND((this.Stats.Reset.TotalTime/this.Stats.TotalRuns)/1000,2),ROUND(this.Stats.Reset.Fast/1000,2),ROUND(this.Stats.Reset.Slow/1000,2))
					LV_ModifyCol(2,"AutoHdr")
					LV_ModifyCol(3,"AutoHdr")
					LV_ModifyCol(4,"AutoHdr")
					LV_ModifyCol(5,"AutoHdr")
					GuiControl, +Redraw, IBM_Stats_Run_LV
					if (LogData.Run.Fail) ;Failed runs (i.e. ones that did not reach the reset zone)
					{
						this.Stats.FailRuns++
						this.Stats.FailTotalTime+=totalDuration
					}
					if (this.Stats.StartTime=="") ;First run
					{
						this.Stats.StartTime:=LogData.Run.Start
					}
					totalTime:=LogData.Run.End - this.Stats.StartTime
					GuiControl, ICScriptHub:, IBM_Stats_Total_Runs, % this.Stats.TotalRuns
					GuiControl, ICScriptHub:, IBM_Stats_Total_Time, % ROUND(totalTime/1000,2) . "s (" . ROUND(totalTime/3600000,2) . "h)"
					GuiControl, ICScriptHub:, IBM_Stats_Fail_Runs, % this.Stats.FailRuns
					GuiControl, ICScriptHub:, IBM_Stats_Fail_Time, % ROUND(this.Stats.FailTotalTime/1000,2) . "s"

					silvers:=g_SF.Memory.ReadChestCountByID(1)
					if(silvers!="")
					{
						this.Chests.CurrentSilver:=silvers
					}
					golds:=g_SF.Memory.ReadChestCountByID(2)
					if(golds!="")
					{
						this.Chests.CurrentGold:=golds
					}
					silverString:=this.Chests.CurrentSilver - this.Stats.Chests.SilverStart + this.Chests.OpenedSilver - this.Chests.PurchasedSilver . " / " . this.Chests.PurchasedSilver . " / " . this.Chests.OpenedSilver ; Start + Purchased + Dropped - Opened
					goldString:=this.Chests.CurrentGold - this.Stats.Chests.GoldStart + this.Chests.OpenedGold - this.Chests.PurchasedGold . " / " . this.Chests.PurchasedGold . " / " . this.Chests.OpenedGold
					GuiControl, ICScriptHub:, IBM_Stats_Chests, % "Silver: " . silverString . " Gold: " . goldString

					this.Stats.BossKills+=FLOOR(LogData.Run.LastZone / 5)
					bph:=(this.Stats.BossKills / totalTime) * 3600000
					GuiControl, ICScriptHub:, IBM_Stats_BPH, % "BPH: " . ROUND(bph,2) ;Includes the prefix so it can be properly centered
					gems:=g_SF.Memory.ReadGems()
					if(gems!="")
					{
						this.CurrentGems:=gems
					}
					gemsTotal:=this.CurrentGems - this.Stats.StartGems + this.Chests.PurchasedGold*this.CONSTANT_goldCost + this.Chests.PurchasedSilver*this.CONSTANT_silverCost
					gph:=(gemsTotal / totalTime) * 3600000
					GuiControl, ICScriptHub:, IBM_Stats_GPH, % "GPH: " . ROUND(gph,2) ;Includes the prefix so it can be properly centered
					GuiControl, ICScriptHub:, IBM_Stats_TotalGems, % gemsTotal
					;Track GH status
					if (this.Stats.GHActive!=2) ;If already set to 2 the current value no longer matters; we've seen both states
					{
						if (LogData.Run.GHActive)
						{
							if (this.Stats.GHActive==-1) ;Not set yet - set to active
								this.Stats.GHActive:=1
							else if (this.Stats.GHActive==0) ;Been seen inactive - mark as both states
								this.Stats.GHActive:=2
						}
						else
						{
							if (this.Stats.GHActive==-1) ;Not set yet - set to inactive
								this.Stats.GHActive:=0
							else if (this.Stats.GHActive==1) ;Been seen active - mark as both states
								this.Stats.GHActive:=2
						}
					}
					gemMulti:=this.Stats.GHActive>0 ? 1.5 : 1 ;Mixed is processed as active TODO: Is it worth dealing with it dropping off? Doesn't seem like something we need to track
					rawGPB:=gph/bph
					GuiControl, ICScriptHub:, IBM_Stats_GPB, % ROUND(rawGPB/gemMulti,1)
					gemBonus:=(rawGPB/CONSTANT_baseGPB)/gemMulti
					GuiControl, ICScriptHub:, IBM_Stats_Gem_Bonus, % ROUND((gemBonus-1)*100,1) . "%" ;Best expressed as a percentage
					silverChestIncome:=bph*CONSTANT_silversPerBoss
					goldChestIncomeDrops:=bph*CONSTANT_goldPerBoss
					goldChestIncomeGems:=gph/this.CONSTANT_goldCost
					BSCIncomeDrops:=silverChestIncome*CONSTANT_BSCPerSilver + goldChestIncomeDrops * CONSTANT_BSCPerGold
					BSCIncomeGems:=goldChestIncomeGems * CONSTANT_BSCPerGold
					BountyIncomeDrops:=((goldChestIncomeDrops * CONSTANT_BountiesPerGold)/CONSTANT_BountiesPerEventPack)*CONSTANT_TotalRewardPerEventPack
					BountyIncomeGems:=((goldChestIncomeGems * CONSTANT_BountiesPerGold)/CONSTANT_BountiesPerEventPack)*CONSTANT_TotalRewardPerEventPack
					GuiControl, ICScriptHub:, IBM_Stats_BSC_Reward, % ROUND(BSCIncomeDrops+BSCIncomeGems,1) . " (Bosses: " . ROUND(BSCIncomeDrops,1) . ", Gems: " . Round(BSCIncomeGems,1) . ")"
					GuiControl, ICScriptHub:, IBM_Stats_Total_Reward, % ROUND(BSCIncomeDrops+BSCIncomeGems+BountyIncomeDrops+BountyIncomeGems,1) . " (Bosses: " . ROUND(BSCIncomeDrops+BountyIncomeDrops,1) . ", Gems: " . Round(BSCIncomeGems+BountyIncomeGems,1) . ")"
					if (this.Stats.GHActive==0)
						GH_colour:="cRed"
					else if (this.Stats.GHActive==1)
						GH_colour:="cGreen"
					else if (this.Stats.GHActive==2)
						GH_colour:="cFFC000" ;Amber
					else
						GH_colour:="c000000"
					GuiControl, ICScriptHub:+%GH_colour%, IBM_Stats_Gem_Hunter
					GuiControl, ICScriptHub:MoveDraw,IBM_Stats_Gem_Hunter ;Required to update the colour as we don't change the text
					FormatTime, formattedDateTime,, yyyy-MM-ddTHH:mm:ss
					GuiControl, ICScriptHub:, IBM_Stats_Group, % "Run Stats (" . formattedDateTime . ")"
				}
			}
		}
		;Current stats - Run time
        if (this.Stats.PreviousRunEndTime)
			runTime:=A_TickCount - this.Stats.PreviousRunEndTime
		else
			runTime:="-.-"
		;Current stats - Area time
		areaTime:="-.-"
		currentZone:=g_SF.Memory.ReadCurrentZone()
		if (currentZone!="")
		{
			if (this.Stats.LastZone=="" OR currentZone==1) ;Start of run or reset
			{
				if (this.Stats.PreviousRunEndTime) ;If there is an end time for the previous run, use that as a starting point
				{
					this.Stats.PreviousZoneStartTime:=this.Stats.PreviousRunEndTime
					areaTime:=A_TickCount - this.Stats.PreviousRunEndTime
				}
				else
				{
					this.Stats.PreviousZoneStartTime:=A_TickCount
					areaTime:=0 ;Since we just set PreviousZoneStartTime:=A_TickCount
				}
				this.Stats.LastZone:=currentZone
			}
			else if (currentZone > 1 AND currentZone != this.Stats.LastZone) ;New zone
			{
				this.Stats.PreviousZoneStartTime:=A_TickCount
				this.Stats.LastZone:=currentZone
				areaTime:=0 ;Since we just set PreviousZoneStartTime:=A_TickCount
			}
			else
			{
				areaTime:=A_TickCount - this.Stats.PreviousZoneStartTime
			}
		}
		else
			this.MemoryReadFailCount++ ;The zone read is used as the trigger to refresh memory if needed, as it's done every time and should be available outside of a few moments during reset TODO: That isn't so true during offlines (even BrivMaster's ones)
		;Current stats - Steelbones stacks
  		stacks:=g_SF.Memory.ReadSBStacks()
        if (stacks=="") ;If the memory read isn't current
        {
            if (this.Stats.StacksSB=="")
				message_SB:="-"
			else
				message_SB := this.Stats.StacksSB . " [last]"
        }
		else
		{
            this.Stats.StacksSB:=stacks
			message_SB:=this.Stats.StacksSB
        }
		;Current stats - Haste stacks
        stacks:=g_SF.Memory.ReadHasteStacks()
		if (stacks=="") ;If the memory read isn't current
        {
            if (this.Stats.StacksHaste=="")
				message_Haste:="-"
			else
				message_Haste := this.Stats.StacksHaste . " [last]"
        }
		else
		{
            this.Stats.StacksHaste:=stacks
			message_Haste:=this.Stats.StacksHaste
        }
        GuiControl, ICScriptHub:, IBM_Stats_Current_Area_Run_Time, % ROUND(areaTime/1000,1) . " / " . Round(runTime/1000,1)
		GuiControl, ICScriptHub:, IBM_Stats_Loop, % this.SharedRunData.LoopString
		GuiControl, ICScriptHub:, IBM_Stats_Current_Briv, % message_SB . " / " . message_Haste
		GuiControl, ICScriptHub:, IBM_Stats_Last_Close, % this.SharedRunData.LastCloseReason
		;Gem farm stats
		GuiControl, ICScriptHub:, IBM_Stats_Boss_Hits, % this.SharedRunData.BossesHitThisRun . " / " . this.SharedRunData.TotalBossesHit
        GuiControl, ICScriptHub:, IBM_Stats_Rollbacks, % this.SharedRunData.TotalRollBacks
        GuiControl, ICScriptHub:, IBM_Stats_Bad_Auto, % this.SharedRunData.BadAutoProgress
	}

	StatsUpdateFastSlow(Stat,statTime) ;Helper for the slow/fast/total stat for each category
	{
		if (!Stat.Slow OR statTime > Stat.Slow)
			Stat.Slow:=statTime
		if (!Stat.Fast OR statTime < Stat.Fast)
			Stat.Fast:=statTime
		Stat.TotalTime+=statTime
	}

	GameSettingsCheck(change:=false) ;Checks settings but does not change them
	{
		this.NextGameSettingsCheck:=A_TickCount + 3600000 ;Hourly check
		checkTime:="(" . A_Hour . ":" . A_Min . ")"
		if (!this.GameSettingFileLocation)
		{
			this.GetSettingsFileLocation(checkTime)
			if (!this.GameSettingFileLocation) ;We tried and we failed
				return
		}
		profile:=this.settings.IBM_Game_Settings_Option_Profile
		gameSettings:=this.LoadObjectFromAHKJSON(this.GameSettingFileLocation)
		changeCount:=0
		this.SettingCheck(gameSettings,"TargetFramerate","Framerate",false,changeCount,change) ;TODO: Just use the CNE names for all the simple ones and loop this?!
		this.SettingCheck(gameSettings,"PercentOfParticlesSpawned","Particles",false,changeCount,change)
		this.SettingCheck(gameSettings,"resolution_x","HRes",false,changeCount,change)
		this.SettingCheck(gameSettings,"resolution_y","VRes",false,changeCount,change)
		this.SettingCheck(gameSettings,"resolution_fullscreen","Fullscreen",true,changeCount,change)
		this.SettingCheck(gameSettings,"ReduceFramerateWhenNotInFocus","CapFPSinBG",true,changeCount,change)
		this.SettingCheck(gameSettings,"FormationSaveIncludeFeatsCheck","SaveFeats",true,changeCount,change)
		this.SettingCheck(gameSettings,"UseConsolePortraits","ConsolePortraits",true,changeCount,change)
		this.SettingCheck(gameSettings,"NarrowHeroBoxes","NarrowHero",true,changeCount,change)
		this.SettingCheck(gameSettings,"ShowAllHeroBoxes","AllHero",true,changeCount,change)
		this.SettingCheck(gameSettings,"HotKeys","Swap25100",false,changeCount,change)
		if (changeCount)
		{
			if (change)
			{
				if (this.IsGameClosed())
				{
					this.WriteObjectToAHKJSON(this.GameSettingFileLocation,gameSettings)
					g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . this.settings.IBM_Game_Settings_Option_Set[profile,"Name"] . " aligned with " . (changeCount==1 ? "1 change" : changeCount . " changes"),"cGreen")
				}
				else
				{
					MsgBox,,Game Running,Game settings cannot be changed whilst Idle Champions is running
					g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . this.settings.IBM_Game_Settings_Option_Set[profile,"Name"] . " have " . changeCount . (changeCount==1 ? " difference" : " differences"),"cFFC000")
				}

			}
			else
			{
				g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . this.settings.IBM_Game_Settings_Option_Set[profile,"Name"] . " have " . changeCount . (changeCount==1 ? " difference" : " differences"),"cFFC000")
			}
		}
		else
		{
			g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . this.settings.IBM_Game_Settings_Option_Set[profile,"Name"] . " match","cGreen")
		}
	}

	SettingCheck(gameSettings, CNEName, IBMName,isBoolean, byRef changeCount,change:=false)
	{
		if (IBMName=="Swap25100") ;Special case for the hotkey swap
		{
			if (this.settings.IBM_Game_Settings_Option_Set[this.settings.IBM_Game_Settings_Option_Profile,IBMName]) ;If not using this option we don't care what the user has set them to, so only check in this case
			{
				level25:=gameSettings[CNEName,"hero_level_25"] ;This should be a single-element array ["LeftControl"]
				if !(level25.Count()==1 AND level25[1]=="LeftControl")
				{
					changeCount++
					if (change)
						gameSettings[CNEName,"hero_level_25"]:=["LeftControl"]
				}
				level100:=gameSettings[CNEName,"hero_level_100"] ;This should be a two-element array ["LeftShift","LeftControl"]
				if !(level100.Count()==2 AND ((level100[1]=="LeftShift" AND level100[2]=="LeftControl") OR (level100[1]=="LeftControl" AND level100[2]=="LeftShift"))) ;TODO: Shift,Control is how the game saves it, determine if Control,Shift is actually valid?
				{
					changeCount++
					if (change)
						gameSettings[CNEName,"hero_level_100"]:=["LeftShift","LeftControl"]
				}
			}
			return
		}
		if (isBoolean)
			targetValue:=this.settings.IBM_Game_Settings_Option_Set[this.settings.IBM_Game_Settings_Option_Profile,IBMName]==1 ? "true" : "false"
		else
			targetValue:=this.settings.IBM_Game_Settings_Option_Set[this.settings.IBM_Game_Settings_Option_Profile,IBMName]
		if gameSettings[CNEName]!=targetValue
		{
			changeCount++
			if (change)
				gameSettings[CNEName]:=targetValue
		}
	}

	LoadObjectFromAHKJSON( FileName )
    {
        FileRead, oData, %FileName%
        data := ""
        try
        {
            data := AHK_JSON_RAWBOOLEAN.Load( oData )
        }
        catch err
        {
            err.Message := err.Message . "`nFile:`t" . FileName
            throw err
        }
        return data
    }

    WriteObjectToAHKJSON( FileName, ByRef object )
    {
        objectJSON := AHK_JSON_RAWBOOLEAN.Dump( object,,"`t")
        if (!objectJSON)
            return
        FileDelete, %FileName%
        FileAppend, %objectJSON%, %FileName%
        return
    }

	GetSettingsFileLocation(checkTime)
	{
		settingsFileLoc:=this.settings.IBM_Game_Path . "IdleDragons_Data\StreamingAssets\localSettings.json"
		if (FileExist(settingsFileLoc))
		{
			this.GameSettingFileLocation:=settingsFileLoc
		}
		return
	}

	IsGameClosed()
	{
		return !WinExist("ahk_exe " . this.settings.IBM_Game_Exe)
	}

	ChestSnatcher() ;Process chest purchase orders
	{
		if (this.SharedRunData.IBM_BuyChests) ;Check daily rewards or Open chests
		{
			if (this.settings.IBM_DailyRewardClaim_Enable AND A_TickCount >= this.NextDailyClaimCheck)
			{
				this.ChestSnatcher_ClaimDailyRewards()
				g_IriBrivMaster_GUI.IBM_ChestsSnatcher_Status_Update()
			}
			else if (this.settings.IBM_ChestSnatcher_Options_Open_Gold OR this.settings.IBM_ChestSnatcher_Options_Open_Silver)
			{
				this.ChestSnatcher_Process()
			}
			else
				this.SharedRunData.IBM_BuyChests:=0 ;Cancel the order
		}
		else if (this.settings.IBM_ChestSnatcher_Options_Min_Buy)
		{
			gems:=this.CurrentGems - this.settings.IBM_ChestSnatcher_Options_Min_Gem
			amountG:=Min(Floor(gems / this.CONSTANT_goldCost) , this.CONSTANT_serverRateBuy )
			if (amountG >= this.settings.IBM_ChestSnatcher_Options_Min_Buy)
			{
				this.ChestSnatcher_AddMessage("Buy","No open order, buying " . amountG . " Gold...")
				this.ChestSnatcher_BuyChests(2, amountG )
				g_IriBrivMaster_GUI.IBM_ChestsSnatcher_Status_Update()
			}
		}

	}

	ChestSnatcher_AddMessage(action,comment)
	{
		message:={}
		FormatTime, formattedTime,, HH:mm:ss
		message["Time"]:=formattedTime
		message["Action"]:=action
		message["Comment"]:=comment
		this.ChestSnatcher_Messages.Push(message)
		if (this.ChestSnatcher_Messages.Count()>20)
			this.ChestSnatcher_Messages.RemoveAt(1)
	}

	ChestSnatcher_ClaimDailyRewards()
	{
		lastSaveEpoch:=g_SF.Memory.IBM_ReadLastSave() ;Reads in seconds since 01Jan0001
		If (lastSaveEpoch=="")
			return
		lastSave:=this.ChestSnatcher_CNETimeStampToDate(lastSaveEpoch)
		secondsElapsed:=A_NOW
		secondsElapsed-=lastSave,s
		if (secondsElapsed>=2)
			return
		serverString:="&user_id=" . g_SF.Memory.ReadUserID() . "&hash=" . g_SF.Memory.ReadUserHash() . "&instance_id=" . g_SF.Memory.ReadInstanceID() . "&language_id=1&timestamp=0&request_id=0&network_id=" . g_SF.Memory.ReadPlatform() . "&mobile_client_version=" . g_SF.Memory.ReadBaseGameVersion() . "&instance_key=1&offline_v2_build=1&localization_aware=true"
		response := g_ServerCall.ServerCall("getdailyloginrewards",serverString) ;Check what rewards are available and their claim status
		if (IsObject(response) && response.success)
		{
			dayMask := 1 << (response.daily_login_details.today_index)
			if (response.daily_login_details.premium_active && response.daily_login_details.premium_expire_seconds > 0)
				boostExpiry:=response.daily_login_details.premium_expire_seconds / 86400 ;Convert to days
			standardClaimed:=(response.daily_login_details.rewards_claimed & dayMask) > 0
			premimumClaimed:=(response.daily_login_details.premium_rewards_claimed & dayMask) > 0
			if(standardClaimed AND (premimumClaimed OR !response.daily_login_details.premium_active)) ;standard claimed, and premium either claimed or not active - no need to further claim
			{
				nextClaim_Seconds := response.daily_login_details.next_claim_seconds
				this.NextDailyClaimCheck:=A_TickCount + MIN(28800000,nextClaim_Seconds * 1000) ;8 hours, or the next reset TODO: What happens when this rolls over?
				this.ChestSnatcher_AddMessage("Claim", response.daily_login_details.premium_active ? "Standard and premium daily rewards already claimed" : "Standard daily reward already claimed. Premium not active")
				if (response.daily_login_details.premium_active)
					this.ChestSnatcher_AddMessage("Claim", "Premium daily reward expires in " . Round(boostExpiry,1) . " days") ;Seperate entry simply due to length
				return
			}
			else ;Need to claim
			{
				if (response.daily_login_details.premium_active)
				{
					this.ChestSnatcher_AddMessage("Claim", "Standard reward " . standardClaimed ? "" : "un" . "claimed and premium reward " . standardClaimed ? "" : "un" . "claimed. Claiming...")
					this.ChestSnatcher_AddMessage("Claim", "Premium daily reward expires in " . Round(boostExpiry,1) . " days")
				}
				else
					this.ChestSnatcher_AddMessage("Claim", "Standard reward " . standardClaimed ? "" : "un" . "claimed and premium reward not active. Claiming...") ;TODO: The standardClaimed check is redundant in this case, left for debugging for mow
				this.ChestSnatcher_AddMessage("Claim", messageString)
			}
		}
		else ;Check failed
		{
			this.ChestSnatcher_AddMessage("Claim", "Failed to check current daily reward status")
			return
		}
		extraParams := "&is_boost=0" . serverString
		response := g_ServerCall.ServerCall("claimdailyloginreward",extraParams) ;Claim rewards
		if (IsObject(response) AND response.success)
		{
			nextClaim_Seconds:=response.daily_login_details.next_claim_seconds
			if (response.daily_login_details.premium_active) ;TODO: Use the initial check servercall to determine if this is needed? (So we can call ONLY the premium if it's the only one outstanding)
			{
				extraParams := "&is_boost=1" . serverString
				response := g_ServerCall.ServerCall("claimdailyloginreward",extraParams)
				if (IsObject(response) AND response.success)
				{
					nextClaim_Seconds:=response.daily_login_details.next_claim_seconds
					this.ChestSnatcher_AddMessage("Claim", "Claimed standard and premium daily rewards")
				}
				else ;Standard worked, premium failed despite being available?
					this.ChestSnatcher_AddMessage("Claim", "Claimed standard daily reward and failed to claim available premium reward")
			}
			else
			{
				this.ChestSnatcher_AddMessage("Claim", "Claimed standard daily reward")
			}
			if (!nextClaim_Seconds) ;If we somehow didn't get a value for the next time (despite success on the call), wait 5min before calling again
				nextClaim_Seconds:=300
			this.NextDailyClaimCheck:=A_TickCount + MIN(28800000,nextClaim_Seconds * 1000) ;8 hours, or the next reset TODO: What happens when this rolls over?
		}
		else
		{
			this.NextDailyClaimCheck:=A_TickCount + 60000 ;Wait 1min before trying again
			this.ChestSnatcher_AddMessage("Claim","Failed to claim daily rewards")
			this.ServerCallFailCount++
		}
	}

	ChestSnatcher_GetBaseServerString()
	{
		return "&user_id=" . g_SF.Memory.ReadUserID() . "&hash=" . g_SF.Memory.ReadUserHash() . "&instance_id=" . g_SF.Memory.ReadInstanceID() . "&language_id=1&timestamp=0&request_id=0&network_id=" . g_SF.Memory.ReadPlatform() . "&mobile_client_version=" . g_SF.Memory.ReadBaseGameVersion() . "&instance_key=1&offline_v2_build=1&localization_aware=true"
	}

	ChestSnatcher_BuyChests(chestID := 1, numChests := 100)
    {
		if (numChests > 0)
		{
			callTime:=A_TickCount
			response := g_ServerCall.CallBuyChests( chestID, numChests )
			serverCallTime:=A_TickCount-callTime
			if (response.okay AND response.success)
			{
				If (chestID==1)
				{
					this.Chests.PurchasedSilver+=numChests
					this.Chests.CurrentSilver:=response.chest_count
					this.ChestSnatcher_AddMessage("Buy","Bought " . numChests " Silver in " . serverCallTime . "ms")
				}
				else If (ChestID==2)
				{
					this.Chests.PurchasedGold+=numChests
					this.Chests.CurrentGold:=response.chest_count
					this.ChestSnatcher_AddMessage("Buy","Bought " . numChests " Gold in " . serverCallTime . "ms")
				}
				this.CurrentGems:=response.currency_remaining
			}
			else
			{
				this.ChestSnatcher_AddMessage("Buy","Chest purchase failed")
				this.ServerCallFailCount++
			}
		}
    }

	ChestSnatcher_Process()
	{
		lastSaveEpoch:=g_SF.Memory.IBM_ReadLastSave() ;Reads in seconds since 01Jan0001
		If (lastSaveEpoch=="")
			return
		lastSave:=this.ChestSnatcher_CNETimeStampToDate(lastSaveEpoch)
		secondsElapsed:=A_NOW
		secondsElapsed-=lastSave,s
		if (secondsElapsed>=2)
			return
		this.SharedRunData.IBM_BuyChests:=false ;Prevent repeats in the same run
		if (this.settings.IBM_ChestSnatcher_Options_Open_Gold AND this.settings.IBM_ChestSnatcher_Options_Open_Gold + this.settings.IBM_ChestSnatcher_Options_Min_Gold <= this.Chests.CurrentGold)
		{
			this.ChestSnatcher_OpenChests(2,this.settings.IBM_ChestSnatcher_Options_Open_Gold)
		}
		else if (this.settings.IBM_ChestSnatcher_Options_Open_Silver AND this.settings.IBM_ChestSnatcher_Options_Open_Silver + this.settings.IBM_ChestSnatcher_Options_Min_Silver <= this.Chests.CurrentSilver)
		{
			this.ChestSnatcher_OpenChests(1,this.settings.IBM_ChestSnatcher_Options_Open_Silver)
		}
		else
			this.ChestSnatcher_AddMessage("Open","Not enough chests to process open order")
		g_IriBrivMaster_GUI.IBM_ChestsSnatcher_Status_Update()
	}

	RefreshUserData()
    {
        if(WinExist("ahk_exe " . this.settings.IBM_Game_Exe)) ; only update server when the game is open
        {
            g_SF.Memory.OpenProcessReader()
            g_SF.ResetServerCall()
			this.ServerCallFailCount:=0 ;Reset
			this.MemoryReadFailCount:=0
			if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
				this.SharedRunData.IBM_ProcessSwap:=false
        }
    }

	ChestSnatcher_CNETimeStampToDate(timeStamp) ;Takes a timestamp in seconds-since-day-0 format and converts it to a date for AHK use
	{
		unixTime:=timeStamp-62135596800 ;Difference between day 1 (01Jan0001) and unix time (AHK doesn't support dates before 1601 so we can't just set converted:=1)
		converted:=1970
		converted+=unixTime,s
		return converted
	}

	ChestSnatcher_OpenChests(chestID:=1,numChests:=250)
    {
		chestName:=chestID==2 ? "Gold" : "Silver"
        callTime:=A_TickCount
		this.ChestSnatcher_AddMessage("Open","Opening " . numChests . " " . chestName . "...")
		chestResults := g_ServerCall.CallOpenChests( chestID, numChests )
		serverCallTime:=A_TickCount-callTime
        if (!chestResults.success)
		{
			if (!chestResults.failure_reason)
			{
				this.ChestSnatcher_AddMessage("Open","Failed attempting to open " . numChests . " " . chestName " - no reason reported")
				this.ServerCallFailCount++
			}
			else if (chestResults.failure_reason=="Outdated instance id")
			{
				this.ChestSnatcher_AddMessage("Open","Failed attempting to open " . numChests . " " . chestName " - Old ID - Refreshing")
				this.RefreshUserData()
			}
			else
			{
				this.ChestSnatcher_AddMessage("Open","Failed attempting to open " . numChests . " " . chestName " - " . chestResults.failure_reason)
				this.ServerCallFailCount++
			}
			return
		}
 		if (chestID==1)
		{
			this.Chests.OpenedSilver+=numChests
			this.Chests.CurrentSilver:=chestResults.chests_remaining
			this.ChestSnatcher_AddMessage("Open","Opened " . numChests " Silver in " . serverCallTime . "ms")

		}
		else if (chestID==2)
		{
			this.Chests.OpenedGold+=numChests
		    this.Chests.CurrentGold:=chestResults.chests_remaining
			this.ChestSnatcher_AddMessage("Open","Opened " . numChests " Gold in " . serverCallTime . "ms")
		}
    }

	SetControl_RestoreWindow() ;Toggles
	{
		if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
            this.SharedRunData.IBM_UpdateOutbound("IBM_RestoreWindow_Enabled",!this.SharedRunData.IBM_RestoreWindow_Enabled)
		else
			Msgbox % "Failed to update script."
	}

	ParseRouteImportString(routeString)
	{
		RegExMatch(routeString,"{([A-Za-z0-9-_]+),.*}",routeMatches)
		if (strlen(routeMatches1)>0)
		{
			this.settings.IBM_Route_Zones_Jump:=IC_BrivMaster_SharedFunctions_Class.IBM_ConvertBase64ToBinaryArray(routeMatches1)
			while (this.settings.IBM_Route_Zones_Jump.Length() > 50) ;The input will represent a multiple of 6 bits
				this.settings.IBM_Route_Zones_Jump.Pop()
			g_IriBrivMaster_GUI.RefreshRouteJumpBoxes()
		}
		RegExMatch(routeString,"{.*,([A-Za-z0-9-_]+)}",routeMatches)
		if (strlen(routeMatches1)>0)
		{
			this.settings.IBM_Route_Zones_Stack:=IC_BrivMaster_SharedFunctions_Class.IBM_ConvertBase64ToBinaryArray(routeMatches1)
			while (this.settings.IBM_Route_Zones_Stack.Length() > 50) ;The input will represent a multiple of 6 bits
				this.settings.IBM_Route_Zones_Stack.Pop()
			g_IriBrivMaster_GUI.RefreshRouteStackBoxes()
		}
	}

	GetRouteExportString()
	{
		return "{" . IC_BrivMaster_SharedFunctions_Class.IBM_ConvertBinaryArrayToBase64(this.settings.IBM_Route_Zones_Jump) . "," . IC_BrivMaster_SharedFunctions_Class.IBM_ConvertBinaryArrayToBase64(this.settings.IBM_Route_Zones_Stack) . "}"
	}

	SetControl_OfflineStacking()
	{
		if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
            this.SharedRunData.IBM_UpdateOutbound("IBM_RunControl_DisableOffline",!this.SharedRunData.IBM_RunControl_DisableOffline) ;Toggle
		else
			Msgbox % "Failed to update script."
	}

	SetControl_QueueOffline()
	{
		If (ComObjType(this.SharedRunData,"IID") OR this.RefreshComObject())
			this.SharedRunData.IBM_UpdateOutbound("IBM_RunControl_ForceOffline",!this.SharedRunData.IBM_RunControl_ForceOffline) ; Toggle
		else
			Msgbox % "Failed to update script."
	}

	UpdateStatus() ;Run by timer to update the GUI
    {
		comValid:=ComObjType(this.SharedRunData,"IID") OR this.RefreshComObject()
		if ((comValid AND this.SharedRunData.IBM_ProcessSwap) OR this.ServerCallFailCount>2 OR this.MemoryReadFailCount>10) ;Irisiri - check we are still attached to the process
		{
			this.RefreshUserData()
		}
		if (comValid)
        {
			try ;The script stopping can cause the COM object to become invalid instantaneously
			{
			dirty:=this.SharedRunData.IBM_OutboundDirty
			this.SharedRunData.IBM_OutboundDirty:=false ;Needs to be reset right away, so updates during processing are not loss
			;OutputDebug % A_TickCount . " Dirty=[" . dirty . "]`n"
			if (dirty)
			{
				this.STATUS_RunControlOffline:=this.SharedRunData.IBM_RunControl_DisableOffline
				g_IriBrivMaster_GUI.UpdateRunControlDisable(this.STATUS_RunControlOffline)
				this.STATUS_RunControlForce:=this.SharedRunData.IBM_RunControl_ForceOffline
				g_IriBrivMaster_GUI.UpdateRunControlForce(this.STATUS_RunControlForce)
				this.STATUS_RestoreWindow:=this.SharedRunData.IBM_RestoreWindow_Enabled
				g_IriBrivMaster_GUI.UpdateRestoreWindow(this.SharedRunData.IBM_RestoreWindow_Enabled)
				this.CYCLE_Message_String:=this.SharedRunData.IBM_RunControl_CycleString
				this.STATUS_Message_String:=this.SharedRunData.IBM_RunControl_StatusString
				this.STATUS_Stack_String:=this.SharedRunData.IBM_RunControl_StackString
				g_IriBrivMaster_GUI.UpdateRunStatus(this.CYCLE_Message_String,this.STATUS_Message_String,this.STATUS_Stack_String)
			}
			this.UpdateStats(dirty)
			this.ChestSnatcher() ;AFter stats as Stats reads the gem/chest counts on new run start
			}
			catch
				g_IriBrivMaster_GUI.ResetStatusText()
        }
        else
            g_IriBrivMaster_GUI.ResetStatusText()
		if (A_TickCount>=this.NextGameSettingsCheck)
			this.GameSettingsCheck()
    }

	LoadSettings()
    {
        needSave := false
        default := this.GetNewSettings()
        this.Settings := settings := g_SF.LoadObjectFromJSON(IC_BrivMaster_SharedData_Class.SettingsPath)
        if (!IsObject(settings))
        {
            this.Settings := settings := default
            needSave := true
        }
        else
        {
            ; Delete extra settings
            for k, v in settings
            {
                if (!default.HasKey(k))
                {
                    settings.Delete(k)
                    needSave := true
                }
            }
            ; Add missing settings
            for k, v in default
            {
                if (!settings.HasKey(k) || settings[k] == "")
                {
                    settings[k] := default[k]
                    needSave := true
                }
            }
        }
        if (needSave)
            this.SaveSettings()
        ; Set the state of GUI buttons with saved settings.
        g_IriBrivMaster_GUI.UpdateGUISettings(settings)
    }

    UpdateSetting(setting, value)
    {
        this.Settings[setting] := value
    }

    UpdateLevelSettings(levelData)
    {
        this.Settings["IBM_LevelManager_Levels",this.Settings["IBM_Route_Combine"]] := levelData
    }

	UpdateRouteSetting(setting,toggleZone)
	{
		this.Settings[setting][toggleZone]:=!this.Settings[setting][toggleZone]
	}

	IBM_GetGUIFormationData() ;Generates formation data for the level manager GUI
	{
		championData:={} ;This will be per seat, then champID with a list of formations containing, eg championData[1][58] being [1,3,4] if Briv is in Q/E/M but not W
        slots:=["Q","W","E"]
		loop 3
		{
			formation:=g_SF.Memory.GetFormationByFavorite(A_Index)
			this.IBM_GetGUIFormationData_ProcessFormation(championData,slots[A_Index],formation)
		}
		formation:=g_SF.Memory.GetActiveModronFormation()
		this.IBM_GetGUIFormationData_ProcessFormation(championData,"M",formation)
		return championData
	}

	IBM_GetGUIFormationData_ProcessFormation(championData,index,formation)
	{
		for _, champId in formation
		{
			if champID>0
			{
				seat:=g_SF.Memory.ReadChampSeatByID(champID)
                if !(championData.hasKey(seat) and championData[seat].hasKey(champID)) ;Create entry for this champ
                {
                    championData[seat,champID,"Name"]:=g_SF.Memory.ReadChampNameByID(champID) ;We need to create the array if it doesn't yet exist
                    championData[seat,champID,"Q"]:=false
                    championData[seat,champID,"W"]:=false
                    championData[seat,champID,"E"]:=false
                    championData[seat,champID,"M"]:=false
                }
                championData[seat,champID,index]:=true
			}
		}
	}

	IBM_Elly_StartNonGemFarm()
    {
        this.Elly_NonGemFarm := new IC_BrivMaster_EllywickDealer_NonFarm_Class(this.IBM_Elly_GetNonGemFarmCards("Min"),this.IBM_Elly_GetNonGemFarmCards("Max"))
        this.Elly_NonGemFarm.Start()
		g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Started")
    }

    IBM_Elly_StopNonGemFarm()
    {
        this.Elly_NonGemFarm.Stop()
        this.Elly_NonGemFarm := ""
		g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Stopped")
    }

    IBM_Elly_GetNonGemFarmCards(capType:="Min")
    {
        cards := []
        Loop 5
        {
            GuiControlGet, cap, ICScriptHub:, IBM_NonGemFarm_Elly_%capType%_%A_Index% ;Eg IBM_NonGemFarm_Elly_Min_1
            cards.Push(cap)
        }
        return cards
    }

}

;Modifed AHK JSON Library for working with the game setting file - as JSON lacks a boolean type 'x'=false or 'y'=true ges turned into numeric values as standard

/**
 * Modify by WarpRider, Member on https://www.autohotkey.com/boards
 *     ingnore the ahk internal vars true/false and the string null wil be not empty
 */

class AHK_JSON_RAWBOOLEAN extends AHK_JSON ;Irisiri - renamed as SH already has a JSON class powered by JavaScript
{
	class Load extends AHK_JSON.Load
	{
		Call(self, ByRef text, reviver:="")
		{
			this.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			this.keys := this.rev ? {} : false

			static quot := Chr(34), bashq := "\" . quot
			     , json_value := quot . "{[01234567890-tfn"
			     , json_value_or_array_closing := quot . "{[]01234567890-tfn"
			     , object_key_or_object_closing := quot . "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0

			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0

					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )

						ObjInsertAt(stack, 1, value)

						if (this.keys)
							this.keys[value] := []

					} else {
						if (ch == quot) {
							i := pos
							while (i := InStr(text, quot,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

								static tail := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, tail) != "\")
									break
							}

							if (!i)
								this.ParseError("'", text, pos)

							  value := StrReplace(value,  "\/",  "/")
							, value := StrReplace(value, bashq, quot)
							, value := StrReplace(value,  "\b", "`b")
							, value := StrReplace(value,  "\f", "`f")
							, value := StrReplace(value,  "\n", "`n")
							, value := StrReplace(value,  "\r", "`r")
							, value := StrReplace(value,  "\t", "`t")

							pos := i ; update pos

							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}

							if (is_key) {
								key := value, next := ":"
								continue
							}

						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)
							;MsgBox, "value=" %value%

							static number := "number", integer :="integer"
							if value is %number%
							{
								if value is %integer%
									value += 0
							}

							;WarpRider 31.01.2023: hier wird value auf true oder false geprüft und behandelt, nach AHK wird das dann 0 oder 1,
							;das ist aber falsch, da true/false für JSON keine boolschen Variablen sind, value muss unverändert übernommen werden
							else if (value == "true" || value == "false")
								value := value	;ORIGINAL: value := %value% + 0


							else if (value == "null")
								value := "null"									;WarpRider 31.01.2023: hier genauso, warum wird null nicht stur übernommen?
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								this.ParseError(next, text, pos, i)

							pos += i-1
						}

						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else

					is_array? key := ObjPush(holder, value) : holder[key] := value

					if (this.keys && this.keys.HasKey(holder))
						this.keys[holder].Push(key)
				}

			} ; while ( ... )

			return this.rev ? this.Walk(root, "") : root[""]
		}
	}

	class Dump extends AHK_JSON.Dump
	{
		Str(holder, key)
		{
			value := holder[key]

			if (this.rep)
				value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion<"2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (this.gap) {
						stepback := this.indent
						this.indent .= this.gap
					}

					is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects. Due to the use of a for-loop
				; sparse arrays such as '[1,,3]' are detected as objects({}).
					if (!is_array) {
						for i in value
							is_array := i == A_Index
						until !is_array
					}

					str := ""
					if (is_array) {
						Loop, % value.Length() {
							if (this.gap)
								str .= this.indent

							v := this.Str(value, A_Index)
							str .= (v != "") ? v . "," : "null,"
						}
					} else {
						colon := this.gap ? ": " : ":"
						for k in value {
							v := this.Str(value, k)
							if (v != "") {
								if (this.gap)
									str .= this.indent

								str .= this.Quote(k) . colon . v . ","
							}
						}
					}

					if (str != "") {
						str := RTrim(str, ",")
						if (this.gap)
							str .= stepback
					}

					if (this.gap)
						this.indent := stepback

					return is_array ? "[" . str . "]" : "{" . str . "}"
				}

			}
			;WarpRider 31.01.2023: alle Werte hier, ausser Zahlen werden durch die Funktion Quote() mit " eingefasst,
			;das darf bei true,false,null eben nicht so sein, da true/false für JSON keine boolschen Variablen sind und null nicht leer werden
			else ; is_number ? value : "value"
			{
			;MsgBox, vor.Str.return.raw.value=%value%
			if (value == "true" || value == "false" || value == "null")
			  return value
			else
			  return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
			}

		}
	}
}