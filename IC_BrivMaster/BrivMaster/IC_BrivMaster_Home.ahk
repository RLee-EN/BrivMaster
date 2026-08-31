Class IC_IriBrivMaster_Component
{
	static BASE_64_CHARACTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_" ;RFC 4648 S5 URL-safe, aka base64url

	Settings:={}
	TimerFunction:=ObjBindMethod(this, "UpdateStatus")
	SharedRunData:=""
	CONSTANT_serverRateOpen:=1000 ;For chests TODO: Make a table of this stuff? Note the GUI file does use them
	CONSTANT_serverRateBuy:=250
	CONSTANT_goldCost:=500
	CONSTANT_silverCost:=50
	ServerCallFailCount:=0 ;Track the number of failed calls, so we can refresh the user data / servercall, but avoid doing so because one call happened to fail (e.g. at 20:00 UK the new game day starting tends to result in fails)
	MemoryReadFailCount:=0 ;Separate tracker for memory reads, as these are expected to fail during resets etc (TODO: We could combine and just add different numbers, e.g. 5 for a call fail or 1 for a memory read fail?)

	;START STUFF COPIED FROM IC_BrivGemFarm_Component.ahk

	Run_Clicked()
    {
        try
        {
            this.Connect_Clicked()
            SharedData:=ComObjActive(this.GemFarmGUID)
            SharedData.ShowGui()
        }
        catch
        {
            g_SF.Hwnd:=WinExist("ahk_exe " . g_IBM_Settings["ExeName"])
            g_SF.Memory.OpenProcessReader()
			g_ServerCall.Update()
            scriptLocation:=A_LineFile . "\..\IC_BrivMaster_Run.ahk"
            GuiControl, IBM_Home:Choose, ModronTabControl, Stats
            for k,v in g_IriBrivMaster_StartFunctions
            {
                v.Call()
            }
            GuidCreate:=ComObjCreate("Scriptlet.TypeLib")
            this.GemFarmGUID:= guid:=GuidCreate.Guid
            Run, %A_AhkPath% "%scriptLocation%" "%guid%"
        }
    }

    UpdateGUIDFromLast()
    {
        this.GemFarmGUID:=g_SF.LoadObjectFromAHKJSON(A_LineFile . "\..\LastGUID_IBM_GemFarm.json")
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
            SharedRunData:=ComObjActive(this.GemFarmGUID)
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

    Connect_Clicked() ;TODO: Consolidate Connect and Run
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
        g_SF.Hwnd := WinExist("ahk_exe " . g_IBM_Settings["ExeName"])
        g_SF.Memory.OpenProcessReader()
		g_ServerCall.Update()
        for k,v in g_IriBrivMaster_StartFunctions
        {
            v.Call()
        }
    }

    LEGACY_UpdateStatus(msg)
    {
        GuiControl, IBM_Home:, IBM_MainButtons_Status, % msg
        if (msg=="")
			return
		SetTimer, ClearButtonStatusMessage,-3000
    }

	;END STUFF COPIED FROM IC_BrivGemFarm_Component.ahk

	Init()
    {
		this.GemFarmGUID:=g_SF.LoadObjectFromAHKJSON(A_LineFile . "\..\LastGUID_IBM_GemFarm.json")
        g_Heroes:=new IC_BrivMaster_Heroes_Class()
		this.LoadSettings()
		g_SF:=New IC_BrivMaster_SharedFunctions_Class
		g_IriBrivMaster_GUI.Init() ;Must follow IBM memory manager being set up in g_SF
		g_IriBrivMaster_GUI.UpdateGUISettings()
		this.ChestSnatcher:=New IC_IriBrivMaster_ChestSnatcher_Class()
		this.ResetStats() ;Before we initiate the timers
		g_IriBrivMaster_StartFunctions.Push(ObjBindMethod(this, "Start"))
        g_IriBrivMaster_StopFunctions.Push(ObjBindMethod(this, "Stop"))
		this.ServerCallFailCount:=0
		this.MemoryReadFailCount:=0
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
		if(g_IBM_Settings.HUB.IBM_Version_Check)
			g_IriBrivMaster.RunVersionCheck()
		if(g_IBM_Settings.HUB.IBM_Offsets_Check)
			g_IriBrivMaster.CheckOffsetVersions()
    }

	GetSettingsTemplate() ;_DEFAULT property allows us to seperate the object structure from the default values, as some defaults are themselves objects
    {
        settings:={}
		settings.IBM_Offline_Stack_Zone["_DEFAULT"]:=500
		settings.IBM_Offline_Stack_Min["_DEFAULT"]:=300
		settings.IBM_Route_Combine["_DEFAULT"]:=0
		settings.IBM_Route_Combine_Boss_Avoidance["_DEFAULT"]:=1
		settings.IBM_LevelManager_Levels["_DEFAULT",7]:={"min": 100,"prio": 0,"priolimit": "","z1": 100}
		settings.IBM_LevelManager_Levels["_DEFAULT",58]:={"min": 200,"prio": 3,"priolimit": "","z1": 200}
		settings.IBM_LevelManager_Levels["_DEFAULT",59]:={"min": 70,"prio": 2,"priolimit": "","z1": 70}
		settings.IBM_LevelManager_Levels["_DEFAULT",75]:={"min": 220,"prio": 0,"priolimit": "","z1": 220}
		settings.IBM_LevelManager_Levels["_DEFAULT",83]:={"min": 200,"prio": 4,"priolimit": 100,"z1": 200}
		settings.IBM_LevelManager_Levels["_DEFAULT",91]:={"min": 300,"prio": 0,"priolimit": "","z1": 300}
		settings.IBM_LevelManager_Levels["_DEFAULT",97]:={"min": 100,"prio": 4,"priolimit": 100,"z1": 100}
		settings.IBM_LevelManager_Levels["_DEFAULT",99]:={"min": 200,"prio": 2,"priolimit": "","z1": 200}
		settings.IBM_LevelManager_Levels["_DEFAULT",117]:={"min": 50,"prio": 0,"priolimit": "","z1": 50}
		settings.IBM_LevelManager_Levels["_DEFAULT",139]:={"min": 1,"prio": 0,"priolimit": "","z1": 1}
		settings.IBM_LevelManager_Levels["_DEFAULT",145]:={"min": 100,"prio": 0,"priolimit": "","z1": 100}
		settings.IBM_LevelManager_Levels["_DEFAULT",148]:={"min": 100,"prio": 2,"priolimit": "","z1": 100}
		settings.IBM_LevelManager_Levels["_DEFAULT",165]:={"min": 200,"prio": 2,"priolimit": "","z1": 200}
		settings.IBM_Route_Zones_Jump["_DEFAULT"]:=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		settings.IBM_Route_Zones_Stack["_DEFAULT"]:=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		settings.IBM_Online_Melf_Min["_DEFAULT"]:=349
		settings.IBM_LevelManager_Input_Max["_DEFAULT"]:=5
		settings.IBM_LevelManager_Boost_Use["_DEFAULT"]:=false
		settings.IBM_LevelManager_Boost_Multi["_DEFAULT"]:=8
		settings.IBM_Route_BrivJump_Q["_DEFAULT"]:=4
		settings.IBM_Route_BrivJump_E["_DEFAULT"]:=0
		settings.IBM_Route_BrivJump_M["_DEFAULT"]:=4
		settings.IBM_Casino_Target_Base["_DEFAULT"]:=3
		settings.IBM_Casino_Redraws_Base["_DEFAULT"]:=1
		settings.IBM_Casino_MinCards_Base["_DEFAULT"]:=0
		settings.IBM_Casino_Front_Row_Threshold["_DEFAULT"]:=2
		settings.IBM_OffLine_Delay_Time["_DEFAULT"]:=15000
		settings.IBM_OffLine_Sleep_Time["_DEFAULT"]:=0
		settings.IBM_Level_Options_Mod_Key["_DEFAULT"]:="Shift"
		settings.IBM_Level_Options_Mod_Value["_DEFAULT"]:=10
		settings.IBM_Route_Offline_Restore_Window["_DEFAULT"]:=true
		settings.IBM_OffLine_Freq["_DEFAULT"]:=1
		settings.IBM_OffLine_Blank["_DEFAULT"]:=0
		settings.IBM_OffLine_Blank_Relay["_DEFAULT"]:=0
		settings.IBM_OffLine_Blank_Relay_Zones["_DEFAULT"]:=300
		settings.IBM_Level_Options_Suppress_Front["_DEFAULT"]:=true
		settings.IBM_Level_Options_Ghost["_DEFAULT"]:=true
		settings.IBM_Level_Recovery_Softcap["_DEFAULT"]:=0
		settings.IBM_Format_Date_Display["_DEFAULT"]:="yyyy-MM-ddTHH:mm:ss" ;Hidden setting for date / time display
		settings.IBM_Format_Date_File["_DEFAULT"]:="yyyyMMddTHHmmss" ;Hidden setting for date / time output in filenames, as : is not a valid character there
		settings.IBM_Game_Exe["_DEFAULT"]:="IdleDragons.exe"
		settings.IBM_Game_Path["_DEFAULT"]:="" ;Path and Launch command are user dependant so can't have a default
		settings.IBM_Game_Launch["_DEFAULT"]:=""
		settings.IBM_Game_Hide_Launcher["_DEFAULT"]:=false
		settings.IBM_OffLine_Timeout["_DEFAULT"]:=5
		settings.IBM_BM_X["_DEFAULT"]:=0
		settings.IBM_BM_Y["_DEFAULT"]:=0
		settings.IBM_Window_X["_DEFAULT"]:=0
		settings.IBM_Window_Y["_DEFAULT"]:=900 ;To keep the window on-screen at 1080
		settings.IBM_Window_Hide["_DEFAULT"]:=false
		settings.IBM_Level_Diana_Cheese["_DEFAULT"]:=false
		settings.IBM_Allow_Modron_Buff_Off["_DEFAULT"]:=false ;Hidden setting - allows the script to be started without the modron core buff enabled, for those who want to use potions via saved familiars
		settings.IBM_Logger_MiniLog["_DEFAULT"]:=false
		settings.IBM_Logger_ZoneLog["_DEFAULT"]:=false
		settings.IBM_Online_Farideh_Threshold["_DEFAULT"]:=90
		settings.IBM_Online_Farideh_Condition["_DEFAULT"]:=1
		settings.IBM_Scan_Codes["Esc","_DEFAULT"]:=1 ;Escape for skipping splash screen
		settings.IBM_Scan_Codes["F1","_DEFAULT"]:=59 ;F-keys for levelling
		settings.IBM_Scan_Codes["F2","_DEFAULT"]:=60
		settings.IBM_Scan_Codes["F3","_DEFAULT"]:=61
		settings.IBM_Scan_Codes["F4","_DEFAULT"]:=62
		settings.IBM_Scan_Codes["F5","_DEFAULT"]:=63
		settings.IBM_Scan_Codes["F6","_DEFAULT"]:=64
		settings.IBM_Scan_Codes["F7","_DEFAULT"]:=65
		settings.IBM_Scan_Codes["F8","_DEFAULT"]:=66
		settings.IBM_Scan_Codes["F9","_DEFAULT"]:=67
		settings.IBM_Scan_Codes["F10","_DEFAULT"]:=68
		settings.IBM_Scan_Codes["F11","_DEFAULT"]:=87
		settings.IBM_Scan_Codes["F12","_DEFAULT"]:=88
		settings.IBM_Scan_Codes["q","_DEFAULT"]:=16 ;QWE for formation swapping
		settings.IBM_Scan_Codes["w","_DEFAULT"]:=17
		settings.IBM_Scan_Codes["e","_DEFAULT"]:=18
		settings.IBM_Scan_Codes["g","_DEFAULT"]:=34 ;Auto progress
		settings.IBM_Scan_Codes["Left","_DEFAULT"]:=331 ;Left for moving back a zone
		settings.IBM_Scan_Codes["ClickDmg","_DEFAULT"]:=41 ;Click damage, using text instead of tilde as it's a special character in AHK
		settings.IBM_Scan_Codes["LCtrl","_DEFAULT"]:=29 ;Modifier keys for adjusting levelling amount
		settings.IBM_Scan_Codes["Shift","_DEFAULT"]:=42
		settings.IBM_Scan_Codes["Alt","_DEFAULT"]:=56
		settings.IBM_Scan_Codes[1,"_DEFAULT"]:=2 ;Ultimates
		settings.IBM_Scan_Codes[2,"_DEFAULT"]:=3
		settings.IBM_Scan_Codes[3,"_DEFAULT"]:=4
		settings.IBM_Scan_Codes[4,"_DEFAULT"]:=5
		settings.IBM_Scan_Codes[5,"_DEFAULT"]:=6
		settings.IBM_Scan_Codes[6,"_DEFAULT"]:=7
		settings.IBM_Scan_Codes[7,"_DEFAULT"]:=8
		settings.IBM_Scan_Codes[8,"_DEFAULT"]:=9
		settings.IBM_Scan_Codes[9,"_DEFAULT"]:=10
		settings.IBM_Scan_Codes[0,"_DEFAULT"]:=11
		settings.IBM_OffLine_Blank_Stop["_DEFAULT"]:=false
		settings.IBM_Theme_Current["_DEFAULT"]:={"DefaultText":0xC0C0C0,"WarningText":0xF18500,"SpecialText1":0x8888FF,"SpecialText2":0x88FF88,"TableText":0xE0E0E0,"EditText":0x333333,"TableBackground":0x555555,"WindowBackground":0x333333,"TrafficLightBad":0xF00000,"TrafficLightGood":0x00F000,"TrafficLightNeutral":0xFFC000,"DarkMode":true}
		settings.HUB:={} ;Separate hub-only settings
		settings.HUB.IBM_ChestSnatcher_Options_Min_Gem["_DEFAULT"]:=500000
		settings.HUB.IBM_ChestSnatcher_Options_Min_Gold["_DEFAULT"]:=500
		settings.HUB.IBM_ChestSnatcher_Options_Min_Silver["_DEFAULT"]:=500
		settings.HUB.IBM_ChestSnatcher_Options_Min_Buy["_DEFAULT"]:=250
		settings.HUB.IBM_ChestSnatcher_Options_Open_Gold["_DEFAULT"]:=0
		settings.HUB.IBM_ChestSnatcher_Options_Open_Silver["_DEFAULT"]:=0
		settings.HUB.IBM_DailyRewardClaim_Enable["_DEFAULT"]:=true
		settings.HUB.IBM_Game_Settings_Option_Profile["_DEFAULT"]:=1
		settings.HUB.IBM_Game_Settings_Option_Set[1,"_DEFAULT"]:={Name:"Profile 1",Framerate:600,Particles:0,HRes:1920,VRes:1080,Fullscreen:false,CapFPSinBG:false,SaveFeats:false,ConsolePortraits:false,NarrowHero:true,AllHero:true,Swap25100:false}
		settings.HUB.IBM_Game_Settings_Option_Set[2,"_DEFAULT"]:={Name:"Profile 2",Framerate:600,Particles:0,HRes:1920,VRes:1080,Fullscreen:false,CapFPSinBG:false,SaveFeats:false,ConsolePortraits:false,NarrowHero:true,AllHero:true,Swap25100:false}
		settings.HUB.IBM_Ellywick_NonGemFarm_Cards["_DEFAULT"]:=[0,0,4,5,0,0,0,1,0,0] ;Min/Max for each card in cardID order
		settings.HUB.IBM_Version_Check["_DEFAULT"]:=false
		settings.HUB.IBM_Offsets_Check["_DEFAULT"]:=false
		settings.HUB.IBM_Offsets_Lock_Pointers["_DEFAULT"]:=false
		settings.HUB.IBM_Offsets_URL["_DEFAULT"]:="https://raw.githubusercontent.com/RLee-EN/BrivMaster-Imports/refs/heads/main/" ;Hidden setting to allow a different offset source to be used if wanted
        settings.HUB.IBM_Window_Wide["_DEFAULT"]:=false
		return settings
    }

	SaveSettings()
    {
        IC_BrivMaster_SharedFunctions_Class.WriteObjectToAHKJSON(IC_BrivMaster_SharedData_Class.SettingsPath, g_IBM_Settings)
		if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
			this.SharedRunData.UpdateSettingsFromFile() ;Apply settings to the farm script
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
        g_ServerCall.Update()
		fncToCallOnTimer:=this.TimerFunction
        SetTimer, %fncToCallOnTimer%, 600, 0
		this.SharedRunData:="" ;Reset this on start
		if (this.RefreshComObject())
        {
			this.SharedRunData.IBM_BuyChests:=0 ;Cancel any orders open as the hub starts
        }
		this.ChestSnatcher.StartMessage()
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
		this.Stats.Total.ValidRuns:=0 ;Not actually needed for this
		this.Stats.Active:={}
		this.Stats.Active.Fast:=""
		this.Stats.Active.Slow:=""
		this.Stats.Active.TotalTime:=0
		this.Stats.Active.ValidRuns:=0 ;Not every reported run will have active/reset times due to fails
		this.Stats.Reset:={}
		this.Stats.Reset.Fast:=""
		this.Stats.Reset.Slow:=""
		this.Stats.Reset.TotalTime:=0
		this.Stats.Reset.ValidRuns:=0

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
			this.SharedRunData.ResetRunStats()
		}

		GuiControl, IBM_Home:, IBM_Group_Stats_Timing,Run Timings
		GuiControl, -Redraw, IBM_Stats_Run_LV
		Gui, IBM_Home:Default
		Gui, ListView, IBM_Stats_Run_LV
		LV_Modify(1,,"Total","--.--","--.--","--.--","--.--")
		LV_Modify(2,,"Active","--.--","--.--","--.--","--.--")
		LV_Modify(3,,"Wait","--.--","--.--","--.--","--.--")
		;LV_ModifyCol(1,"AutoHdr")
		LV_ModifyCol(2,"AutoHdr")
		LV_ModifyCol(3,"AutoHdr")
		LV_ModifyCol(4,"AutoHdr")
		LV_ModifyCol(5,"AutoHdr")
		GuiControl, +Redraw, IBM_Stats_Run_LV
		Gui, ListView, IBM_Stats_Chests_LV
		GuiControl, -Redraw, IBM_Stats_Chests_LV
		LV_Modify(1,,"Silver","--.--","--.--","--.--")
		LV_Modify(2,,"Gold","--.--","--.--","--.--")
		LV_ModifyCol(2,"AutoHdr")
		LV_ModifyCol(3,"AutoHdr")
		LV_ModifyCol(4,"AutoHdr")
		GuiControl, +Redraw, IBM_Stats_Chests_LV
		GuiControl, IBM_Home:, IBM_Stats_Total_Runs, 0 in 0s (0h)
		GuiControl, IBM_Home:, IBM_Stats_Fail_Runs, 0 for 0s
		GuiControl, IBM_Home:, IBM_Stats_BPH, BPH: --.--
		GuiControl, IBM_Home:, IBM_Stats_GPH, GPH: --.--
		GuiControl, IBM_Home:, IBM_Stats_TotalGems, 0
		GuiControl, IBM_Home:, IBM_Stats_Gem_Hunter,-
		GuiControl, IBM_Home:, IBM_Stats_Gem_Bonus, -.-`% (-.- GPB)
		GuiControl, IBM_Home:, IBM_Stats_BSC_Reward, --.--
		GuiControl, IBM_Home:, IBM_Stats_Total_Reward, --.--

		GuiControl, IBM_Home:, IBM_Stats_Current_Area_Run_Time,Area / Run (s): - / -
		GuiControl, IBM_Home:, IBM_Stats_Loop, Stage: -
		GuiControl, IBM_Home:, IBM_Stats_Current_Briv, SB / Haste stacks: - / -
		GuiControl, IBM_Home:, IBM_Stats_Last_Close, Last close: -
		GuiControl, IBM_Home:, IBM_Stats_Boss_Hits, - / -
        GuiControl, IBM_Home:, IBM_Stats_Rollbacks, 0
        GuiControl, IBM_Home:, IBM_Stats_Bad_Auto, 0
	}

	UpdateStats(dirty)
	{
		static CONSTANT_baseGPB:=9.02 ;TODO: Read blessings so this correctly reflects those? Seems a bit of a waste of CPU cycles admittedly...just do it at startup?
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
					GuiControl, IBM_Home:, IBM_Group_Stats_Timing, Run Timings (Waiting for run start)
					LogData:=AHK_JSON.Load(this.SharedRunData.RunLog)
					this.Stats.PreviousRunEndTime:=LogData.End ;Include this so it is available for run timing
				}
				else if (this.Stats.StartUpStage==1) ;The run number has changed to a 2nd real number - this is the start of 1st run we are timing
				{
					this.Stats.LastRun:=this.SharedRunData.RunLogResetNumber
					this.Stats.StartUpStage:=2
					GuiControl, IBM_Home:, IBM_Group_Stats_Timing, Run Timings (Waiting for run end)
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
					this.Stats.PreviousRunEndTime:=LogData.End ;Include this so it is available for run timing
				}
				else
				{
					LogData:=AHK_JSON.Load(this.SharedRunData.RunLog)
					this.Stats.LastRun:=LogData.ResetNumber

					totalDuration:=LogData.End - LogData.Start
					this.StatsUpdateFastSlow(this.Stats.Total,totalDuration)
					if(LogData.HasKey("ResetReached") AND LogData.HasKey("ActiveStart")) ;Failed runs may not have a reset value
					{
						activeTime:=LogData.ResetReached - LogData.ActiveStart
						loadTime:=LogData.ActiveStart - LogData.Start
						resetTime:=LogData.End - LogData.ResetReached
						waitTime:=loadTime+resetTime
						this.StatsUpdateFastSlow(this.Stats.Active,activeTime)
						this.StatsUpdateFastSlow(this.Stats.Reset,waitTime)
						waitTime:=ROUND(waitTime/1000,2) ;Round for display, done here so we can have options for missing data
						activeTime:=ROUND(activeTime/1000,2)
					}
					else
					{
						activeTime:="-"
						waitTime:="-"
					}
					this.Stats.TotalRuns++
					this.Stats.PreviousRunEndTime:=LogData.End
					Gui, IBM_Home:Default
					Gui, ListView, IBM_Stats_Run_LV
					GuiControl, -Redraw, IBM_Stats_Run_LV
					LV_Modify(1,,"Total",ROUND(totalDuration/1000,2),ROUND((this.Stats.Total.TotalTime/this.Stats.Total.ValidRuns)/1000,2),ROUND(this.Stats.Total.Fast/1000,2),ROUND(this.Stats.Total.Slow/1000,2))
					LV_Modify(2,,"Active",activeTime,ROUND((this.Stats.Active.TotalTime/this.Stats.Active.ValidRuns)/1000,2),ROUND(this.Stats.Active.Fast/1000,2),ROUND(this.Stats.Active.Slow/1000,2))
					LV_Modify(3,,"Wait",waitTime,ROUND((this.Stats.Reset.TotalTime/this.Stats.Reset.ValidRuns)/1000,2),ROUND(this.Stats.Reset.Fast/1000,2),ROUND(this.Stats.Reset.Slow/1000,2))
					LV_ModifyCol(2,"AutoHdr")
					LV_ModifyCol(3,"AutoHdr")
					LV_ModifyCol(4,"AutoHdr")
					LV_ModifyCol(5,"AutoHdr")
					GuiControl, +Redraw, IBM_Stats_Run_LV
					if (LogData.Fail) ;Failed runs (i.e. ones that did not reach the reset zone)
					{
						this.Stats.FailRuns++
						this.Stats.FailTotalTime+=totalDuration
					}
					if (this.Stats.StartTime=="") ;First run
					{
						this.Stats.StartTime:=LogData.Start
					}
					totalTime:=LogData.End - this.Stats.StartTime
					GuiControl, IBM_Home:, IBM_Stats_Total_Runs, % this.Stats.TotalRuns . " in " . ROUND(totalTime/1000,2) . "s (" . ROUND(totalTime/3600000,2) . "h)"
					GuiControl, IBM_Home:, IBM_Stats_Fail_Runs, % this.Stats.FailRuns . " for " . ROUND(this.Stats.FailTotalTime/1000,2) . "s"
					silvers:=g_SF.Memory.ReadChestCountByID(1)
					if(silvers!="")
						this.Chests.CurrentSilver:=silvers
					golds:=g_SF.Memory.ReadChestCountByID(2)
					if(golds!="")
						this.Chests.CurrentGold:=golds
					
					Gui, IBM_Home:Default
					Gui, ListView, IBM_Stats_Chests_LV
					GuiControl, -Redraw, IBM_Stats_Chests_LV
					LV_Modify(1,,"Silver",this.Chests.CurrentSilver - this.Stats.Chests.SilverStart + this.Chests.OpenedSilver - this.Chests.PurchasedSilver,this.Chests.PurchasedSilver,this.Chests.OpenedSilver) ; Start + Purchased + Dropped - Opened
					LV_Modify(2,,"Gold",this.Chests.CurrentGold - this.Stats.Chests.GoldStart + this.Chests.OpenedGold - this.Chests.PurchasedGold,this.Chests.PurchasedGold,this.Chests.OpenedGold)
					LV_ModifyCol(2,"AutoHdr")
					LV_ModifyCol(3,"AutoHdr")
					LV_ModifyCol(4,"AutoHdr")
					GuiControl, +Redraw, IBM_Stats_Chests_LV
										
					this.Stats.BossKills+=FLOOR(LogData.LastZone / 5)
					bph:=(this.Stats.BossKills / totalTime) * 3600000
					GuiControl, IBM_Home:, IBM_Stats_BPH, % "BPH: " . RegExReplace(ROUND(bph,2), "\G\d+?(?=(\d{3})+(?:\D|$))", "$0" ",") ;Includes the prefix so it can be properly centered
					gems:=g_SF.Memory.ReadGems()
					if(gems!="")
						this.CurrentGems:=gems
					gemsTotal:=this.CurrentGems - this.Stats.StartGems + this.Chests.PurchasedGold*this.CONSTANT_goldCost + this.Chests.PurchasedSilver*this.CONSTANT_silverCost
					gph:=(gemsTotal / totalTime) * 3600000
					GuiControl, IBM_Home:, IBM_Stats_GPH, % "GPH: " . RegExReplace(ROUND(gph,2), "\G\d+?(?=(\d{3})+(?:\D|$))", "$0" ",") ;Includes the prefix so it can be properly centered				
					GuiControl, IBM_Home:, IBM_Stats_TotalGems, % gemsTotal
					;Track GH status
					if (this.Stats.GHActive!=2) ;If already set to 2 the current value no longer matters; we've seen both states
					{
						if (LogData.GHActive)
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
					gemMulti:=this.Stats.GHActive>0 ? 1.5 : 1 ;Mixed is processed as active
					rawGPB:=gph/bph
					gemBonus:=(rawGPB/CONSTANT_baseGPB)/gemMulti
					GuiControl, IBM_Home:, IBM_Stats_Gem_Bonus, % ROUND((gemBonus-1)*100,1) . "% (" . ROUND(rawGPB/gemMulti,1) . " GPB)" ;Bonus best expressed as a percentage
					silverChestIncome:=bph*CONSTANT_silversPerBoss
					goldChestIncomeDrops:=bph*CONSTANT_goldPerBoss
					goldChestIncomeGems:=gph/this.CONSTANT_goldCost
					BSCIncomeDrops:=silverChestIncome*CONSTANT_BSCPerSilver + goldChestIncomeDrops * CONSTANT_BSCPerGold
					BSCIncomeGems:=goldChestIncomeGems * CONSTANT_BSCPerGold
					BountyIncomeDrops:=((goldChestIncomeDrops * CONSTANT_BountiesPerGold)/CONSTANT_BountiesPerEventPack)*CONSTANT_TotalRewardPerEventPack
					BountyIncomeGems:=((goldChestIncomeGems * CONSTANT_BountiesPerGold)/CONSTANT_BountiesPerEventPack)*CONSTANT_TotalRewardPerEventPack
					GuiControl, IBM_Home:, IBM_Stats_BSC_Reward, % ROUND(BSCIncomeDrops+BSCIncomeGems,1)
					g_IriBrivMaster_GUI.UpdateToolTip("IBM_Stats_BSC_Reward", "Bosses: " . ROUND(BSCIncomeDrops,1) . ", Gems: " . Round(BSCIncomeGems,1))
					GuiControl, IBM_Home:, IBM_Stats_Total_Reward, % ROUND(BSCIncomeDrops+BSCIncomeGems+BountyIncomeDrops+BountyIncomeGems,1)
					g_IriBrivMaster_GUI.UpdateToolTip("IBM_Stats_Total_Reward", "Bosses: " . ROUND(BSCIncomeDrops+BountyIncomeDrops,1) . ", Gems: " . Round(BSCIncomeGems+BountyIncomeGems,1))
					switch this.Stats.GHActive
					{
						case 0: ghStatus:="No"
						case 1: ghStatus:="Yes"
						case 2: ghStatus:="Mixed"
						Default: ghStatus:="-"
					}
					GuiControl, IBM_Home:,IBM_Stats_Gem_Hunter, % ghStatus
					FormatTime, formattedDateTime,,% g_IBM_Settings["IBM_Format_Date_Display"]
					GuiControl, IBM_Home:, IBM_Group_Stats_Timing,% "Run Timings (" . formattedDateTime . ")"
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
  		stacks:=g_Heroes[58].ReadSBStacks()
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
        stacks:=g_Heroes[58].ReadHasteStacks()
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
        GuiControl, IBM_Home:, IBM_Stats_Current_Area_Run_Time, % "Area / Run (s): " . ROUND(areaTime/1000,1) . " / " . Round(runTime/1000,1)
		GuiControl, IBM_Home:, IBM_Stats_Loop, % "Stage: " . this.SharedRunData.LoopString
		GuiControl, IBM_Home:, IBM_Stats_Current_Briv, % "SB / Haste stacks: " . message_SB . " / " . message_Haste
		GuiControl, IBM_Home:, IBM_Stats_Last_Close, % "Last close: " . this.SharedRunData.LastCloseReason
		;Gem farm stats
		GuiControl, IBM_Home:, IBM_Stats_Boss_Hits, % this.SharedRunData.BossesHitThisRun . " / " . this.SharedRunData.TotalBossesHit
        GuiControl, IBM_Home:, IBM_Stats_Rollbacks, % this.SharedRunData.TotalRollBacks
        GuiControl, IBM_Home:, IBM_Stats_Bad_Auto, % this.SharedRunData.BadAutoProgress
	}

	StatsUpdateFastSlow(Stat,statTime) ;Helper for the slow/fast/total stat for each category
	{
		if (!Stat.Slow OR statTime > Stat.Slow)
			Stat.Slow:=statTime
		if (!Stat.Fast OR statTime < Stat.Fast)
			Stat.Fast:=statTime
		Stat.TotalTime+=statTime
		Stat.ValidRuns++
	}

	GameSettingsCheck(change:=false) ;Checks settings but does not change them
	{
		this.NextGameSettingsCheck:=A_TickCount + 3600000 ;Hourly check
		checkTime:="(" . A_Hour . ":" . A_Min . ")"
		if (!this.GameSettingFileLocation)
		{
			this.GetSettingsFileLocation(checkTime)
			if (!this.GameSettingFileLocation) ;We tried and we failed
			{
				g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " Unable to open game settings","TrafficLightBad","")
				return
			}
		}
		profile:=g_IBM_Settings.HUB.IBM_Game_Settings_Option_Profile
		gameSettings:=g_SF.LoadObjectFromAHKJSON(this.GameSettingFileLocation,true)
		changeCount:=0
		changeString:=""
		this.SettingCheck(gameSettings,"TargetFramerate","Framerate",false,changeCount,changeString,change) ;TODO: Just use the CNE names for all the simple ones and loop this?!
		this.SettingCheck(gameSettings,"PercentOfParticlesSpawned","Particles",false,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"resolution_x","HRes",false,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"resolution_y","VRes",false,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"resolution_fullscreen","Fullscreen",true,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"ReduceFramerateWhenNotInFocus","CapFPSinBG",true,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"FormationSaveIncludeFeatsCheck","SaveFeats",true,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"UseConsolePortraits","ConsolePortraits",true,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"ShowAllHeroBoxes","AllHero",true,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"HotKeys","Swap25100",false,changeCount,changeString,change)
		this.SettingCheck(gameSettings,"NarrowHeroBoxes","NarrowHero",true,changeCount,changeString,change) ;Note that all hero boxes need to be visible for the script to work properly, but at higher resolutions this isn't needed to achieve that so it isn't forced
		this.ForcedSettingCheck(gameSettings,"LevelupAmountIndex",3,changeCount,changeString,change) ;Fixed, always 3 (x100 levelling)
		if (changeCount)
		{
			if (change)
			{
				if (this.IsGameClosed())
				{
					g_SF.WriteObjectToAHKJSON(this.GameSettingFileLocation,gameSettings,true)
					g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profile,"Name"] . " aligned with " . (changeCount==1 ? "1 change" : changeCount . " changes"),"TrafficLightGood",changeString)
				}
				else
				{
					MsgBox,48,Briv Master,Game settings cannot be changed whilst Idle Champions is running
					g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profile,"Name"] . " have " . changeCount . (changeCount==1 ? " difference" : " differences"),"TrafficLightNeutral",changeString)
				}

			}
			else
			{
				g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profile,"Name"] . " have " . changeCount . (changeCount==1 ? " difference" : " differences"),"TrafficLightNeutral",changeString)
			}
		}
		else
		{
			g_IriBrivMaster_GUI.GameSettings_Status(checkTime . " IC and " . g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[profile,"Name"] . " match","DefaultText",changeString)
		}
	}

	SettingCheck(gameSettings, CNEName, IBMName,isBoolean, byRef changeCount,byRef changeString,change:=false)
	{
		if (IBMName=="Swap25100") ;Special case for the hotkey swap
		{
			if (g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[g_IBM_Settings.HUB.IBM_Game_Settings_Option_Profile,IBMName]) ;If not using this option we don't care what the user has set them to, so only check in this case
			{
				level25:=gameSettings[CNEName,"hero_level_25"] ;This should be a single-element array ["LeftControl"]
				if !(level25.Count()==1 AND level25[1]=="LeftControl")
				{
					changeCount++
					changeString.=CNEName . ".hero_level_25 - Expected: LeftControl Actual: " . level25[1] . "(" . level25.Count() . " items)`n"
					if (change)
						gameSettings[CNEName,"hero_level_25"]:=["LeftControl"]
				}
				level100:=gameSettings[CNEName,"hero_level_100"] ;This should be a two-element array ["LeftShift","LeftControl"]
				if !(level100.Count()==2 AND ((level100[1]=="LeftShift" AND level100[2]=="LeftControl") OR (level100[1]=="LeftControl" AND level100[2]=="LeftShift"))) ;TODO: Shift,Control is how the game saves it, determine if Control,Shift is actually valid?
				{
					changeCount++
					changeString.=CNEName . ".hero_level_100 - Expected: LeftShift and LeftControl Actual: " . level100[1] . " and " . level100[2] . "(" . level100.Count() . " items)`n"
					if (change)
						gameSettings[CNEName,"hero_level_100"]:=["LeftShift","LeftControl"]
				}
			}
			return
		}
		if (isBoolean)
			targetValue:=g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[g_IBM_Settings.HUB.IBM_Game_Settings_Option_Profile,IBMName]==1 ? "true" : "false"
		else
			targetValue:=g_IBM_Settings.HUB.IBM_Game_Settings_Option_Set[g_IBM_Settings.HUB.IBM_Game_Settings_Option_Profile,IBMName]
		if(gameSettings[CNEName]!=targetValue)
		{
			changeCount++
			changeString.=CNEName . " - Expected: " . targetValue . " Actual: " . gameSettings[CNEName] . "`n"
			if (change)
				gameSettings[CNEName]:=targetValue
		}
	}

	ForcedSettingCheck(gameSettings, CNEName, value, byRef changeCount,byRef changeString,change:=false) ;For settings where we don't give or save an option
	{
		if gameSettings[CNEName]!=value
		{
			changeCount++
			changeString.=CNEName . " - Expected: " . targetValue . " Actual: " . gameSettings[CNEName] . "`n"
			if (change)
				gameSettings[CNEName]:=value
		}
	}

	GetSettingsFileLocation(checkTime)
	{
		settingsFileLoc:=g_IBM_Settings.IBM_Game_Path . "IdleDragons_Data\StreamingAssets\localSettings.json"
		if (FileExist(settingsFileLoc))
		{
			this.GameSettingFileLocation:=settingsFileLoc
		}
		return
	}

	IsGameClosed()
	{
		return !WinExist("ahk_exe " . g_IBM_Settings.IBM_Game_Exe)
	}

	RefreshUserData()
    {
        if(WinExist("ahk_exe " . g_IBM_Settings.IBM_Game_Exe)) ;Only update server when the game is open
        {
            g_SF.Memory.OpenProcessReader()
            g_ServerCall.Update()
			this.ServerCallFailCount:=0 ;Reset
			this.MemoryReadFailCount:=0
			if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
				this.SharedRunData.IBM_ProcessSwap:=false
        }
    }

	ParseRouteImportString(routeString)
	{
		RegExMatch(routeString,"{([A-Za-z0-9-_]+),.*}",routeMatches)
		if (strlen(routeMatches1)>0)
		{
			g_IBM_Settings.IBM_Route_Zones_Jump:=this.ConvertBase64ToBinaryArray(routeMatches1)
			while (g_IBM_Settings.IBM_Route_Zones_Jump.Length() > 50) ;The input will represent a multiple of 6 bits
				g_IBM_Settings.IBM_Route_Zones_Jump.Pop()
			g_IriBrivMaster_GUI.RefreshRouteJumpBoxes()
		}
		RegExMatch(routeString,"{.*,([A-Za-z0-9-_]+)}",routeMatches)
		if (strlen(routeMatches1)>0)
		{
			g_IBM_Settings.IBM_Route_Zones_Stack:=this.ConvertBase64ToBinaryArray(routeMatches1)
			while (g_IBM_Settings.IBM_Route_Zones_Stack.Length() > 50) ;The input will represent a multiple of 6 bits
				g_IBM_Settings.IBM_Route_Zones_Stack.Pop()
			g_IriBrivMaster_GUI.RefreshRouteStackBoxes()
		}
	}

	GetRouteExportString()
	{
		return "{" . this.ConvertBinaryArrayToBase64(g_IBM_Settings.IBM_Route_Zones_Jump) . "," . this.ConvertBinaryArrayToBase64(g_IBM_Settings.IBM_Route_Zones_Stack) . "}"
	}

	ConvertBinaryArrayToBase64(value) ;Converts an array of 0/1 values to base 64. Note this is NOT proper base64url as we've no interest in making it byte compatible. As we have 50 values we'd be 22bits over
	{
		charIndex:=1
		chars:=[]
		;OutputDebug % value.Length() . "`n"
		loop, % value.Length()
		{
			if (!chars.HasKey(charIndex))
				chars[charIndex]:=[]
			chars[charIndex].Push(value[A_Index])
			;OutputDebug % "Loop:" . charIndex . " " . chars[charIndex].Length() . "`n"
			if (chars[charIndex].Length()==6)
				charIndex++
		}
		while (chars[charIndex].Length() < 6) ;Pad the last character to 6 bits, otherwise 11 would convert to dec 3, as would 000011
			chars[charIndex].Push(0)
		accu:=""
		loop, % chars.Length()
		{
			accu.=SubStr(IC_IriBrivMaster_Component.BASE_64_CHARACTERS,this.BinaryArrayToDec(chars[A_INDEX])+1,1) ;1 for 1-index array
		}
		return accu
	}

	BinaryArrayToDec(value)
	{
		charPos:=0
		accu:=0
		while value.Length() >= 1
		{
			accu+=value.Pop()*(2**charPos)
			charPos++
		}
		return accu
	}

	ConvertBase64ToBinaryArray(value) ;Converts a base-64 value to a binary array, limited to the specified size Note this is NOT proper base64url as we've no interest in making it byte compatible. The result will always be a multiple of 6 bits TODO: Should we allow a size limit here (eg IBM_ConvertBase64ToBinaryArray(value,maxsize) )
	{
		length:=StrLen(value)
		accu:=[]
		loop, parse, value
		{
			base:=(InStr(IC_IriBrivMaster_Component.BASE_64_CHARACTERS,A_LoopField,true)-1) ;InStr must be set to case-sensitive
			accu.Push((base & 0x20)>0,(base & 0x10)>0,(base & 0x08)>0,(base & 0x04)>0,(base & 0x02)>0,(base & 0x01)>0)
		}
		return accu
	}

	SetControl_OfflineStacking()
	{
		if (ComObjType(this.SharedRunData,"IID") or this.RefreshComObject())
            this.SharedRunData.UpdateOutbound("IBM_RunControl_DisableOffline",!this.SharedRunData.IBM_RunControl_DisableOffline) ;Toggle
		else
			Msgbox 48, "BrivMaster",Failed to update script ;48 is excamation, +0 for just OK
	}

	SetControl_QueueOffline()
	{
		If (ComObjType(this.SharedRunData,"IID") OR this.RefreshComObject())
			this.SharedRunData.UpdateOutbound("IBM_RunControl_ForceOffline",!this.SharedRunData.IBM_RunControl_ForceOffline) ; Toggle
		else
			Msgbox 48, "BrivMaster",Failed to update script ;48 is excamation, +0 for just OK
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
				this.SharedRunData.IBM_OutboundDirty:=false ;Needs to be reset right away, so updates during processing are not lost
				if (dirty)
				{
					GuiControlGet, activeTab, IBM_Home:, ModronTabControl ;Only MoveDraw if the Briv Master tab is active, to avoid weird bleed-through. Read here once to avoid each function checking it
					brivMasterTabActive:=activeTab=="Home"
					g_IriBrivMaster_GUI.UpdateRunControlDisable(this.SharedRunData.IBM_RunControl_DisableOffline,brivMasterTabActive)
					g_IriBrivMaster_GUI.UpdateRunControlForce(this.SharedRunData.IBM_RunControl_ForceOffline,brivMasterTabActive)
					g_IriBrivMaster_GUI.UpdateRunStatus(this.SharedRunData.IBM_RunControl_CycleString,this.SharedRunData.IBM_RunControl_StatusString,this.SharedRunData.IBM_RunControl_StackString)
				}
				this.UpdateStats(dirty)
				this.ChestSnatcher.Snatch() ;After stats as Stats reads the gem/chest counts on new run start
			}
			catch
			{
				g_IriBrivMaster_GUI.ResetStatusText()
			}
        }
        else
            g_IriBrivMaster_GUI.ResetStatusText()
		if (A_TickCount>=this.NextGameSettingsCheck)
			this.GameSettingsCheck()
    }

	LoadSettings()
    {
        needSave:=false
        template:=this.GetSettingsTemplate() ;Needs in all cases, either to create in full, or for key checks
		g_IBM_Settings:=IC_BrivMaster_SharedFunctions_Class.LoadObjectFromAHKJSON(IC_BrivMaster_SharedData_Class.SettingsPath) ;Cannot use the instance as it might not be set up yet - it needs the exe name from these settings to set up .Memory
        if (!IsObject(g_IBM_Settings)) ;If no settings are read in create a new default set
        {
			g_IBM_Settings:=this.CreateDefaultSettingsFromTemplate(template)
            needSave:=true
        }
        else
        {
			needSave:=this.CheckForExtraSettings(g_IBM_Settings, template) ;Delete extra settings, without removing object-based values for them
            needSave:=this.CheckForMissingSettings(g_IBM_Settings,template) OR needSave ;Add extra settings, along with their default values. Order matters here due to lazy OR
        }
        if (needSave)
            this.SaveSettings()
    }

	CheckForMissingSettings(settings, template) ;Check all elements of settings and remove any that do not exist in template, up to those with _DEFAULT properties
	{
		needSave:=false
		for k,v in template.Clone()
		{
			if(k!="_DEFAULT") ;Do not treat the default values as settings
			{
				if(!settings.HasKey(k))
				{
					if(template[k].HasKey("_DEFAULT")) ;If this setting is a leaf node
						settings[k]:=template[k,"_DEFAULT"]
					else ;An object that will be further added to later
						settings[k]:={}
					needSave:=true
				}
				if(isObject(v))
					 needSave:=this.CheckForMissingSettings(settings[k],v) OR needSave
			}
		}
		return needSave
	}

	CheckForExtraSettings(settings, template) ;Check all elements of settings and remove any that do not exist in template, up to those with _DEFAULT properties
	{
		needSave:=false
		for k,v in settings.Clone()
		{
			if(template.HasKey(k))
			{
				if(!template[k].HasKey("_DEFAULT")) ;Marks a 'leaf' note in the template, following items may be object-based values so we can't delete them
					needSave:=this.CheckForExtraSettings(v,template[k]) OR needSave ;Order matters due to lazy execution
			}
			else
			{
				settings.Delete(k)
				needSave:=true
			}
		}
		return needSave
	}

	CreateDefaultSettingsFromTemplate(template) ;Extracts all values from the _DEFAULT keys, e.g. template.IBM_Setting._DEFAULT:=true becomes template.IBM_Setting:=true. This is done in place
	{
		for k,v in template
		{
			if(IsObject(v))
				this.CreateDefaultSettingsFromTemplate_Recurse(template,k,v)
		}
		return template
	}

	CreateDefaultSettingsFromTemplate_Recurse(parentObj,key,value)
	{
		for k,v in value.Clone()
		{
			if(k=="_DEFAULT") ;Assign the value of the default property to the parent it is attached to
			{
				parentObj[key]:=v ;This overwrites value, so we just return here
				return
			}
			else if(IsObject(v))
			{
				this.CreateDefaultSettingsFromTemplate_Recurse(value,k,v)
			}
		}
	}

    UpdateSetting(setting, value) ;TODO: With no logic around the assignment this seems like a bit of a pointless function
    {
        g_IBM_Settings[setting]:=value
    }

	UpdateRouteSetting(setting,toggleZone)
	{
		g_IBM_Settings[setting][toggleZone]:=!g_IBM_Settings[setting][toggleZone]
	}

	IBM_GetGUIFormationData() ;Generates formation data for the level manager GUI
	{
		if(g_SF.Memory.ReadGameStarted()!=1)
			this.RefreshUserData()
		championData:={} ;This will be per seat, then champID with a list of formations containing, eg championData[1][58] being [1,3,4] if Briv is in Q/E/M but not W
		if (!g_Heroes.Init()) ;Initialise the hero handler, otherwise we won't be able to get champion details - likely if this fails the formation reads would also fail anyway
			return
        slots:=["Q","W","E"]
		loop 3
			this.IBM_GetGUIFormationData_ProcessFormation(championData,slots[A_Index],g_SF.Memory.GetFormationByFavorite(A_Index))
		this.IBM_GetGUIFormationData_ProcessFormation(championData,"M",g_SF.Memory.GetActiveModronFormation())
		listIndex:=1
		for _, seatMembers in championData ;The listIndex has to be assigned after all formations are processed, as they are assigned seat by seat
		{
			for _, champData in seatMembers
			{
				champData["ListIndex"]:=listIndex++
			}
		}
		return championData
	}

	IBM_GetGUIFormationData_ProcessFormation(championData,index,formation) ;TODO: This needs to deal with the seat/name reads failing. Probably via trying to restart the memory reader initially, then giving up and not returning any champs with some kind of feedback message
	{
		for _, heroID in formation
		{
			if heroID>0
			{
				seat:=g_Heroes[heroID].Seat
                if !(championData.hasKey(seat) AND championData[seat].hasKey(heroID)) ;Create entry for this champ
                {
                    championData[seat,heroID,"Name"]:=g_Heroes[heroID].ReadName() ;We need to create the array if it doesn't yet exist
                    championData[seat,heroID,"Q"]:=false
                    championData[seat,heroID,"W"]:=false
                    championData[seat,heroID,"E"]:=false
                    championData[seat,heroID,"M"]:=false
                }
                championData[seat,heroID,index]:=true
			}
		}
	}

	IBM_Elly_StartNonGemFarm()
	{
		g_IBM.GameMaster:={}
		g_IBM.GameMaster.Hwnd:=WinExist("ahk_exe " . g_IBM_Settings["IBM_Game_Exe"])
		exeName:=g_IBM_Settings["IBM_Game_Exe"]
		Process, Exist, %exeName%
		g_SF.PID := ErrorLevel
		g_SF.Memory.OpenProcessReader()
		if (!g_Heroes.Init()) ;Initialise the hero handler, otherwise we won't be able to get Elly's details - would generally mean the game is closed
		{
			g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Unable to read hero details")
			return
		}
		if(IsObject(this.Elly_NonGemFarm)) ;Stop any existing timer
			this.Elly_NonGemFarm.Stop()
		this.Elly_NonGemFarm:=New IC_BrivMaster_EllywickDealer_Class(this.IBM_Elly_GetNonGemFarmCards("Min"),this.IBM_Elly_GetNonGemFarmCards("Max"))
        this.Elly_NonGemFarm.Start()
		g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Started")
    }

    IBM_Elly_StopNonGemFarm()
    {
        this.Elly_NonGemFarm.Stop()
        this.Elly_NonGemFarm:=""
		g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Stopped")
    }

    IBM_Elly_GetNonGemFarmCards(capType:="Min")
    {
        cards:=[]
        Loop 5
        {
            GuiControlGet, cap, IBM_Home:, IBM_NonGemFarm_Elly_%capType%_%A_Index% ;Eg IBM_NonGemFarm_Elly_Min_1
            cards.Push(cap)
        }
        return cards
    }

	RunVersionCheck() ;Main version check wrapper
	{
		this.BasicServerCaller:=new IBM_ServerCall_Class() ;For basic server calls when version checking only - we won't be attached to the farm script / game at start up
		this.VersionCheckBM()
		this.BasicServerCaller:=""
	}

	VersionCheckBM()
    {
		details:=this.GetCurrentBMDetails()
		addonDetails:=this.BasicServerCaller.BasicServerCall(this.ExtractAddonUrl(details[2]))
		comparison:=this.VersionComparison(addonDetails.Version,details[1])
        versionString:="Briv Master: "
		if(comparison.GT)
		{
            versionString.=details[1] . " - New version " . comparison.TestVersion . " available"
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("TrafficLightNeutral")
		}
        else if(comparison.E)
        {
			versionString.=details[1]
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("TrafficLightGood")
		}
		else
        {
			versionString.=details[1] . " - Server has " . comparison.TestVersion
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("SpecialText1") ;Not TrafficLightBad as this isn't necessarily a problem - it's probably me, or you dear reader, working on updates
		}
		GuiControl, IBM_Home:, IBM_Version_Text_SH, %versionString% ;Update UI
		GuiControl, IBM_Home:+%colour%, IBM_Version_Status_SH
		GuiControl, IBM_Home:MoveDraw,IBM_Version_Status_SH ;Required to update the colour as we don't change the text
	}

	GetCurrentBMDetails() ;Returns [version,url] TODO: Should we handle this file being missing?
	{
		details:=g_SF.LoadObjectFromAHKJSON(A_LineFile . "\..\..\IC_BrivMaster.json")
		return [details.Version, details.Url]
	}

	ExtractAddonUrl(url) ;The addon URL will have a format like https://github.com/RLee-EN/BrivMaster/tree/main/IC_BrivMaster_Extra, but directly downloading the file requires https://raw.githubusercontent.com/RLee-EN/BrivMaster/refs/heads/main/IC_BrivMaster_Extra. Returns "" if the URL is not in the expected format
	{
		found:=RegExMatch(url,"O)^https://github.com/(.+)/tree/(.+)$",Matches)
		if(found)
			return "https://raw.githubusercontent.com/" . Matches[1] . "/refs/heads/" . Matches[2] . "/IC_BrivMaster.json"
		else
			return ""
	}

	VersionComparison(versionStringTest,versionStringBase) ;Returns an object with the extracted versions. Version numbers must be the first numbers/periods in the string, comparison is test against base, so VersionComparsion(3,2) is greater than
	{
		result:={}
		result.GT:=false ;Greater than
		result.LT:=false
		result.E:=false
		foundBase:=RegExMatch(versionStringBase,"[\d.]+",versionsBase) ;Extract 1.2.3 etc
		foundTest:=RegExMatch(versionStringTest,"[\d.]+",versionsTest)
		result.BaseVersion:=versionsBase
		result.TestVersion:=versionsTest
		if(foundBase AND foundTest)
		{
			partsBase:=StrSplit(versionsBase,".")
			partsTest:=StrSplit(versionsTest,".")
			loops:=Max(partsBase.Count(),partsTest.Count())
			loop %loops%
			{
				if(A_Index > partsBase.Count()) ;Test must have more elements, as A_Index cannot be greater than loops
				{
					result.GT:=true
					return result
				}
				else if (A_Index > partsTest.Count()) ;Base must have more elements
				{
					result.LT:=true
					return result
				}
				else if (partsTest[A_Index] > partsBase[A_Index])
				{
					result.GT:=true
					return result
				}
				else if (partsTest[A_Index] < partsBase[A_Index])
				{
					result.LT:=true
					return result
				} ;Otherwise we move on to the next element
			}
		}
		else if(foundTest)
		{
			result.GT:=true
			return result ;If test has a value and base does not, it is considered greater
		}
		else if(foundBase)
		{
			result.LT:=false
			return result
		}
		result.E:=true ;Neither valid or both fully equal, so they are the same
		return result
	}

	GetPlatformString() ;Converts a numeric platform ID to a text string, e.g. 11 -> Steam (11)
	{
		platformID:=g_SF.Memory.ReadPlatform()
		if(platformID)
			return this.GetPlatform(platformID)
		else
			return "<Unable to read>"
	}

	GetPlatform(platformID)
	{
		switch platformID
		{
			case 5: return "Kongregate (" . platformID . ")"
			case 6: return "Armor Games (" . platformID . ")"
			case 11: return "Steam (" . platformID . ")"
			case 13: return "Servers (" . platformID . ")"
			case 14: return "Servers (" . platformID . ")"
			case 16: return "Sony (" . platformID . ")"
			case 17: return "Xbox (" . platformID . ")"
			case 18: return "CNE Games (" . platformID . ") - treated as Steam (11)"
			case 20: return "Kartridge (" . platformID . ")"
			case 21: return "EGS (" . platformID . ")" ;Note this is the full 'Epic Games Store' in the client
			Default: return "UNKNOWN (" . platformID . ")"
		}
	}

	GetPlayServerFriendly() ;Finds the ps19.idlechampions.com portion, or returns a descriptive error
	{
		if(g_SF.Memory.ReadGameStarted()!=1)
			this.RefreshUserData()
		webRoot:=g_SF.Memory.ReadWebRoot()
		if(webRoot)
		{
			if(match:=this.ExtractPlayServerFromURL(webRoot))
				return match
			else
				return "Invalid URL. Servercall fallback: " . this.ExtractPlayServerFromURL(g_ServerCall.webRoot, "Invalid")
		}
		else
			return "Invalid memory read. Servercall fallback: " . this.ExtractPlayServerFromURL(g_ServerCall.webRoot, "Invalid")
	}
	
	ExtractPlayServerFromURL(webRoot, failReturn:="")
	{
		if(RegExMatch(webRoot,"ps(lt)?\d+[^/]+",match))
			return match
		else
			return failReturn
	}

	CheckOffsetVersions()
	{
		if(g_SF.Memory.ReadGameStarted()!=1)
			this.RefreshUserData()
		gameMajor:=g_SF.Memory.ReadBaseGameVersion() ;Major version, e.g. 636.3 will return 636
		gameMinor:=g_SF.Memory.IBM_ReadGameVersionMinor() ;If the game is 636.3, return .3, 637 will return empty as it has no minor version
		if(gameMajor)
		{
			gameVersion:=gameMajor . gameMinor
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour()
		}
		else
		{
			gameVersion:="<Not found>"
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("WarningText")
		}
		GuiControl, IBM_Home:+%colour%, IBM_Offsets_Text_Game
		GuiControl, IBM_Home:, IBM_Offsets_Text_Game, % "Game Version: " . gameVersion
		currentPointers:=this.GetPointersVersion()
		GuiControl, IBM_Home:, IBM_Offsets_Text_Pointers_Current,% "Current: " . currentPointers
		currentImports:=g_SF.Memory.GetImportsVersion()
		comparison:=this.VersionComparison(gameVersion,currentImports)
		if(comparison.GT)
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("WarningText")
		else
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour()
		GuiControl, IBM_Home:, IBM_Offsets_Text_Imports_Current,% "Current: " . currentImports
		GuiControl, IBM_Home:+%colour%, IBM_Offsets_Text_Imports_Current%index%
		platformID:=g_SF.Memory.ReadPlatform()
		if(!platformID)
		{
			prompt:="Briv Master was unable to read your platform ID from the game. Please enter one of the following:"
			prompt.="`nSteam or CNE Standalone: 11"
			prompt.="`nEpic Games Store: 21"
			InputBox, platformID , Platform Selection, %prompt%,,,,,,,, 11
			platformID:=Trim(platformID)
			if(ErrorLevel==1 OR (platformID!=11 AND platformID!=21)) ;ErrorLevel of 1 means cancel was pressed
				return
		}
		GuiControl, IBM_Home:, IBM_Offsets_Text_Platform, % "Platform: " . this.GetPlatform(platformID)
		if(platformID==18) ;CNE client should be treated as Steam
			platformID:=11
		remoteURL:=g_IBM_Settings.HUB.IBM_Offsets_URL . "IC_Offsets_Header_P" . platformID . ".csv"
		this.BasicServerCaller:=new IBM_ServerCall_Class() ;For basic server calls when version checking only - we won't be attached to the farm script / game at start up
		offsetHeader:=this.BasicServerCaller.BasicServerCallRaw(remoteURL) ;CSV: Import version, import revision, pointer version, pointer revision
		splitCSV:=StrSplit(offsetHeader,",")
		if(splitCSV.Count()>=4) ;Allowing greater than so other info can be appended
		{
			comparison:=this.VersionComparison(splitCSV[3],currentPointers)
			if(comparison.GT)
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("WarningText")
			else
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour()
			GuiControl, IBM_Home:+%colour%, IBM_Offsets_Text_Pointers_GitHub%index%
			GuiControl, IBM_Home:, IBM_Offsets_Text_Pointers_GitHub, % "GitHub: " . splitCSV[3] . " " . splitCSV[4]
			comparison:=this.VersionComparison(splitCSV[1],currentImports)
			if(comparison.GT)
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("WarningText")
			else
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour()
			GuiControl, IBM_Home:+%colour%, IBM_Offsets_Text_Imports_GitHub%index%
			GuiControl, IBM_Home:, IBM_Offsets_Text_Imports_GitHub, % "GitHub: " . splitCSV[1] . " " . splitCSV[2]

		}
		else
			Msgbox 48, Briv Master, Unable to read offset header ;48 is excamation, +0 for just OK
		this.BasicServerCaller:=""
	}

	DownloadOffsets() ;TODO: Resolve the massive duplication with CheckOffsetVersions()
	{
		if(g_SF.Memory.ReadGameStarted()!=1)
			this.RefreshUserData()
		gameMajor:=g_SF.Memory.ReadBaseGameVersion() ;Major version, e.g. 636.3 will return 636
		gameMinor:=g_SF.Memory.IBM_ReadGameVersionMinor() ;If the game is 636.3, return .3, 637 will return empty as it has no minor version
		gameVersion:=gameMajor ? gameMajor . gameMinor : "<Not found>"
		GuiControl, IBM_Home:, IBM_Offsets_Text_Game, % "Game Version: " . gameVersion
		currentPointers:=this.GetPointersVersion()
		GuiControl, IBM_Home:, IBM_Offsets_Text_Pointers_Current,% "Current: " . currentPointers
		currentImports:=g_SF.Memory.GetImportsVersion()
		comparison:=this.VersionComparison(gameVersion,currentImports)
		if(comparison.GT)
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("WarningText")
		else
			colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour()
		GuiControl, IBM_Home:, IBM_Offsets_Text_Imports_Current,% "Current: " . currentImports
		GuiControl, IBM_Home:+%colour%, IBM_Offsets_Text_Imports_Current%index%
		platformID:=g_SF.Memory.ReadPlatform()
		if(!platformID)
		{
			prompt:="Briv Master was unable to read your platform ID from the game. Please enter one of the following:"
			prompt.="`nSteam: 11"
			prompt.="`nEpic Games Store: 21"
			InputBox, platformID , Platform Selection, %prompt%,,,,,,,, 11
			platformID:=Trim(platformID)
			if(ErrorLevel==1 OR (platformID!=11 AND platformID!=21)) ;ErrorLevel of 1 means cancel was pressed
				return
		}
		GuiControl, IBM_Home:, IBM_Offsets_Text_Platform, % "Platform: " . this.GetPlatform(platformID)
		if (platformID==18) ;CNE client should be treated as Steam
			platformID:=11
		remoteURL:=g_IBM_Settings.HUB.IBM_Offsets_URL . "IC_Offsets_Header_P" . platformID . ".csv"
		this.BasicServerCaller:=new IBM_ServerCall_Class() ;For basic server calls when version checking only - we won't be attached to the farm script / game at start up
		offsetHeader:=this.BasicServerCaller.BasicServerCallRaw(remoteURL) ;CSV: Import version, import revision, pointer version, pointer revision
		splitCSV:=StrSplit(offsetHeader,",")
		if(splitCSV.Count()>=4) ;Allowing greater than so other info can be appended
		{
			comparison:=this.VersionComparison(splitCSV[3],currentPointers)
			if(comparison.GT)
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("WarningText")
			else
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour()
			GuiControl, IBM_Home:, IBM_Offsets_Text_Pointers_GitHub, % "GitHub: " . splitCSV[3] . " " . splitCSV[4]
			GuiControl, IBM_Home:+%colour%, IBM_Offsets_Text_Pointers_GitHub%index%
			comparison:=this.VersionComparison(splitCSV[1],currentImports)
			if(comparison.GT)
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour("WarningText")
			else
				colour:=g_IriBrivMaster_GUI.Theme.GetThemeTextColour()
			GuiControl, IBM_Home:, IBM_Offsets_Text_Imports_GitHub, % "GitHub: " . splitCSV[1] . " " . splitCSV[2]
			GuiControl, IBM_Home:+%colour%, IBM_Offsets_Text_Imports_GitHub%index%
			prompt:="Confirm download of the following:"
			prompt.=g_IBM_Settings.HUB.IBM_Offsets_Lock_Pointers ? "`nPointers preserved" : "`nPointers: " . splitCSV[3] . " " . splitCSV[4]
			prompt.="`nImports: " . splitCSV[1] . " " . splitCSV[2]
			Msgbox 36, Briv Master, %prompt% ;32 is question, 4 is Yes/No
			ifMsgBox Yes
			{
				remoteURL:=g_IBM_Settings.HUB.IBM_Offsets_URL . "IC_Offsets_Data_P" . platformID . ".zlib"
				offsetZlib:=this.BasicServerCaller.BasicServerCallRaw(remoteURL) ;Binary data
				if(offsetZlib)
				{
					zlib:=new IC_BrivMaster_Budget_Zlib_Class ;Currently zlib is only used for offset updates, which should be rare, so create and free an instance just for this
					offsetJSON:=zlib.Inflate(offsetZlib)
					zlib:="" ;Free as above
					offsetData:=AHK_JSON.Load(offsetJSON)
					Splitpath A_LineFile,,scriptDir
					offsetDirectory:=scriptDir . "\Offsets\"
					if !InStr(FileExist(offsetDirectory), "D") ;Create the directory if missing
						FileCreateDir, %offsetDirectory%
					for importFile,importString in offsetData["Imports"]
					{
						dataPath:=offsetDirectory . "IC_" . importFile .  "_Import.ahk"
						FileDelete, %dataPath%
						FileAppend, %importString%, %dataPath%
					}
					dataPath:=offsetDirectory . "IC_Offsets.json"
					if(g_IBM_Settings.HUB.IBM_Offsets_Lock_Pointers) ;In this case we have to load the existing pointer file, update the import versions, and re-output
					{
						FileRead, existingJSON, %dataPath%
						existingData:=AHK_JSON.Load(existingJSON)
						existingData["Import_Version_Major"]:=offsetData["Pointers","Import_Version_Major"]
						existingData["Import_Version_Minor"]:=offsetData["Pointers","Import_Version_Minor"]
						existingData["Import_Revision"]:=offsetData["Pointers","Import_Revision"]
						if(existingData["Platform"]!=offsetData["Pointers","Platform"])
							Msgbox 48, Briv Master, % "Update imports only selected but downloaded platform differs from existing:`nExisting: " . existingData["Platform"] . "`nDownloaded: " . offsetData["Pointers","Platform"] . "`nPlease review"
						existingJSON:=AHK_JSON.Dump(existingData,,"`t") ;This should be formatted as we might need to manually review pointers
						FileDelete, %dataPath%
						FileAppend, %existingJSON%, %dataPath%
					}
					else ;Just output
					{
						offsetJSON:=AHK_JSON.Dump(offsetData["Pointers"],,"`t") ;This should be formatted as we might need to manually review pointers
						FileDelete, %dataPath%
						FileAppend, % offsetJSON, %dataPath%
					}
					prompt:="Download complete. Briv Master Home and the Gem Farm, if running, must be restarted independantly to use the new offsets.`nRestart Home now?"
					Msgbox 36, Briv Master, %prompt% ;32 for question, +4 for Yes/No
					ifMsgBox Yes
					{
						Reload_Clicked()
					}
				}
				else
					Msgbox 48, Briv Master, Unable to read offset data ;48 is excamation, +0 for just OK
			}
		}
		else
			Msgbox 48, Briv Master, Unable to read offset header ;48 is excamation, +0 for just OK
		this.BasicServerCaller:=""
	}

	GetPointersVersion() ;As only used in the hub, no point putting the logic in a shared file
	{
		return g_SF.Memory.Versions.Pointer_Version_Major . g_SF.Memory.Versions.Pointer_Version_Minor . " " . g_SF.Memory.Versions.Pointer_Revision . " " . this.GetPlatform(g_SF.Memory.Versions.Platform)
	}
}

