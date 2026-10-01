#Requires AutoHotkey 1.1.37+ <1.2
#SingleInstance Force
#NoEnv ; Avoids checking empty variables to see if they are environment variables (recommended for all new scripts). Default behavior for AutoHotkey v2.
SetWorkingDir %A_ScriptDir%
SetWinDelay, 33 ; Sets the delay that will occur after each windowing command, such as WinActivate. (Default is 100)
SetControlDelay, 0 ; Sets the delay that will occur after each control-modifying command. -1 for no delay, 0 for smallest possible delay. The default delay is 20.
SetBatchLines, -1 ; How fast a script will run (affects CPU utilization).(Default setting is 10ms - prevent the script from using any more than 50% of an idle CPU's time.
                  ; This allows scripts to run quickly while still maintaining a high level of cooperation with CPU sensitive tasks such as games and video capture/playback.
ListLines Off
Process, Priority,, High
CoordMode, Mouse, Client

;Based on BrivGemFarm Performance by MikeBaldi and Antilectual, and on various addons created by ImpEGamer. Refer to the Readme.

#include %A_LineFile%\..\IC_BrivMaster_SharedFunctions.ahk ;Indirectly #includes IC_BrivMaster_Memory.ahk
#include %A_LineFile%\..\IC_BrivMaster_Functions.ahk
#include %A_LineFile%\..\IC_BrivMaster_GameMaster.ahk
#include %A_LineFile%\..\IC_BrivMaster_RouteMaster.ahk
#include %A_LineFile%\..\IC_BrivMaster_LevelManager.ahk
#include %A_LineFile%\..\IC_BrivMaster_Heroes.ahk
#include %A_LineFile%\..\..\Lib\IC_BrivMaster_JSON.ahk
#include %A_LineFile%\..\..\Lib\IC_BrivMaster_Zlib.ahk

global g_ServerCall:={} ;Populated by the creation of g_SF below
global g_SF:=New IC_BrivMaster_SharedFunctions_Class ;Includes IBM MemoryFunctions in g_SF.Memory
global g_IBM_Settings:={}
global g_IBM:=New IC_BrivMaster_GemFarm_Class
global g_zlib:=New IC_BrivMaster_Budget_Zlib_Class() ;Created global as it has a lot of one-time setup and we want to avoid re-creating it
global g_IBM_Settings_Addons:={}
global g_Heroes:={} ;Has to be instantiated after memory reads are available
global g_InputManager:=New IC_BrivMaster_InputManager_Class()
global g_SharedData:=New IC_BrivMaster_SharedData_Class

g_SharedData.Init() ;Loads settings so must be prior to the icon set and Window:Show in CreateWindow()
g_IBM.CreateWindow()

if(A_Args[1])
{
    ObjRegisterActive(g_SharedData, A_Args[1])
    g_SF.WriteObjectToAHKJSON(A_LineFile . "\..\LastGUID_IBM_GemFarm.json", A_Args[1])
}
else
{
    GuidCreate:=ComObjCreate("Scriptlet.TypeLib")
    guid:=GuidCreate.Guid
    ObjRegisterActive(g_SharedData, guid)
    g_SF.WriteObjectToAHKJSON(A_LineFile . "\..\LastGUID_IBM_GemFarm.json", guid)
}

g_IBM.GemFarm()

OnExit(ComObjectRevoke())

ComObjectRevoke()
{
    ObjRegisterActive(g_SharedData, "")
    ExitApp
}

IBM_GemFarmGuiClose()
{
    MsgBox, 35, Close, Really close the gem farm script? `n`nWarning: This script is required for gem farming. `n"Yes" will close the gem farm script. `n"No" will minimise the script to the tray.`nYou can open it again by pressing the play button at the top of Briv Master Home.
    IfMsgBox, Yes
        ExitApp
    IfMsgBox, No
        Gui, IBM_GemFarm:Hide
    IfMsgBox, Cancel
        return true
}

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

class IC_BrivMaster_GemFarm_Class
{
	GemFarm()
    {
        static lastResetCount:=0
        this.TriggerStart:=true
        DllCall("QueryPerformanceFrequency", "Int64*", PerformanceCounterFrequency) ;Get the performance counter frequency once as it cannot change
		this.CounterFrequency:=PerformanceCounterFrequency/1000 ;Convert from seconds to milliseconds as that is our main interest
		this.GameMaster:=New IC_BrivMaster_GameMaster_Class() ;This does the initial OpenProcessReader() call
		this.RefreshImportCheck() ;Does the initial population of the import check
		g_ServerCall.Update()
        g_Heroes:=New IC_BrivMaster_Heroes_Class() ;Global to allow consitency between uses in main script and hub (e.g. Ellywick for gold farming). We have to wait with initalising it until memory reads are available, however TODO: More reason for bringing some order to initial startup
		this.Logger:=New IC_BrivMaster_Logger_Class(A_LineFile . "\..\..\Logs\")
		this.LevelManager:=New IC_BrivMaster_LevelManager_Class() ;Must be before the PreFlightCheck() call as we use the formation data the LevelManager loads
		this.RouteMaster:=New IC_BrivMaster_RouteMaster_Class(g_IBM_Settings["IBM_Route_Combine"],this.Logger.logBase)
		if (!this.PreFlightCheck()) ; Did not pass pre flight check.
            return false
		this.offRamp:=false ;Flag when approaching the end of a run for missed-reset detection
		this.EllywickCasino:=New IC_BrivMaster_EllywickCasino_Class()
		this.DialogSwatter:=New IC_BrivMaster_DialogSwatter_Class()
		if (g_IBM_Settings["IBM_Level_Diana_Cheese"]) ;Diana Electrum Chest Cheese things
			this.DianaCheeseHelper:=New IC_BrivMaster_DianaCheese_Class
		g_SharedData.UpdateOutbound("IBM_BuyChests",false)
		this.PreviousZoneStartTime:=A_TickCount ;TODO: These 3 variables are for CheckifStuck, could maybe using encapsulating somewhere else (simple object for it?)
		this.CheckifStuck_lastCheck:=0
        this.CheckifStuck_fallBackTries:=0
		Loop
        {
			this.currentZone:=g_SF.Memory.ReadCurrentZone() ;Class level variable so it can be reset during rollbacks TODO: Move to RouteMaster
			if (this.currentZone=="")
				this.GameMaster.SafetyCheck()
			if(!this.TriggerStart) ;Check for resets outside of the expected
			{
				if(g_SF.Memory.ReadResetsCount()>lastResetCount) ;Modron core reset
				{
					this.TriggerStart:=true
					this.Logger.AddMessage("Missed Reset: Core reset count=[" . g_SF.Memory.ReadResetsCount() . "] lastResetCount=[" . lastResetCount . "]")
				}
				else if(lastResetCount==0 AND this.offRamp AND this.currentZone<=this.RouteMaster.thelloraTarget) ;Additional reset detection for the first run after a manual (forced) restart, as we can't tell run 0 from run 0 if another forced restart happens in that one
				{
					this.TriggerStart:=true
					this.Logger.AddMessage("Missed Reset: Core reset count=0 offramp=true and z[" . this.currentZone . "] is at or before Thellora target z[" . this.RouteMaster.thelloraTarget . "]")
				}
			}
			if (this.TriggerStart) ;First loop
            {
				g_SharedData.UpdateOutbound("IBM_BuyChests",false)
				if (g_SharedData.BossesHitThisRun)
				{
					this.Logger.AddMessage("Bosses:" . g_SharedData.BossesHitThisRun) ;Boss hits from previous run
					g_SharedData.UpdateOutbound("BossesHitThisRun",0)
				}
				this.Logger.NewRun()
				this.currentZone:=this.WaitForZoneLoad(this.currentZone)
				this.RouteMaster.ToggleAutoProgress(g_Heroes[139].inM ? 1 : 0) ;Set initial autoprogess ASAP
				this.offRamp:=false ;TODO: There's a lot of resetting that could probably be wrapped together. Or possibly this whole block carved out
				this.failedConversionMode:=false
                this.levelManager.Reset()
                this.RouteMaster.Reset()
				this.EllywickCasino.Reset()
				this.IBM_FirstZone(this.currentZone)
                lastResetCount:=g_SF.Memory.ReadResetsCount()
				if (!this.RouteMaster.ExpectingGameRestart() OR this.RouteMaster.cycleMax==1) ;When running hybrid don't do standard online chests during offline runs as there will be an early save when closing the game. Without hybrid we don't have a choice
					g_SharedData.UpdateOutbound("IBM_BuyChests",true)
                this.PreviousZoneStartTime:=A_TickCount
				this.TriggerStart:=false
				DllCall("QueryPerformanceCounter", "Int64*", lastLoopEndTime) ;Set for the first loop
				g_SharedData.UpdateOutbound("LoopString","Main Loop")
                this.previousZone:=this.currentZone ;Update these as we may have progressed during first-zone logic. Previous zone is an object variable so it can be reset if a fallback is detected TODO: This should be in the RouteMaster
				this.currentZone:=g_SF.Memory.ReadCurrentZone()
            }
			g_SharedData.UpdateOutbound("LoopString","Main Loop")
			if (g_SF.Memory.ReadResetting())
			{
				this.Logger.ResetReached()
				this.ModronResetCheck()
				Continue ;ModronResetCheck() updates PreviousZoneStartTime in all cases, so the CheckifStuck() call we'd proceed to will never do anything, and the delay is unwanted in this case - we've been waiting on the reset
			}
			else if (this.currentZone<=this.RouteMaster.targetZone) ;If we've passed the reset but the modron has yet to trigger we don't want to spam the game with inputs
			{
				if (!Mod( g_SF.Memory.ReadCurrentZone(), 5 ) AND Mod( g_SF.Memory.ReadHighestZone(), 5 ) AND !g_SF.Memory.ReadTransitioning())
					this.RouteMaster.ToggleAutoProgress( 1, true ) ; Toggle autoprogress to skip boss bag
				if (this.RouteMaster.TestForSteelBonesStackFarming()) ;Returns true on failure case (out of stacks and restarted due to having enough for another run)
					Continue ;Go straight back to the start of the loop
				this.RouteMaster.SetFormation(true) ;This is the only call that uses fastCheck, as it should be whilst just cruising along
				this.RouteMaster.TestForBlankOffline(this.currentZone)
				if (this.currentZone>1)
					this.levelManager.LevelFormation("Q", "min", 0) ;TODO: Should this call on Q? We might be on E and it's technically possible E has champs Q doesn't (although that would be odd). Probably need a union of Q and E
				if(this.currentZone>this.previousZone) ;Things to be done every new zone
				{
					this.Logger.UpdateZone(this.currentZone)
					this.previousZone:=this.currentZone
					this.RouteMaster.InitZone()
					if ((!Mod( g_SF.Memory.ReadCurrentZone(), 5 )) AND (!Mod( g_SF.Memory.ReadHighestZone(), 5)))
					{
						g_SharedData.UpdateOutbound_Increment("TotalBossesHit")
						g_SharedData.UpdateOutbound_Increment("BossesHitThisRun")
						if (g_IBM_Settings["IBM_Level_Recovery_Softcap"] AND !this.failedConversionMode AND this.RouteMaster.NeedToStack() AND g_Heroes[58].ReadHasteStacks() < 50) ;Only check for recovery levelling when we hit a boss
						{
							this.failedConversionMode:=true
							this.levelManager.SetupFailedConversion()
						}
					}
					if (!this.offRamp and this.currentZone>=this.RouteMaster.targetZone - this.RouteMaster.zonesPerJumpQ * 3) ;Set offramp to provide a backup missed-reset check
						this.offRamp:=true
				}
				else
					this.RouteMaster.StartAutoProgressSoft() ;InitZone() will handle this for new zones (which makes it odd it is separate...) TODO: Checking this every single tick seems excessive?
			}
			else
			{
				this.Logger.ResetReached()
				g_SharedData.UpdateOutbound("LoopString","Pending modron reset")
			}
            this.CheckifStuck() ;Does not need to set TriggerStart as any exit that would require it will also call RestartAdventure() which sets it to true
			;Loop frequency check
			this.IBM_SleepOffset(lastLoopEndTime,30)
			DllCall("QueryPerformanceCounter", "Int64*", lastLoopEndTime)
		}
    }

	WaitForZoneLoad(currentZone) ;Waits for a valid zone. Used because force restarts seem to go into the main loop before the game has loaded z1. Note that this doesn't mean that the zone is active (per g_SF.Memory.ReadAreaActive())
	{
		if (currentZone!="") ;TODO: Do we need to check for this being -1 here and in the loop? The zone also becomes 0 during resets
			return currentZone
		endTime:=A_TickCount+2000
		while (currentZone=="" AND A_TickCount<endTime) 
		{
			this.IBM_Sleep(15)
			currentZone:=g_SF.Memory.ReadCurrentZone()
		}
		return currentZone
	}

	IBM_FirstZone(currentZone)
	{
		if (currentZone==1)
		{
			if (g_IBM_Settings["IBM_Level_Diana_Cheese"] AND this.DianaCheeseHelper.InWindow()) ;Diana can give excess chests after the daily reset, as it seems things don't get synced up until a restart. Level her to 200 only in that window
				this.levelManager.OverrideLevelByIDRaiseToMin(148,"min",200)
			if (g_Heroes[139].inM) ;Thellora in M, either combining or non-combining followed by Casino, which proceed in the same way but with Briv's z1c set when not combining
			{
				this.RouteMaster.CheckThelloraBossRecovery() ;Try to avoid rushing into bosses after a failed run by breaking / making the combine. This will set Briv's z1c in the default case for non-combining
				this.EllywickCasino.lockedFrontColumnChamps:=this.LevelManager.SetupFirstZoneFrontRow()
				g_SharedData.UpdateOutbound("LoopString","Start Zone Levelling")
				this.levelManager.LevelFormation("M","z1",,true,,true) ;Level until priority champions hit target only
				this.DoRushWait(true)
				this.RouteMaster.ToggleAutoProgress(0,false,true) ;We may or may not have been stopped by DoRushWait()
				g_SharedData.UpdateOutbound("LoopString","Standard Levelling: M")
				this.levelManager.LevelFormation("M","min") ;Level M to minimum
				this.RouteMaster.UpdateThellora()
				this.levelManager.LevelClickDamage() ;Probably done whilst waiting for Thellora, but not guaranteed
				g_SharedData.UpdateOutbound("LoopString","Ellywick's Casino - Thellora in M")
				unlockRequired:=this.EllywickCasino.Casino()
				g_SharedData.UpdateOutbound("LoopString","Casino Done - Thellora in M")
				if (this.RouteMaster.IsFeatSwap()) ;Swap formation here as we can't be blocked in the transition
				{
					this.RouteMaster.StartAutoProgressSoft() ;Start moving ASAP
					this.RouteMaster.SetFormation(,true) ;Use the highzone on the immediate exit
				}
				else ;For non-feat swap, check if Briv is correctly placed so we do/don't jump out of the waitroom
				{
					brivShouldBeInEConfig:=this.RouteMaster.ShouldWalk(g_SF.Memory.ReadCurrentZone())
					swapAttempts:=0
					Loop
					{
						this.RouteMaster.SetFormation() ;Move to standard formation after waiting for the Casino if necessary
						swapAttempts++
					} until (brivShouldBeInEConfig==g_Heroes[58].ReadBenched() OR swapAttempts>10)
					this.RouteMaster.StartAutoProgressSoft() ;Start moving only once Briv is correctly placed or removed
				}
				if(unlockRequired) ;Moved this out of the IBM_EllywickCasino end logic so it can be done after sending the key presses needed to get moving - there is nothing gained doing it before the next levelling call
					this.EllywickCasino.UnlockHeroes()
				this.levelManager.LevelFormation("Q","min",500) ;Apply min so BBEG->Dyna swap, Tatyana->Hew swap etc happens. Trying 500ms to allow for Hew modifier key levelling to happen
			}
			else ;No Thellora, so Casino in z1
			{
				this.EllywickCasino.lockedFrontColumnChamps:=this.levelManager.SetupFirstZoneFrontRow()
				this.levelManager.LevelFormation("M","z1",,true,,true)
				g_SharedData.UpdateOutbound("LoopString","Ellywick's Casino - No Thellora in M")
				this.levelManager.LevelClickDamage()
				if(this.EllywickCasino.Casino()) ;Moved this out of the IBM_EllywickCasino end logic, for non-combine unlock right away as if the zone is somehow not complete Briv won't be present to get 'free' stacks anyway | TODO: Think about ghost levelling in this case
					this.EllywickCasino.UnlockHeroes()
				g_SharedData.UpdateOutbound("LoopString","Casino Done - No Thellora in M")
				quest:=g_SF.Memory.ReadQuestRemaining() ;Wait for zone completion so we can level Briv - TODO: this should perhaps have a timeout in case things get weird (no familiars in modron formation? Which would mean no gold anyway)
				while(quest>0)
				{
					this.levelManager.LevelWorklist() ;Level existing M worklist whilst waiting
					this.IBM_Sleep(15)
					quest:=g_SF.Memory.ReadQuestRemaining()
				}
				this.levelManager.LevelWorklist(,true) ;Force briv to z1 level (due to z1c he won't have been levelled by the earlier calls)
				;TODO: This will stall without Thellora, or if formation is zerged. Need a cap, and need to actually compare Q/E to what we have
				;It seems this fails due to the ranged fairies Minsc spawns attacking the formation
				swapAttempts:=0
				Loop
				{
					this.RouteMaster.SetFormation() ;Move to z1 formation after waiting for the Casino if necessary
					swapAttempts++
				} until (!g_Heroes[139].ReadBenched() OR (swapAttempts>10)) ;139 is Thellora
				this.levelManager.LevelFormation("Q","min",0) ;One tap of levelling after the change so that BBEG->Dyna swap or such happens
				if (g_Heroes[139].inQ OR g_Heroes[139].inE)
				{
					this.DoRushWait()
					this.RouteMaster.UpdateThellora()
				}
			}
		}
		else ;Not z1
			this.RouteMaster.InitZone() ;Includes levelling click damage to make sure we can move
	}
	
	DoRushWait(stopProgress:=false) ;Wait for Thellora (ID=139) to activate her Rush ability. TODO: unknown what ReadRushTriggered() returns if she starts with 0 stacks or we have 0 favour (with the former being the case that might matter)
    {
        elapsedTime:=0
		levelTypeChampions:=true ;Alternate levelling types to cover both without taking too long in each loop
		g_SharedData.UpdateOutbound("LoopString","Rush Wait")
		startTime:=A_TickCount
		while(!(g_SF.Memory.ReadCurrentZone()>1 OR g_Heroes[139].ReadRushTriggered()) AND elapsedTime < 8000)
        {
			if(stopProgress) ;If we are doing Elly's casino after the rush we need to stop ASAP so that 1 kill doesn't jump us an extra time, possibly on the wrong formation
			{
				if(g_SF.Memory.ReadHighestZone()>1)
				{
					this.RouteMaster.ToggleAutoProgress(0)
					stopProgress:=false ;No need to keep checking
				}
			}
			if (levelTypeChampions)
				this.levelManager.LevelWorklist() ;Level current worklist
			else
				this.levelManager.LevelClickDamage(0) ;Level click damage
            levelTypeChampions:=!levelTypeChampions
			elapsedTime:=A_TickCount-startTime
        }
    }

    CheckifStuck() ;A test if stuck on current area. After 35s, toggles autoprogress every 5s. After 45s, attempts falling back up to 2 times. After 65s, restarts level.
    {
		dtCurrentZoneTime:=A_TickCount - this.PreviousZoneStartTime
		if (dtCurrentZoneTime<=35000) ;Irisiri - added fast exit for the standard case
			return false
        else if (dtCurrentZoneTime>35000 AND dtCurrentZoneTime<=45000 AND dtCurrentZoneTime - this.CheckifStuck_lastCheck > 5000) ; first check - ensuring autoprogress enabled
        {
            this.RouteMaster.ToggleAutoProgress(1, true)
            if(dtCurrentZoneTime < 40000) ;TODO: What purpose does this serve? To avoid interfering with the next check block?
                this.CheckifStuck_lastCheck:=dtCurrentZoneTime
        }
        if (dtCurrentZoneTime>45000 AND this.CheckifStuck_fallBackTries < 3 AND dtCurrentZoneTime - this.CheckifStuck_lastCheck > 15000) ; second check - Fall back to previous zone and try to continue
        {
			; reset memory values in case they missed an update.
            this.GameMaster.Hwnd:=WinExist("ahk_exe " . g_IBM_Settings["IBM_Game_Exe"]) ;TODO: This can screw things up if the there is more than one process open. At least align with .PID?
            g_SF.Memory.OpenProcessReader()
            g_ServerCall.Update()
            this.RouteMaster.FallBackFromZone() ;Try a fall back
            this.RouteMaster.SetFormation() ;In the base script this just goes to Q, which might not be ideal, especially for feat swap
            this.RouteMaster.ToggleAutoProgress(1, true)
            this.CheckifStuck_lastCheck:=dtCurrentZoneTime
            this.CheckifStuck_fallBackTries++
        }
        if (dtCurrentZoneTime>65000)
        {
			this.GameMaster.RestartAdventure("Game is stuck z[" . g_SF.Memory.ReadCurrentZone() . "]" )
            this.GameMaster.SafetyCheck()
            this.PreviousZoneStartTime:=A_TickCount
            this.CheckifStuck_lastCheck:=0
            this.CheckifStuck_fallBackTries:=0
            return true
        }
        return false
    }

	RollBackAction(returnZone) ;Actions to take once a rollback is detected, separate function as needed for normal re-opens and for restarts
	{
		if (this.offramp) ;Not checking the offramp zone here as simply overwriting false with false is almost certainly faster than doing so
				this.offramp:=false ;Reset offramp
		this.Logger.AddMessage("Rollback detected - expected z[" . this.currentZone . "] return z[" . returnZone . "]")
		this.previousZone:=1 ;Otherwise the currentZone > previousZone check will be false until we pass the original zone
		this.currentZone:=returnZone ;Must also be reset, otherwise previousZone will be updated straight to the old current zone
		g_SharedData.UpdateOutbound_Increment("TotalRollBacks")
	}
	
	ModronResetCheck() 	;Waits for modron to reset. Closes IC if it fails.
    {
        if(this.WaitForModronReset(45000)) ;Don't use timeout factor here as this isn't related to host performance
			this.TriggerStart:=true ;For some users the modron core reset count doesn't always increase post reset, despite my PC and tablet both working reliably. It might be a connectivity issue as it appears to be done by the server
		else
        {
            this.GameMaster.RestartAdventure("Modron reset timed out z[" . g_SF.Memory.ReadCurrentZone() . "]",true) ;true flags this as a modron reset restart, where we should try and return to the adventure we're in if the server appears to be down
            this.GameMaster.SafetyCheck()
            this.CheckifStuck_lastCheck:=0 ;This used to be done by passing a 'force' option to CheckifStuck(), which seemed clunky - but we still need to reset these as we are no longer stuck. Or at least we hope not. TODO: Make a stuck-checker object to contain this stuff?
            this.CheckifStuck_fallBackTries:=0
		}
		this.PreviousZoneStartTime:=A_TickCount
    }
	
	WaitForModronReset(timeout:=60000)
    {
        StartTime:=A_TickCount
        ElapsedTime:=0
        g_SharedData.UpdateOutbound("LoopString","Modron Resetting...")
        g_ServerCall.UpdateStackData()
		if(g_serverCall.ShouldCallPreventStackFail()) ;Only try and manually save if it hasn't already happened
			g_serverCall.CallPreventStackFail("WaitForModronReset()",true)
        while (g_SF.Memory.ReadResetting() AND ElapsedTime < timeout)
        {
            this.IBM_Sleep(20)
            ElapsedTime:=A_TickCount - StartTime
        }
        g_SharedData.UpdateOutbound("LoopString", "Loading z1...")
		this.IBM_Sleep(100) ;20ms is not sufficent for this for all users. Was 50ms in BGF, but looks like the loading part of the reset takes >1s in reality, so using 100ms is a safe play without any performance concerns
        while(!g_SF.Memory.ReadUserIsInited() AND g_SF.Memory.ReadCurrentZone()<1 AND ElapsedTime<timeout)
        {
            this.IBM_Sleep(20)
            ElapsedTime:=A_TickCount - StartTime
        }
        if (ElapsedTime>=timeout)
			return false
        return true
    }
	
	IBM_Sleep(sleepTime) ;A more accurate sleep. Relevant for any short sleep (<100ms?)
	{
		DllCall("QueryPerformanceCounter", "Int64*", currentTime)
		targetEndTime:=currentTime+this.CounterFrequency*sleepTime
		while (currentTime < targetEndTime)
		{
			targetTick:=(targetTime - currentTime)//this.CounterFrequency
			if (targetTick<=5) ;With <5ms to go make individual 1ms calls
				tick:=1
			else
				tick:=Min(15,targetTick) ;Make calls of no more than 15ms to ensure timers run etc
			DllCall("Sleep", "UInt", tick)
			DllCall("QueryPerformanceCounter", "Int64*", currentTime)
		}
	}

	IBM_SleepOffset(baseTime,offsetMilliseconds) ;baseTime is in performance counter ticks, acquired from DllCall("QueryPerformanceCounter", "Int64*", var). Use to sleep until a specific time has elapsed from a previous event (rather than the call, per IBM_Sleep)
	{
		targetTime:=baseTime+this.CounterFrequency*offsetMilliseconds
		DllCall("QueryPerformanceCounter", "Int64*", currentTime)
		while (currentTime < targetTime)
		{
			targetTick:=(targetTime - currentTime)//this.CounterFrequency
			if (targetTick <= 5) ;With <5ms to go make individual 1ms calls
				tick:=1
			else
				tick:=Min(15,targetTick) ;Make calls of no more than 15ms to ensure timers run etc
			DllCall("Sleep", "UInt", tick)
			DllCall("QueryPerformanceCounter", "Int64*", currentTime)
		}
	}

	;START PRE-FLIGHT CHECK
    PreFlightCheck() ;TODO: Pack some of this into functions - it's getting a bit large
    {
		;Check for active adventure
		if(this.GameMaster.CurrentAdventure=="" OR this.GameMaster.CurrentAdventure<=0)
		{
			errorMsg:="Unable to read adventure data."
			errorMsg.="`nPlease load into a valid adventure. Current adventure shows as: " . (CurrentObjID ? CurrentObjID : "-- Error --`n")
			errorMsg.=this.PreFlightCheck_GenericMessage()
			this.PreFlightErrorMessage("Adventure",errorMsg)
			return false
		}
		;Check Briv is saved in the expected formations
		brivInM:=g_Heroes[58].inM
        brivInQ:=g_Heroes[58].inQ
		brivInW:=g_Heroes[58].inW
		brivInE:=g_Heroes[58].inE ;Briv should be present in E if and only if we are feat swapping
		if (!brivInM OR !brivInQ OR !brivInW OR (this.RouteMaster.IsFeatSwap() != brivInE))
		{
			errorMsg:="Briv's presence in the saved formations is not as expected:`n"
			errorMsg.="M	Expected: Yes	Saved: " . (brivInM ? "Yes" : "No") . "`n"
			errorMsg.="Q	Expected: Yes	Saved: " . (brivInQ ? "Yes" : "No") . "`n"
			errorMsg.="W	Expected: Yes	Saved: " . (brivInW ? "Yes" : "No") . "`n"
			errorMsg.="E	Expected: " . (this.RouteMaster.IsFeatSwap() ? "Yes (FS)" : "No") . "	Saved: " . (brivInE ? "Yes" : "No") . "`n"
			errorMsg.=this.PreFlightCheck_GenericMessage()
			this.PreFlightErrorMessage("Briv Formations",errorMsg)
			return false
		}
		;Check for Metalborn
		if(!g_Heroes[58].HasCoreSpec(3455))
		{
			errorMsg:="Briv must have the Metalborn specialisation saved in the Modron formation.`n"
			errorMsg.=this.PreFlightCheck_GenericMessage()
			this.PreFlightErrorMessage("Briv Formations",errorMsg)
			return false
		}
		;Check for familiars, M, Q and E should have 3, W always 0
		familiarCountM:=g_SF.Memory.IBM_GetFormationFieldFamiliarCountBySlot(g_SF.Memory.GetActiveModronFormationSaveSlot())
		familiarCountQ:=g_SF.Memory.IBM_GetFormationFieldFamiliarCountBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(1))
		familiarCountW:=g_SF.Memory.IBM_GetFormationFieldFamiliarCountBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(2))
		familiarCountE:=g_SF.Memory.IBM_GetFormationFieldFamiliarCountBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(3))
        if (familiarCountM=="" OR familiarCountQ=="" OR familiarCountW=="" OR familiarCountE=="") ;Check for bad reads
		{
			errorMsg:="Familiars in saved formations could not be checked`n"
			errorMsg.=this.PreFlightCheck_GenericMessage()
			this.PreFlightErrorMessage("Familiars",errorMsg)
			return false
		}
        if (familiarCountM==0 OR familiarCountQ==0 OR familiarCountW>0 OR familiarCountE==0) ;Check for the minimum viable config - failing this check causes an abort
		{
			errorMsg:="Familiars in saved formations are not as expected:`n"
			errorMsg.="M	Expected: 3	Saved: " . familiarCountM . "`n"
			errorMsg.="Q	Expected: 3	Saved: " . familiarCountQ . "`n"
			errorMsg.="W	Expected: 0	Saved: " . familiarCountW . "`n"
			errorMsg.="E	Expected: 3	Saved: " . familiarCountE . " (Feat Swap)`n"
			this.PreFlightErrorMessage("Familiars",errorMsg) ;No generic message because we checked the memory reads for these are working above
			return false
		}
		if (familiarCountM!=3 OR familiarCountQ!=3 OR familiarCountW>0 OR familiarCountE!=3) ;Check for the expected config - the user may choose to proceed in this case
		{
			errorMsg:="Familiars in saved formations are not as expected but do meet the minimum requirements:`n"
			errorMsg.="M	Expected: 3	Saved: " . familiarCountM . "`n"
			errorMsg.="Q	Expected: 3	Saved: " . familiarCountQ . "`n"
			errorMsg.="W	Expected: 0	Saved: " . familiarCountW . "`n"
			errorMsg.="E	Expected: 3	Saved: " . familiarCountE . " (Feat Swap)`n"
			errorMsg.="Do you wish to continue?"
			this.PreFlightErrorMessage("Familiars",errorMsg,32+4) ;32 is Question, 1 is Yes/No
            IfMsgBox, No
				return false
		}
		;Check Modron automation is active
		modronEnabledF:=g_SF.Memory.ReadModronAutoFormation()==1
		modronEnabledR:=g_SF.Memory.ReadModronAutoReset()==1
		modronEnabledB:=g_SF.Memory.ReadModronAutoBuffs()==1
		modronStatusB:=g_IBM_Settings["IBM_Allow_Modron_Buff_Off"] OR modronEnabledB ;Request to allow this for those who don't want to have the modron core use potions, and instead save familiars in the formation. Which is apparently a thing. Not recommended, and the setting is not available in the GUI as a result
		if (!modronEnabledF OR !modronEnabledR OR !modronStatusB) ;If any of the Modron core functions are not set
		{
			errorMsg:="All 3 Mordon Core automation functions must be enabled before starting the gem farm. Current status:`n"
			errorMsg.="Set Formation: " . (modronEnabledF ? "Enabled" : "Disabled") . "`n"
			errorMsg.="Set Area Goal: " . (modronEnabledR ? "Enabled" : "Disabled") . "`n"
			errorMsg.="Set Buffs: " . (modronEnabledB ? "Enabled" : "Disabled") . "`n"
			errorMsg.=this.PreFlightCheck_GenericMessage()
			this.PreFlightErrorMessage("Modron",errorMsg)
			return false
		}
		;Check the Heroes collection has been able to read the heroIndex map
		if (!g_Heroes.Init())
		{
			errorMsg:="Unable to generate HeroID to HeroIndex map`n"
			errorMsg.=this.PreFlightCheck_GenericMessage()
			this.PreFlightErrorMessage("Hero Manager",errorMsg)
			return false
		}
		;Check availability
		gameInstanceID:=g_SF.Memory.IBM_GetActiveGameInstanceID() ;1 to 4, for the four parties
		lockedHeroesString:=""
		locked:=false
		for heroID, _ in this.LevelManager.savedFormationChamps["A"] ;A is a meta-formation that is the union of the other 4 TODO: Should have levelManager return this via a function?
		{
			heroInstanceID:=g_Heroes[heroID].ReadActiveGameInstanceID()
			if(heroInstanceID>0 AND heroInstanceID!=gameInstanceID) ;heroInstanceID of 0 means not assigned to an instance, which is fine
			{
				locked:=true
				lockedHeroesString.=g_Heroes[heroID].ReadName() . " (" . heroID . ") - Party " . heroInstanceID . "`n"
			}
		}
		if (locked)
		{
			errorMsg:="The following champions are configured for Briv Master but are currently active in other adventure parties:`n`n" . lockedHeroesString . "`nEither recall them or end their current adventures"
			this.PreFlightErrorMessage("Hero Manager",errorMsg)
			return false
		}
		;Check Feat Guard
		levelSettings:=g_IBM_Settings["IBM_LevelManager_Levels"] ;Currently the feat data is not being loaded into the hero objects, as it's only relevant to the pre-flight check
		for heroID, _ in this.LevelManager.savedFormationChamps["A"] ;A is a meta-formation that is the union of the other 4 TODO: Should have levelManager return this via a function?
		{
			if(levelSettings.hasKey(heroID) AND levelSettings[heroID].hasKey("Feat_List") AND levelSettings[heroID].hasKey("Feat_Exclusive")) ;Data available
			{
				HERO_FEATS:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.FeatHandler.heroFeatSlots[heroID].List
				size:=HERO_FEATS.size.Read()
				if (size<0 or size>6) ;Allow an expansion of the number of feat slots in the future
				{
					this.PreFlightErrorMessage("Feat Guard","Unable to read equipped feats for heroID: " . heroID . "`n" . this.PreFlightCheck_GenericMessage())
					return false
				}
				extraFeats:={}
				checkList:=levelSettings[heroID,"Feat_List"].Clone() ;A copy is made so that found feats can be removed from it, leaving only those that are missing
				loop, %size%
				{
					id:=HERO_FEATS[A_Index - 1].ID.Read()
					name:=HERO_FEATS[A_Index - 1].Name.Read()
					if(id) ;heroFeatSlots always has the 4 slots
					{
						if (checkList.hasKey(id))
							checklist.Delete(id)
						else if (levelSettings[heroID,"Feat_Exclusive"]) ;In exclusive mode, track extra feats
						{
							extraFeats[id]:=name
						}
					}
				}
				if (checkList.Count()>0 OR extraFeats.Count()>0) ;Any fail
				{
					errorMsg:="Feat Guard found inconsistencies with the equipped feats of " . g_Heroes[heroID].ReadName() . " (" . heroID . ").`n"
					if (checkList.Count()>0)
					{
						errorMsg.="`nNot all of the required feats are present:`n"
						for featID, featName in levelSettings[heroID,"Feat_List"]
						{
							errorMsg.="	" . featName . " (" . featID . ") - " . (checkList.hasKey(featID) ? "Missing" : "Present") . "`n"
						}
					}
					if (extraFeats.Count()>0)
					{
						errorMsg.="`nExclusive mode is enabled and the following extra feats were found:`n"
						for featID, featName in extraFeats
						{
							errorMsg.="	" . featName . " (" . featID . ")`n"
						}
					}
					this.PreFlightErrorMessage("Feat Guard",errorMsg)
					return false
				}
			}
		}
        return true
    }

	PreFlightCheck_GenericMessage() ;Generic error text for PreFlightCheck() errors that might relate to reading from the game
	{
        genericMsg:="`nOther potential solutions:`n"
        genericMsg.="1. Be sure Imports are up to date. Current imports are for: v" . g_SF.Memory.GetImportsVersion() . "`n"
        genericMsg.="2. If IC is running with admin privileges, then the script will also require admin privileges.`n"
        genericMsg.="3. AHK must be 64-bit. (Currently " . (A_PtrSize = 4 ? 32 : 64) . "-bit)"
		return genericMsg
	}

	PreFlightErrorMessage(failingStep,message,options:=16) ;16 is Stop/Error icon, the default of just an OK button (option 0) is used as standard
	{
		title:="Briv Master Startup: " . failingStep
		Msgbox, % options, %title%, %message%
	}
	;END PRE-FLIGHT CHECK

	;GEM FARM WINDOW
	CreateWindow()
	{
		global
		try
		{
			Menu Tray, Icon, %A_LineFile%\..\..\Resources\IBM_Farm.ico
		}
		Gui, IBM_GemFarm:New, -Resize -MaximizeBox
		Gui, IBM_GemFarm:Color, % Format("{:#x}", g_IBM_Settings["IBM_Theme_Current","WindowBackground"])
        Gui, IBM_GemFarm:Font, % "c" . Format("{:#x}", g_IBM_Settings["IBM_Theme_Current","DefaultText"]) . " w400 s8", Microsoft Sans Serif
		FormatTime, formattedDateTime,,% g_IBM_Settings["IBM_Format_Date_Display"]
		Gui IBM_GemFarm:Add, Text, w95 xm+1, % "Gem Farm Started:"
		Gui IBM_GemFarm:Add, Text, w105 x+3, % formattedDateTime
		Gui IBM_GemFarm:Add, Text, w95 xm+1, % "Settings Updated:"
		Gui IBM_GemFarm:Add, Text, w105 x+3 vIBM_GemFarm_Settings_Update_Time, % formattedDateTime
		Gui IBM_GemFarm:Add, Text, w95 xm+1, % "Game Version:"
		Gui IBM_GemFarm:Add, Text, w105 x+3 vIBM_GemFarm_Version_Game, % "Checking..."
		Gui IBM_GemFarm:Add, Text, w95 xm+1, % "Imports Version:"
		Gui IBM_GemFarm:Add, Text, w105 x+3 vIBM_GemFarm_Version_Imports, % "Checking..."
		if(!g_IBM_Settings["IBM_Window_Hide"])
		{
			if(g_IBM_Settings["IBM_Theme_Current","DarkMode"])
			{
				if (A_OSVersion>="10.0.17763" AND SubStr(A_OSVersion, 1, 3)="10.")
				{
					attr:=19
					if (A_OSVersion>="10.0.18985")
						attr:=20
					Gui, IBM_GemFarm: +hwndGuiID
					DllCall("dwmapi\DwmSetWindowAttribute", "ptr", GuiID, "int", attr, "int*", true, "int", 4)
				}
			}
			Gui, IBM_GemFarm:Show,% "x" . g_IBM_Settings["IBM_Window_X"] . " y" . g_IBM_Settings["IBM_Window_Y"], Briv Master
		}
	}

	RefreshGemFarmWindow() ;Updates the time settings were updated
	{
	   FormatTime, formattedDateTime,,% g_IBM_Settings["IBM_Format_Date_Display"]
	   GuiControl, IBM_GemFarm:, IBM_GemFarm_Settings_Update_Time, % formattedDateTime
	}

	RefreshImportCheck()
	{
		gameMajor:=g_SF.Memory.ReadBaseGameVersion() ;Major version, e.g. 636.3 will return 636
		gameMinor:=g_SF.Memory.IBM_ReadGameVersionMinor() ;If the game is 636.3, return .3, 637 will return empty as it has no minor version
		importsMajor:=g_SF.Memory.Versions.Import_Version_Major
		importsMinor:=g_SF.Memory.Versions.Import_Version_Minor
		colour:="c" . Format("{:#x}", g_IBM_Settings["IBM_Theme_Current","TrafficLightBad"])
		if (gameMajor!="" AND importsMajor!="") ;If both major versions are populated
		{
			if (gameMajor==importsMajor AND gameMinor==importsMinor) ;Full matching
				colour:="c" . Format("{:#x}", g_IBM_Settings["IBM_Theme_Current","DefaultText"])
			else if (gameMajor==importsMajor) ;In this case the minor versions necessarily do not match
				colour:="c" . Format("{:#x}", g_IBM_Settings["IBM_Theme_Current","TrafficLightNeutral"])
		}
		gameString:=gameMajor ? (gameMajor . (gameMinor ? gameMinor : "")) : "Unable to detect"
		importString:=importsMajor ? (importsMajor . (importsMinor ? importsMinor : "") . " " . g_SF.Memory.Versions.Import_Revision) : "Unable to detect"
		GuiControl, IBM_GemFarm:+%colour%, IBM_GemFarm_Version_Game
		GuiControl, IBM_GemFarm:+%colour%, IBM_GemFarm_Version_Imports
		GuiControl, IBM_GemFarm:, IBM_GemFarm_Version_Game, % gameString
		GuiControl, IBM_GemFarm:, IBM_GemFarm_Version_Imports, % importString
	}
	;END GEM FARM WINDOW
}

