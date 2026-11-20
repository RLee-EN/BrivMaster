class IC_BrivMaster_GameMaster_Class ;A class for managing the game process
{
	__New() ;This expects the game to be open and loaded in to the adventure to be farmed
	{
		this.PID:=0
		this.Hwnd:=0
		this.SavedActiveWindow:=0
		exeName:=g_IBM_Settings["IBM_Game_Exe"]
		Process, Exist, %exeName%
		this.PID:=ErrorLevel
		this.Hwnd:=WinExist("ahk_pid " . this.PID)
		Process, Priority, % this.PID, Realtime ;Raises IC's priority. Admin is required for RealTime, but will automatically use High if not elevated
		g_SF.Memory.OpenProcessReader()
		this.CurrentAdventure:=g_SF.Memory.ReadCurrentObjID() ;This might fail, which will be checked in the pre-flight check
		this.KEY_ESC:=g_InputManager.getKey("Esc") ;Used to dismiss the splash screen
		this.OpenTimeout:=CEIL(g_IBM_Settings["IBM_Timeout_Static_Launch"]*1.5) ;75s at default 50s timeout
		this.ProcessWaitingTimeout:=CEIL(g_IBM_Settings["IBM_Timeout_Static_Launch"]*0.3) ;15s at default 50s timeout
		this.OpenProcessTimeout:=CEIL(g_IBM_Settings["IBM_Timeout_Static_Launch"]*0.8) ;40s at default 50s timeout
	}
	
	;-----------------------------------------------------------------------
	;Opening the game
	;-----------------------------------------------------------------------
	
	OpenIC(message:="")
	{
		loadingDone:=false
		g_SharedData.UpdateOutbound("LoopString","Starting Game" . (message ? " " . message : ""))
		g_IBM.Logger.AddMessage("Starting Game" . (message ? " " . message : ""))
		WinGet, savedActive,, A ;Use handle as multiple windows could have the same name
		this.SavedActiveWindow:=savedActive
		StartTime := A_TickCount
		while (!loadingZone AND ElapsedTime < this.OpenTimeout)
		{
			this.Hwnd:=0
			ElapsedTime := A_TickCount - StartTime
			if(ElapsedTime<this.OpenTimeout)
			{
				this.OpenProcessAndSetPID()
				Process, Priority, % this.PID, Realtime
			}
			ElapsedTime:=A_TickCount - StartTime
			if(ElapsedTime < this.OpenTimeout)
				this.SetLastActiveWindowWhileWaitingForGameExe(this.OpenTimeout - ElapsedTime)
			this.ActivateLastWindow()
			g_SF.Memory.OpenProcessReader()
			g_SharedData.UpdateOutbound("IBM_ProcessSwap",true) ;Prompt the hub to update as well
			ElapsedTime:=A_TickCount - StartTime
			if(ElapsedTime < this.OpenTimeout)
				loadingZone:=this.WaitForGameReady() ;NOTE: WaitForGameReady will turn Critical On via WaitForFinalStatUpdates
			if(loadingZone)
				g_ServerCall.Update()
			else
				g_IBM.IBM_Sleep(15) ;Moved this to an Else, otherwise it delays code progression when loading is sucessful
			ElapsedTime:=A_TickCount - StartTime
		}
		if(ElapsedTime>=this.OpenTimeout)
		{
			Critical Off ;Potential edge case where loadingZone was set to true but we ran out time whilst exiting the loop
			return -1 ; took too long to open
		}
		else
		{
			g_IBM.routeMaster.ResetCycleCount() ;Whatever the reason, we've gone offline and therefore don't need to restart the game again
			g_IBM.DialogSwatter.Start()
			return 0
		}
	}
	
	OpenProcessAndSetPID() ;Runs ICs and sets this.PID
	{
		this.PID:=0
		ElapsedTime:=0
		StartTime:=A_TickCount
		while (!this.PID AND ElapsedTime<this.OpenProcessTimeout)
		{
			g_SharedData.UpdateOutbound("LoopString","Opening IC...")
			existingPIDs:=this.GetExistingPIDList() ;Save a list of existing PIDs so we can find the new one the Run command creates TODO: Instead of checking if the Run command is executing the exe directly at run time, work it out once from the name so we don't save this when not needed?
			programLoc:=g_IBM_Settings["IBM_Game_Launch"]
			try
			{
				if (g_IBM_Settings["IBM_Game_Hide_Launcher"])
					Run, %programLoc%,,Hide, openPID
				else
					Run, %programLoc%,,,openPID
			}
			catch
			{
				MsgBox, 48, Unable to launch game, `nVerify the game location is set properly by enabling the Game Location Settings addon, clicking Change Game Location on the Briv Gem Farm tab, and ensuring the launch command is set properly.
				ExitApp
			}
			g_IBM.IBM_Sleep(15)
			processName:=g_SF.GetProcessName(openPID)
			if (processName=g_IBM_Settings["IBM_Game_Exe"]) ;If we launch the game .exe directly (e.g. Steam) the Run PID will be the game, but for things like EGS it will not so we need to find it
			{
				this.PID:=openPID
				g_IBM.Logger.AddMessage("OpenProcessAndSetPID() set PID=[" . this.PID . "] via Run return")
			}
			else
			{
				StartTimePID:=A_TickCount
				ElapsedTimePID:=0
				while(!this.PID AND ElapsedTimePID<this.ProcessWaitingTimeout)
				{
					g_IBM.IBM_Sleep(45)
					this.PID:=this.GetNewPID(existingPIDs)
					ElapsedTimePID:=A_TickCount - StartTimePID
				}
				g_IBM.Logger.AddMessage("OpenProcessAndSetPID() set PID=[" . this.PID . "] via GetNewPID()")
				ElapsedTime:=A_TickCount - StartTime
			}
			if(!this.PID) ;We launched a process (or at least we think we did) but never found it via window. Terminate any IC process not in the existingPIDs list to clean up 
			{
				for gameProcess in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='" . g_IBM_Settings["IBM_Game_Exe"] . "'") ;This seemed to have quite variable performance, but since this is a failure mode anyway being thorough is the older of the day (otherwise we'd be relying on Windows, which might nor might not have been created)
				{
					isNew:=true
					loop % existingPIDs.Count() ;Check each saved PID
					{
						if(existingPIDs[A_Index]==gameProcess.ProcessId)
						{
							isNew:=false
							break
						}
					}
					if(isNew)
					{
						if(this.TerminateProcess(gameProcess.ProcessId))
							g_IBM.Logger.AddMessage("OpenProcessAndSetPID() start fail cleanup killing PID=[" . gameProcess.ProcessId . "]")
						else
							g_IBM.Logger.AddMessage("OpenProcessAndSetPID() start fail cleanup attempted to kill PID=[" . gameProcess.ProcessId . "] but could not find handle")
					}
					else
						g_IBM.Logger.AddMessage("OpenProcessAndSetPID() start fail cleanup ignoring PID=[" . gameProcess.ProcessId . "]")
				}
				if(processName="rare.exe" or processName="legendary.exe") ;Note these are = not == by design. This is to kill launchers that might be queued up trying to launch the game, e.g. due to a connection outage. This is explicitly using these launchers as for normal EGS, OpenPID will be explorer, and we don't want to go killing that
				{
					this.TerminateProcess(openPID)
					g_IBM.Logger.AddMessage("OpenProcessAndSetPID() attempted to terminate launcher [" . processName . "] PID=[" . openPID . "]")
				}
			}
		}
	}
	
	GetExistingPIDList() ;Returns any existing PIDs for the IC Exe, so we can detect a new instance even when things go weird. This uses the windows so might not be 100% accurate
	{
		pidList:=[]
		WinGet, IDList, List, % "ahk_exe " . g_IBM_Settings["IBM_Game_Exe"]
		Loop % IDList
		{
			WinGet, existingPID, PID, % "ahk_id " . IDList%A_Index%
			pidList.Push(existingPID)
		}
		return pidList
	}

	
	GetNewPID(oldPIDList) ;oldPIDList is a list of PIDs to NOT match. Requires the game window to have been created
	{
		WinGet, IDList, List, % "ahk_exe " . g_IBM_Settings["IBM_Game_Exe"]
		Loop % IDList
		{
			WinGet, newPID, PID, % "ahk_id " . IDList%A_Index%
			isNew:=true
			loop % oldPIDList.Count()
			{
				if(oldPIDList[A_Index]==newPID)
				{
					isNew:=false
					break
				}
			}
			if(isNew)
				return newPID
		}
		return 0
	}
	
	SetLastActiveWindowWhileWaitingForGameExe(timeoutLeft:=32000)
	{
		StartTime:=A_TickCount
		while(!(this.Hwnd:=WinExist("ahk_pid " . this.PID)) AND ElapsedTime < timeoutLeft) ;this.PID should be set before calling this function
		{
			WinGet, savedActive,, A ;Use handle as multiple windows could have the same name
			this.SavedActiveWindow:=savedActive
			g_IBM.IBM_Sleep(45)
			ElapsedTime:=A_TickCount - StartTime
		}
		g_IBM.Logger.AddMessage("SetLastActiveWindowWhileWaitingForGameExe() set Hwnd=[" . this.Hwnd . "]")
	}
	
	ActivateLastWindow()
	{
		if (!g_IBM_Settings["IBM_Route_Offline_Restore_Window"])
			return
		g_IBM.IBM_Sleep(80)
		hwnd:=this.Hwnd
		WinActivate, ahk_id %hwnd% ; Idle Champions likes to be activated before it can be deactivated
		savedActive:="ahk_id " . this.SavedActiveWindow
		WinActivate, %savedActive%
	}
	
	WaitForGameReady(skipFinal:=false) ;Waits for the game to be in a ready state. skipFinal is for relay return where we might come back at any point in the offline calculation of the new instance, so waiting for a specific sequence of zone inactive/active/inactive won't necessarily work
	{
		timeout:=g_IBM_Settings["IBM_Timeout_Static_Launch"] ;50s by default
		if (!g_IBM.routeMaster.HybridBlankOffline AND g_IBM.routeMaster.offlineSaveTime>=0) ;If this is set by stack restart
			this.WaitForUserLogin()
		timeoutTimerStart:=A_TickCount
		ElapsedTime:=0
		; wait for game to start
		g_SharedData.UpdateOutbound("LoopString","Waiting for game started...")
		gameStarted:=0 ;This can't check as we need the splash video check to run at least once, due to a bug on recent versions (up to at least 638.2) where the game can get stuck on the splash screen
		lastInput:=-250 ;Input limiter for the escape key presses
		while(ElapsedTime < timeout AND !gameStarted)
		{	
			if (A_TickCount > lastInput+250 AND g_SF.Memory.ReadIsSplashVideoActive())
			{
				this.KEY_ESC.KeyPress() ;.KeyPress() sets critical if necessary
				lastInput:=A_TickCount
				g_IBM.IBM_Sleep(15) ;Short sleep as we've spent time on input already
			}
			else ;Longer sleep if not sending input
				g_IBM.IBM_Sleep(45)
			gameStarted:=g_SF.Memory.ReadGameStarted()
			ElapsedTime:=A_TickCount - timeoutTimerStart
		}
		g_IBM.RefreshImportCheck() ;The game has started so version memory reads should be available
		; check if game has offline progress to calculate
		offlineTime:=g_SF.Memory.ReadOfflineTime()
		if(gameStarted AND offlineTime<=0 AND offlineTime!="")
		{
			return true ; No offline progress to calculate, game started
		}
		; wait for offline progress to finish
		g_SharedData.UpdateOutbound("LoopString","Waiting for offline progress...")
		offlineDone:=g_SF.Memory.ReadOfflineDone()
		if(!offlineDone)
			timeout*=2 ;Increase timeout to ensure offline progress can complete after server issues TODO: Check something else in this loop to make sure the game is actually alive?
		while( ElapsedTime < timeout AND !offlineDone)
		{
			g_IBM.IBM_Sleep(45)
			offlineDone:=g_SF.Memory.ReadOfflineDone()
			ElapsedTime:=A_TickCount - timeoutTimerStart
		}
		if(offlineDone) ;Finished before timeout
		{
			if(!skipFinal)
				this.WaitForFinalStatUpdates()
			g_IBM.StuckChecker.UpdateZoneTime()
			return true
		}
		this.CloseIC("WaitForGameReady-Failed to finish in " . Floor(timeout/1000) . "s")
		return false
	}
	
	WaitForUserLogin() ;Waits for the user platform login, then suspends the IC process until a defined time has past since the game closed
	{
		targetTime:=g_IBM_Settings["IBM_OffLine_Delay_Time"] ;Amount of time we'd like to elapse before passing platform login
		if (g_SF.Memory.IBM_ReadIsGameUserLoaded()!=1 AND (A_TickCount - g_IBM.routeMaster.offlineSaveTime < targetTime))
		{
			g_SharedData.UpdateOutbound("LoopString","Waiting for platform login...")
			ElapsedTime:=A_TickCount - g_IBM.routeMaster.offlineSaveTime
			Critical On ;We need to catch the platform login completing before the game progresses to the userdata request
			while (g_SF.Memory.IBM_ReadIsGameUserLoaded()!=1 AND ElapsedTime < targetTime) ;Wait for user loaded or we run out of time, then stop IC
			{
				Sleep 0 ;Need to be fast to catch this
				ElapsedTime:=A_TickCount - g_IBM.routeMaster.offlineSaveTime
			}
			Critical Off
			ElapsedTime:=A_TickCount - g_IBM.routeMaster.offlineSaveTime
			if (ElapsedTime>=targetTime) ;Don't suspend if we ran out of time waiting
				return
			_IBM_MM.instance.suspend()
			ElapsedTime:=A_TickCount - g_IBM.routeMaster.offlineSaveTime
			While (ElapsedTime<targetTime)
			{
				g_IBM.IBM_Sleep(15)
				ElapsedTime:=A_TickCount - g_IBM.routeMaster.offlineSaveTime
			}
			_IBM_MM.instance.resume()
		}
	}
	
	WaitForFinalStatUpdates() ;Waits until stats are finished updating from offline progress calculations
	{
		g_SharedData.UpdateOutbound("LoopString","Waiting for offline progress (Area Active)...")
		ElapsedTime:=0
		; Starts as 1, turns to 0, back to 1 when active again.
		StartTime := A_TickCount
		while(g_SF.Memory.ReadAreaActive() AND ElapsedTime<5000) ;This was 1736ms, which it seems can be exceeded causing things to go wierd, better to wait here a little longer
		{
			ElapsedTime := A_TickCount - StartTime
			g_IBM.IBM_Sleep(15)
		}
		formationActive:=False
		Critical On ;From here to the zone becoming active timing is important to maximise our chances of getting to the proper formation before something spawns and blocks us. This is not turned off by this function intentionally
		while(!g_SF.Memory.ReadAreaActive() AND ElapsedTime<7000) ;2000ms beyond the initial loop
		{
			if (!formationActive)
			{
				g_IBM.IBM_Sleep(15) ;Only sleep whilst the formation is inactive, we want to react as fast as possible once the area is active
				if (!g_SF.Memory.IBM_IsCurrentFormationEmpty()) ;Once champions start being placed we will try sending input. Was trying to make this mode responsive once the zone becomes available but that seems too early to be useful
				{
					formationActive:=True
				}
			}
			ElapsedTime:=A_TickCount - StartTime
		}
		currentZone:=g_SF.Memory.ReadCurrentZone()
		if(currentZone>1) ;Do not try to change formation if the current zone is either not valid (waste of time) or 1 (where it will override M and cause issues)
			g_IBM.RouteMaster.GetStandardFormationKey(currentZone).KeyPress()
	}
	
	;-----------------------------------------------------------------------
	;Closing the game
	;-----------------------------------------------------------------------
	
	CloseIC(string:="",usePID:=false)
	{
		g_SharedData.UpdateOutbound("LastCloseReason",string)
		g_IBM.Logger.AddMessage("Closing Game" . (string ? " " . string : ""))
		g_ServerCall.Update() ;Check that server call object is updated before closing IC in case any server calls need to be made by the script before the game restarts TODO: Consider the scenarios where this matters that might follow from this function, should just be saving stacks?
		if (string!="")
			string:=": " . string
		g_SharedData.UpdateOutbound("LoopString","Closing IC" . string)
		if (usePID)
			sendMessageString:="ahk_pid " . this.PID
		else
			sendMessageString:="ahk_exe " . g_IBM_Settings["IBM_Game_Exe"]
		timeout:=g_IBM_Settings["IBM_Timeout_Static_Close"] ;Default is 5, so 10s
		if WinExist(sendMessageString)
			SendMessage, 0x112, 0xF060,,, %sendMessageString%,,,, %timeout% ; WinClose
		saveCompleteTime:=-1 ;Unset
		;The memory reads through the usual game instance structure become invalid before the actual saveHandler object is gone, potentially resulting in us detecting a save early and killing the game before it is done - most likely to impact slow systems. Reading the handler directly prevents that
		ADDRESS_DIRTY:=_IBM_MM.instance.getAddressFromOffsets(g_SF.Memory.GameManager.game.gameInstances[0].isDirty.BasePtr.BaseAddress,g_SF.Memory.GameManager.game.gameInstances[0].isDirty.FullOffsets*) 
		TYPE_DIRTY:=g_SF.Memory.GameManager.game.gameInstances[0].isDirty.ValueType
		ADDRESS_CURRENT_SAVE:=_IBM_MM.instance.getAddressFromOffsets(g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.SaveHandler.currentSave.BasePtr.BaseAddress,g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.SaveHandler.currentSave.FullOffsets*)
		TYPE_CURRENT_SAVE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.SaveHandler.currentSave.ValueType
		StartTime:=A_TickCount
		while (WinExist(sendMessageString) AND A_TickCount - StartTime < timeout) ;TODO: In PID mode we could just check process exist, rather than using the window?
		{
			g_IBM.IBM_Sleep(15)
			if (saveCompleteTime==-1 AND saveStatus:=this.CloseIC_SaveCheck(ADDRESS_DIRTY,TYPE_DIRTY,ADDRESS_CURRENT_SAVE,TYPE_CURRENT_SAVE)) ;If saveStatus==2 then the game appears to have closed and we did not confirm the saved actually happened, but there's no value in doing a full wait when there is nothing to check so it is treated the same - either it saved and we missed it, or it won't ever save and there's no point waiting
			{
				saveCompleteTime:=A_TickCount
				g_IBM.Logger.AddMessage("CloseIC() Standard Loop "  . (saveStatus==1 ? "Save" : "Reads Invalid") . " - saveCompleteTime=[" . saveCompleteTime . "] Timeout=[" . A_TickCount - StartTime . "/" . timeout . "]")
				g_IBM.routeMaster.CheckRelayRelease()
				StartTime:=A_TickCount ;Reset timeout after save, there's no longer a reason not to close the game by force in the following loop
				timeout:=500*g_IBM_Settings["IBM_Timeout_Static_Close"] ;Default is 5, so 2.5s
			}
		}
		timeout:=g_IBM_Settings["IBM_Timeout_Static_Close"] ;Reset to standard
		StartTime:=A_TickCount
		NextCloseAttempt:=A_TickCount ;Throttle input whilst continuing to check rapidly for game save and window closure
		while (WinExist(sendMessageString) AND A_TickCount - StartTime < timeout) ; Outright murder
		{
			if (saveCompleteTime==-1 AND saveStatus:=this.CloseIC_SaveCheck(ADDRESS_DIRTY,TYPE_DIRTY,ADDRESS_CURRENT_SAVE,TYPE_CURRENT_SAVE))
			{
				saveCompleteTime:=A_TickCount
				g_IBM.routeMaster.CheckRelayRelease()
				g_IBM.Logger.AddMessage("CloseIC() TerminateProgress Loop " . (saveStatus==1 ? "Save" : "Reads Invalid") . " - saveCompleteTime=[" . saveCompleteTime . "] Timeout=[" . A_TickCount - StartTime . "/" . timeout . "]")
			}
			if (A_TickCount >= NextCloseAttempt) 
			{
				if(this.TerminateProcess(this.PID))
					g_IBM.Logger.AddMessage("CloseIC() failed to close cleanly: sending TerminateProcess saveCompleteTime=[" . saveCompleteTime . "] Timeout=[" . A_TickCount - StartTime . "/" . timeout . "]")
				else
				{
					g_IBM.Logger.AddMessage("CloseIC() failed to close cleanly: failed to get process handle for TerminateProcess saveCompleteTime=[" . saveCompleteTime . "] Timeout=[" . A_TickCount - StartTime . "/" . timeout . "]")
					Break ;If we can't get the handle for the process trying again isn't going to help
				}
				NextCloseAttempt:=A_TickCount+500
			}
			g_IBM.IBM_Sleep(15)
		}
		if (saveCompleteTime==-1) ;Failed to detect, going to have to go with current time
		{
			saveCompleteTime:=A_TickCount
			g_IBM.Logger.AddMessage("CloseIC() fully timed out without detecting a save") ;TODO: This isn't very clear that it could be the window disappearing
		}
		return saveCompleteTime
	}
	
	CloseIC_SaveCheck(ADDRESS_DIRTY,TYPE_DIRTY,ADDRESS_CURRENT_SAVE,TYPE_CURRENT_SAVE) ;Returns 2 if either of memory reads are invalid, 1 if the game is active and has saved and 0 otherwise
	{
		dirty:=_IBM_MM.instance.read(ADDRESS_DIRTY,TYPE_DIRTY)
		currentSave:=_IBM_MM.instance.read(ADDRESS_CURRENT_SAVE,TYPE_CURRENT_SAVE)
		if(dirty=="" OR currentSave=="") ;Memory reads are gone, so game has proceeded to close. This also seems to happen if the relay fails to stop the game and the current copy has the 'Instance invalid' error
			return 2
		else if (dirty==0 AND currentSave==0) ;Save complete. Dirty appears to get set to 0 before the save instance in some cases, so best to check both
			return 1
		return 0
	}
	
	;-----------------------------------------------------------------------
	;General functions
	;-----------------------------------------------------------------------
		
	TerminateProcess(targetPID) ;Returns true if a handle could be acquired and the terminate was sent. Does not check that the process actually exited
	{
		hProcess:=DllCall("Kernel32.dll\OpenProcess", "UInt", 0x0001, "Int", false, "UInt", targetPID, "Ptr")
		if(hProcess)
		{
			DllCall("Kernel32.dll\TerminateProcess", "Ptr", hProcess, "UInt", 0)
			DllCall("Kernel32.dll\CloseHandle", "Ptr", hProcess)
			return true
		}
		return false
	}
	
	SafetyCheck() ;Reopens Idle Champions if it is closed. Calls RecoverFromGameClose after opening IC. Returns true if window still exists.
	{
		if (Not WinExist( "ahk_exe " . g_IBM_Settings["IBM_Game_Exe"]))
		{
			openResult:=this.OpenIC("Called from SafetyCheck()")
			while(openResult==-1) ;OpenIC returns -1 when it times out
			{
				this.CloseIC("Failed to start Idle Champions")
				openResult:=this.OpenIC("Called from SafetyCheck() loop")
			}
			if(g_SF.Memory.ReadResetting() AND g_SF.Memory.ReadCurrentZone() <= 1 AND g_SF.Memory.ReadCurrentObjID() == "")
			{
				g_SharedData.UpdateOutbound("LoopString","Zone is -1. At world map?")
				this.RestartAdventure("At world map?")
			}
			this.RecoverFromGameClose()
			if(g_IBM.currentZone!="")
			{
				returnZone:=g_SF.Memory.ReadCurrentZone()
				if(g_IBM.currentZone>returnZone) ;This allowed 1 zone fallback previously, trying without to minimise the ways we can get stuck
				{
					g_IBM.RollBackAction(returnZone)
				}
				else if (g_IBM.currentZone<returnZone)
				{
					g_SharedData.UpdateOutbound_Increment("BadAutoProgress")
					g_IBM.Logger.AddMessage("Bad autoprogress detected - expected z[" . g_IBM.currentZone . "] return z[" . returnZone . "]")
				}
			}
			return false
		}
		else if (g_SF.Memory.ReadCurrentZone()=="")  ; game loaded but can't read zone? failed to load properly on last load? (Tests if game started without script starting it)
		{
			g_IBM.Logger.AddMessage("SafetyCheck() Resetting process reader - old PID=[" . g_SF.PID . "] and Hwnd=[" . g_SF.Hwnd . "]")
			gameExe:=g_IBM_Settings["IBM_Game_Exe"]
			this.Hwnd := WinExist("ahk_exe " . gameExe)
			Process, Exist, %gameExe% ;TODO: These could potentially return the PID and HWnd of 2 seperate IC processes - need to read one and use that to get the other?
			this.PID := ErrorLevel
			g_SF.Memory.OpenProcessReader()
			g_ServerCall.Update()
			g_IBM.Logger.AddMessage("SafetyCheck() Reset process reader - new PID=[" . g_SF.PID . "] and Hwnd=[" . g_SF.Hwnd . "]")
		}
		return true
	}
	
	RecoverFromGameClose() ;Technically part of opening the game, but called from SafetyCheck not OpenIC()
	{
		StartTime:=A_TickCount
		ElapsedTime:=0
		timeout:=10000 ;TODO: Does this make sense? Should it use the timeout factor?
		currentZone:=g_SF.Memory.ReadCurrentZone()
		if(currentZone==1) ;TODO: What happens if the zone read is invalid, i.e. -1 or ""? The formation lookup will fail...which is probably appropriate
			return
		gameStartFormation:=g_IBM.RouteMaster.GetStandardFormation(currentZone)
		KEY:=g_IBM.RouteMaster.GetStandardFormationKey(currentZone)
		ElapsedTime:=0
		isCurrentFormation:=g_SF.IsCurrentFormation(gameStartFormation)
		while(!isCurrentFormation AND ElapsedTime < timeout AND !g_SF.Memory.ReadNumAttackingMonstersReached())
		{
			KEY.KeyPress() ;Note: Inputs in this function are covered by Critical being turned on previously via WaitForGameReady() calling WaitForFinalStatUpdates()
			g_IBM.IBM_Sleep(15) ;Fast as we do want to mash this to get it in before an enemy spawns
			isCurrentFormation:=g_SF.IsCurrentFormation(gameStartFormation)
			ElapsedTime := A_TickCount - StartTime
		}
		timeout*=2 ;Double the timeout
		while(!isCurrentFormation AND (g_SF.Memory.ReadNumAttackingMonstersReached()) AND (ElapsedTime < timeout))
		{
			ElapsedTime := A_TickCount - StartTime
			g_IBM.RouteMaster.FallBackFromZone()
			KEY.KeyPress()
			g_IBM.RouteMaster.ToggleAutoProgress(1, true)
			isCurrentFormation:=g_SF.IsCurrentFormation(gameStartFormation)
		}
		Critical Off ;Turned On previously via WaitForGameReady() calling WaitForFinalStatUpdates()
		g_SharedData.UpdateOutbound("LoopString","Loading game finished")
	}
	
	RestartAdventure(reason:="",modronFail:=false) ;modronFail is used to indicate if we're restarting due to apparently being stuck at a modron reset. In this case, if the server doesn't respond it's best not to restart, as once the server is back we'll likely load into the run we were on before. This is a parameter to avoid being stuck permanently TODO: Depending on how this ends up working, probably needs breaking into functions for each stage
	{
		g_SharedData.UpdateOutbound("LoopString","ServerCall: Restarting adventure")
		g_IBM.Logger.ForceFail() ;As this can be after we've reached the zone target if the reset got stuck
		g_IBM.Logger.AddMessage("Forced Restart (Reason:" . reason . " at:z" . g_SF.Memory.ReadCurrentZone() . " with haste:" . g_Heroes[58].ReadHasteStacks() . ")")
		this.CloseIC(reason)
		g_SharedData.UpdateOutbound("LoopString","ServerCall: Checking stack conversion") ;This message would ideally be shown only momentarily, but if the server is having issues the servercall will run to timeout and this allows us to see that it is that holding the script up
		if (g_serverCall.ShouldCallPreventStackFail(true)) ;Servercall has been updated by CloseIC()
		{
			response:=g_serverCall.CallPreventStackFail("RestartAdventure()")
			if(response) ;response is an object parsed from the response JSON, which means for debug output we have to turn it back into a string...
				g_IBM.Logger.AddMessage("Stack save response: success=[" . response.success . "] okay=[" . response.okay . "]" . (response.failure_reason ? " failure Reason=[" . response.failure_reason . "]" : ""))
			else if(modronFail) ;If the call return was empty the modron reset probably failed due to server or connection issues. In this case it's quite likely that earlier saves also failed, and if we reconnect without restarting the adventure we'll be able to continue
			{
				g_IBM.Logger.AddMessage("Stack save response: empty and in modron mode - resuming")
				response:=""
				return ;Without setting g_IBM.TriggerStart:=true, as we might not have reset
			}
			else
				g_IBM.Logger.AddMessage("Stack save response: empty and not in modron mode - proceeding to restart adventure")
			g_SharedData.UpdateOutbound("LoopString","ServerCall: Restarting adventure (post stack conversion)")
		}
		else
		{
			g_IBM.Logger.AddMessage("ServerCall Save not required (Haste:" . g_serverCall.sprint . " raw Steelbones:" . g_serverCall.steelbones . ")")
			g_SharedData.UpdateOutbound("LoopString","ServerCall: Restarting adventure (no manual stack conversion)")
		}
		response:=g_ServerCall.CallEndAdventure() ;Note the response to this call does not have an 'okay' property
		if(response)
		{
			if(response.success) ;The EndAdventure call response doesnot have an 'Okay' property
				g_IBM.Logger.AddMessage("End adventure response: success - loading new adventure")
			else
			{
				g_IBM.Logger.AddMessage("End adventure response: failure reason=[" . response.failure_reason . "] - resuming")
				response:=""
				return ;Without setting g_IBM.TriggerStart:=true, as we might not have reset
			}
		}
		else ;If the server didn't return anything from the CallEndAdventure(), it's most likely down or we've lost connectivity, so trying to send the CallLoadAdventure() call is not useful
		{
			g_IBM.Logger.AddMessage("End adventure response: empty - resuming")
			response:=""
			return ;Without setting g_IBM.TriggerStart:=true, as we might not have reset
		}
		attempt:=1
		while(attempt<=3) ;If we're reached this far, we want to try and make sure we get back into an adventure - as we'd restart onto the world map as-is
		{
			callTime:=A_TickCount
			response:=g_ServerCall.CallLoadAdventure(this.CurrentAdventure)
			if(response)
			{
				if(response.success and response.okay)
				{
					g_IBM.Logger.AddMessage("Load adventure response: attempt [" . attempt . "] success and okay - resuming")
					response:=""
					g_IBM.TriggerStart:=true ;As we should now be in a new adventure
					return
				}
				else
					g_IBM.Logger.AddMessage("Load adventure response: attempt [" . attempt . "] success=[" . response.success . "] okay=[" . response.okay . "] failure reason=[" . response.failure_reason . "]")
			}
			else
				g_IBM.Logger.AddMessage("Load adventure response: attempt [" . attempt . "] empty")
			while(A_TickCount < callTime + 20000) ;Normally we'd expect a timeout on the call rather than a bad response, but in case that happens ensure at least 20s have passed TODO: Increasing this a bit might make sense?
			{
				g_IBM.IBM_Sleep(50)
			}
			attempt++
		}
		response:=""
		g_IBM.Logger.AddMessage("Load adventure: out of attempts - probably on world map")
	}
}