class IC_IriBrivMaster_ChestSnatcher_Class ;A class for managing buying and opening chests and associcated servercalls TODO: This has very weak encapsulation due to using various g_IriBrivMaster variables (chests, fails, etc) directly
{
	__New()
	{
		this.Messages:={}
		this.NextDailyClaimCheck:=A_TickCount+180000 ;Wait 3min before making the first check, to avoid spamming calls whilst testing things
	}

	Snatch() ;Process chest purchase orders
	{
		if (g_IriBrivMaster.SharedRunData.IBM_BuyChests) ;Check daily rewards or Open chests. Note it is assumed that SharedRunData has been checked as valid before calling this function
		{
			if (g_IBM_Settings.HUB.IBM_DailyRewardClaim_Enable AND A_TickCount>=this.NextDailyClaimCheck)
			{
				this.ClaimDailyRewards()
				g_IriBrivMaster_GUI.IBM_ChestsSnatcher_Status_Update()
			}
			else if (g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Gold OR g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Silver)
			{
				this.CheckOpenChests()
			}
			else
				g_IriBrivMaster.SharedRunData.IBM_BuyChests:=0 ;Cancel the order
		}
		else if (g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Buy)
		{
			gems:=g_IriBrivMaster.CurrentGems - g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Gem
			amountG:=Min(Floor(gems / g_IriBrivMaster.CONSTANT_goldCost), g_IriBrivMaster.CONSTANT_serverRateBuy)
			if (amountG>=g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Buy)
			{
				this.AddMessage("Buy","No open order, buying " . amountG . " Gold...")
				this.BuyChests(2, amountG)
				g_IriBrivMaster_GUI.IBM_ChestsSnatcher_Status_Update()
			}
		}
	}