/*
    ObjRegisterActive(Object, CLSID, Flags:=0)
    
        Registers an object as the active object for a given class ID.
        Requires AutoHotkey v1.1.17+; may crash earlier versions.
    
    Object:
            Any AutoHotkey object.
    CLSID:
            A GUID or ProgID of your own making.
            Pass an empty string to revoke (unregister) the object.
    Flags:
            One of the following values:
              0 (ACTIVEOBJECT_STRONG)
              1 (ACTIVEOBJECT_WEAK)
            Defaults to 0.
    
    Related:
        http://goo.gl/KJS4Dp - RegisterActiveObject
        http://goo.gl/no6XAS - ProgID
        http://goo.gl/obfmDc - CreateGUID()
*/
ObjRegisterActive(Object, CLSID, Flags:=0) ;TODO: This should not be floating around at the end of this file
{
    static cookieJar:={}
    if (!CLSID)
	{
        if (cookie:=cookieJar.Remove(Object))!=""
            DllCall("oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0)
        return
    }
    if cookieJar[Object]
        throw Exception("Object is already registered", -1)
    VarSetCapacity(_clsid, 16, 0)
    if (hr:=DllCall("ole32\CLSIDFromString", "wstr", CLSID, "ptr", &_clsid))<0
        throw Exception("Invalid CLSID", -1, CLSID)
    hr:=DllCall("oleaut32\RegisterActiveObject"
        , "ptr", &Object, "ptr", &_clsid, "uint", Flags, "uint*", cookie
        , "uint")
    if hr<0
        throw Exception(format("Error 0x{:x}", hr), -1)
    cookieJar[Object]:=cookie
}