	AddMessage(action,comment)
	{
		message:={}
		FormatTime, formattedTime,, HH:mm:ss
		message["Time"]:=formattedTime
		message["Action"]:=action
		message["Comment"]:=comment
		this.Messages.Push(message)
		if (this.Messages.Count()>20)
			this.Messages.RemoveAt(1)
	}

	StartMessage()
	{
		this.AddMessage("General","Awaiting first order")
	}

	ClaimDailyRewards()
	{
		lastSaveEpoch:=g_SF.Memory.IBM_ReadLastSave() ;Reads in seconds since 01Jan0001
		If (lastSaveEpoch=="")
			return
		lastSave:=this.CNETimeStampToDate(lastSaveEpoch)
		secondsElapsed:=A_NOW
		secondsElapsed-=lastSave,s
		if (secondsElapsed>=2)
			return
		serverString:="&user_id=" . g_SF.Memory.ReadUserID() . "&hash=" . g_SF.Memory.ReadUserHash() . "&instance_id=" . g_SF.Memory.ReadInstanceID() . "&language_id=1&timestamp=0&request_id=0&network_id=" . g_SF.Memory.ReadPlatform() . "&mobile_client_version=" . g_SF.Memory.ReadBaseGameVersion() . "&instance_key=1&offline_v2_build=1&localization_aware=true"
		response:=g_ServerCall.ServerCall("getdailyloginrewards",serverString) ;Check what rewards are available and their claim status
		if (IsObject(response) && response.success)
		{
			dayMask:=1 << (response.daily_login_details.today_index)
			if (response.daily_login_details.premium_active && response.daily_login_details.premium_expire_seconds > 0)
				boostExpiry:=response.daily_login_details.premium_expire_seconds / 86400 ;Convert to days
			standardClaimed:=(response.daily_login_details.rewards_claimed & dayMask) > 0
			premimumClaimed:=(response.daily_login_details.premium_rewards_claimed & dayMask) > 0
			if(standardClaimed AND (premimumClaimed OR !response.daily_login_details.premium_active)) ;standard claimed, and premium either claimed or not active - no need to further claim
			{
				nextClaim_Seconds:=response.daily_login_details.next_claim_seconds
				this.NextDailyClaimCheck:=A_TickCount + MIN(28800000,nextClaim_Seconds * 1000) ;8 hours, or the next reset TODO: What happens when this rolls over?
				this.AddMessage("Claim", (response.daily_login_details.premium_active ? "Standard and premium daily rewards already claimed" : "Standard daily reward already claimed. Premium not active"))
				if (response.daily_login_details.premium_active)
					this.AddMessage("Claim", "Premium daily reward expires in " . Round(boostExpiry,1) . " days") ;Seperate entry simply due to length
				return
			}
			else ;Need to claim
			{
				if (response.daily_login_details.premium_active)
				{
					this.AddMessage("Claim", "Standard reward " . (standardClaimed ? "" : "un") . "claimed and premium reward " . (standardClaimed ? "" : "un") . "claimed")
					this.AddMessage("Claim", "Claiming...")
					this.AddMessage("Claim", "Premium daily reward expires in " . Round(boostExpiry,1) . " days")
				}
				else
				{
					this.AddMessage("Claim", "Standard reward unclaimed and premium reward not active")
					this.AddMessage("Claim", "Claiming...")
				}
			}
		}
		else ;Check failed
		{
			this.AddMessage("Claim", "Failed to check current daily reward status")
			return
		}
		extraParams:="&is_boost=0" . serverString
		response:=g_ServerCall.ServerCall("claimdailyloginreward",extraParams) ;Claim rewards
		if (IsObject(response) AND response.success)
		{
			nextClaim_Seconds:=response.daily_login_details.next_claim_seconds
			if (response.daily_login_details.premium_active) ;TODO: Use the initial check servercall to determine if this is needed? (So we can call ONLY the premium if it's the only one outstanding)
			{
				extraParams:="&is_boost=1" . serverString
				response:=g_ServerCall.ServerCall("claimdailyloginreward",extraParams)
				if (IsObject(response) AND response.success)
				{
					nextClaim_Seconds:=response.daily_login_details.next_claim_seconds
					this.AddMessage("Claim", "Claimed standard and premium daily rewards")
				}
				else ;Standard worked, premium failed despite being available?
					this.AddMessage("Claim", "Claimed standard daily reward and failed to claim available premium reward")
			}
			else
			{
				this.AddMessage("Claim", "Claimed standard daily reward")
			}
			if (!nextClaim_Seconds) ;If we somehow didn't get a value for the next time (despite success on the call), wait 5min before calling again
				nextClaim_Seconds:=300
			this.NextDailyClaimCheck:=A_TickCount + MIN(28800000,nextClaim_Seconds * 1000) ;8 hours, or the next reset TODO: What happens when this rolls over?
		}
		else
		{
			this.NextDailyClaimCheck:=A_TickCount + 60000 ;Wait 1min before trying again
			this.AddMessage("Claim","Failed to claim daily rewards")
			g_IriBrivMaster.ServerCallFailCount++
		}
	}

	BuyChests(chestID:=1, numChests:=100)
    {
		if(numChests > 0)
		{
			callTime:=A_TickCount
			response:=g_ServerCall.CallBuyChests(chestID, numChests)
			serverCallTime:=A_TickCount-callTime
			if(response.okay AND response.success)
			{
				if(chestID==1)
				{
					g_IriBrivMaster.Chests.PurchasedSilver+=numChests
					g_IriBrivMaster.Chests.CurrentSilver:=response.chest_count
					this.AddMessage("Buy","Bought " . numChests " Silver in " . serverCallTime . "ms")
				}
				else if (chestID==2)
				{
					g_IriBrivMaster.Chests.PurchasedGold+=numChests
					g_IriBrivMaster.Chests.CurrentGold:=response.chest_count
					this.AddMessage("Buy","Bought " . numChests " Gold in " . serverCallTime . "ms")
				}
				g_IriBrivMaster.CurrentGems:=response.currency_remaining
			}
			else
			{
				this.AddMessage("Buy","Chest purchase failed")
				g_IriBrivMaster.ServerCallFailCount++
			}
		}
    }

	CheckOpenChests()
	{
		lastSaveEpoch:=g_SF.Memory.IBM_ReadLastSave() ;Reads in seconds since 01Jan0001
		If (lastSaveEpoch=="")
			return
		lastSave:=this.CNETimeStampToDate(lastSaveEpoch)
		secondsElapsed:=A_NOW
		secondsElapsed-=lastSave,s
		if (secondsElapsed>=2)
			return
		g_IriBrivMaster.SharedRunData.IBM_BuyChests:=false ;Prevent repeats in the same run
		if (g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Gold AND g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Gold + g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Gold <= g_IriBrivMaster.Chests.CurrentGold)
		{
			this.OpenChests(2,g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Gold)
		}
		else if (g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Silver AND g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Silver + g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Min_Silver <= g_IriBrivMaster.Chests.CurrentSilver)
		{
			this.OpenChests(1,g_IBM_Settings.HUB.IBM_ChestSnatcher_Options_Open_Silver)
		}
		else
			this.AddMessage("Open","Not enough chests to process open order")
		g_IriBrivMaster_GUI.IBM_ChestsSnatcher_Status_Update()
	}

	CNETimeStampToDate(timeStamp) ;Takes a timestamp in seconds-since-day-0 format and converts it to a date for AHK use TODO: There might be a case for making this a more general function
	{
		unixTime:=timeStamp-62135596800 ;Difference between day 1 (01Jan0001) and unix time (AHK doesn't support dates before 1601 so we can't just set converted:=1)
		converted:=1970
		converted+=unixTime,s
		return converted
	}

	OpenChests(chestID:=1,numChests:=250)
    {
		chestName:=chestID==2 ? "Gold" : "Silver"
        callTime:=A_TickCount
		this.AddMessage("Open","Opening " . numChests . " " . chestName . "...")
		chestResults:=g_ServerCall.CallOpenChests(chestID, numChests)
		serverCallTime:=A_TickCount-callTime
        if (!chestResults.success)
		{
			if (!chestResults.failure_reason)
			{
				this.AddMessage("Open","Failed attempting to open " . numChests . " " . chestName " - no reason reported")
				g_IriBrivMaster.ServerCallFailCount++
			}
			else if (chestResults.failure_reason=="Outdated instance id")
			{
				this.AddMessage("Open","Failed attempting to open " . numChests . " " . chestName " - Old ID - Refreshing")
				g_IriBrivMaster.RefreshUserData()
			}
			else
			{
				this.AddMessage("Open","Failed attempting to open " . numChests . " " . chestName " - " . chestResults.failure_reason)
				g_IriBrivMaster.ServerCallFailCount++
			}
			return
		}
 		if (chestID==1)
		{
			g_IriBrivMaster.Chests.OpenedSilver+=numChests
			g_IriBrivMaster.Chests.CurrentSilver:=chestResults.chests_remaining
			this.AddMessage("Open","Opened " . numChests " Silver in " . serverCallTime . "ms")

		}
		else if (chestID==2)
		{
			g_IriBrivMaster.Chests.OpenedGold+=numChests
		    g_IriBrivMaster.Chests.CurrentGold:=chestResults.chests_remaining
			this.AddMessage("Open","Opened " . numChests " Gold in " . serverCallTime . "ms")
		}
    }
}

class IC_BrivMaster_EllywickDealer_Class ;A class for re-rolling Ellywick outside of gem farming
{
    __New(minCards,maxCards)
	{
		this.CasinoTimer:=ObjBindMethod(this, "Casino")
		this.Redraws:=0
		this.UsedUlt:=false ;Tracks Elly's ult being in progress, as her cards are only cleared when it ENDS, despite the visual
		this.minCards:=minCards ;These are arrays indexed by card type, so 1 is Knight, 2 Moon, 3 Gem, 4 Fates, 5 Flames
		this.maxCards:=maxCards
		g_Heroes[83].Reset() ;Reset Elly to clear any previous handlers. This will also create the hero object if necessary
		g_Heroes[99].Reset() ;And DM
	}

	Start()
	{
		timerFunction:=this.CasinoTimer
		SetTimer, %timerFunction%, 100, 0
		g_Heroes[83].InitDoMTHandler() ;.Reset() is called by the constructor, and we create a new object every run (for some reason)
		this.Casino()
	}

	Stop()
	{
		timerFunction:=this.CasinoTimer
		SetTimer, %timerFunction%, Off
	}

	Casino()
	{
		if (g_Heroes[83].EFFECT_HANDLER_CARDS=="") ;Check the effect handler has been set up
		{
			g_Heroes[83].InitDoMTHandler()
			return ;Re-check on next timer tick
		}
		if (g_SF.Memory.ReadResetting() OR g_SF.Memory.ReadCurrentZone()=="")
			return
		if (this.UsedUlt AND !g_Heroes[83].ReadEllywickUltimateActive()) ;Check for completed ultimate
			this.UsedUlt:=false
		remaining:=this.GetRemainingCardsToDraw()
		withinMax:=this.CheckWithinMax()
		if (remaining==0 AND g_Heroes[83].ReadNumCards()==5 AND withinMax) ;We're done
		{
			g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Complete after " . this.Redraws . " redraws")
			this.Stop()
		}
		else if ((5-g_Heroes[83].ReadNumCards()) < remaining or !withinMax) ;Need to re-roll
		{
			if (g_Heroes[83].CanUseUltimate() AND !this.UsedUlt)
			{
				g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Using Ellywick's ultimate")
				this.UseEllywickUlt()
			}
			else if (g_Heroes[99].CanUseUltimate())
			{
				this.UseDMUlt()
				g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Using DM's ultimate")
			}
			else
				g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Waiting for ultimate")
		}
		else
			g_IriBrivMaster_GUI.SetEllyNonGemFarmStatus("Drawing Cards")
	}

	GetRemainingCardsToDraw() ;Check the minimums to determine if we need to draw more
	{
		num:=0
		for cardType, numCards in this.minCards
		   num+=Max(0, numCards - g_Heroes[83].GetNumCardsOfType(cardType))
		return num
	}

	CheckWithinMax() ;Check the maximums have not been exceeded, this is a pass/fail
	{
		for cardType, maxCards in this.maxCards
		{
			if (g_Heroes[83].GetNumCardsOfType(cardType) > maxCards)
				return false
		}
		return true
	}

	UseEllywickUlt()
	{
		if (g_SF.Memory.ReadTransitioning()) ;Do not try using the ults during a transition - possible source of Weird Stuff
			return
		if (g_Heroes[83].CanUseUltimate())
		{
			this.UsedUlt:=true ;Set here to block double presses, until we can confirm it has / hasn't been used
			retryCount:=g_Heroes[83].UseUltimate(50) ;50 'retries' is 5 actual attempts due to the way UseUltimate counts. +1 is a queue wait
			if (retryCount=="" OR retryCount>50) ;Failed to find key, or failed to register
				this.UsedUlt:=false
			else
			{
				this.Redraws++
				this.UseDMUlt()
			}
		}
		else if (g_Heroes[99].CanUseUltimate())
			this.UseDMUlt(0) ;No timeout since Elly's ult is not in progress (this.UsedUlt is false) and has not just been attempted
	}

	UseDMUlt(sleepTime:=30) ;30ms default sleep is for use after Elly's ult triggers, to let the game process it
	{
		if (g_Heroes[99].CanUseUltimate())
		{
			g_IBM.IBM_Sleep(sleepTime)
			g_Heroes[99].UseUltimate(50)
		}
	}
}