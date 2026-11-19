#SingleInstance Force
#NoEnv ; Avoids checking empty variables to see if they are environment variables (recommended for all new scripts). Default behavior for AutoHotkey v2.
SetWorkingDir %A_ScriptDir%
SetWinDelay, 33 ; Sets the delay that will occur after each windowing command, such as WinActivate. (Default is 100)
SetControlDelay, 0 ; Sets the delay that will occur after each control-modifying command. -1 for no delay, 0 for smallest possible delay. The default delay is 20.
SetBatchLines, -1 ; How fast a script will run (affects CPU utilization).(Default setting is 10ms - prevent the script from using any more than 50% of an idle CPU's time, This allows scripts to run quickly while still maintaining a high level of cooperation with CPU sensitive tasks such as games and video capture/playback.
ListLines Off
Process, Priority,, Realtime

#include %A_LineFile%\..\IC_BrivMaster_Memory_Reader.ahk ;Memory reader

Relay:=new IC_BrivMaster_Relay_Class(A_Args[1]) ;Must be called with the relay COM object GUID as an argument
Relay.RunRelay()
ExitApp

	/*
	States:
		0: Not running
		1: Main script has launched Relay
		2: Connected (Relay has accessed COM object)
		3: Game started
		4: Game started and Relay ended before platform login
		5: Game held after platform login
		6: Complete (any outcome) - not set by this helper script
		-1: Failed to launch
		-2: Failed to suspend (game will have started, current instance will be invalid)
	*/

class IC_BrivMaster_Relay_Class
{
	__New(GUID)
	{
		this.LogString:=A_Tickcount . ",Creating Relay`n"
		if (GUID)
		{
			this.GUID:=GUID
			this.LogString.=A_Tickcount . ",Called with GUI=[" . GUID . "]`n"
			try
			{
				this.RelayData:=ComObjActive(this.GUID)
				this.MainPID:=this.RelayData.MainPID ;TODO: passing one-off items as Args on launch might be better than COM - particularly the offsets array
				this.MainHwnd:=this.RelayData.MainHwnd
				this.MEMORY_baseAddress:=this.RelayData.MEMORY_baseAddress ;TODO: Actually the module offset now. Change this name...
				this.MEMORY_LOADED_Type:=this.RelayData.MEMORY_LOADED_Type
				this.MEMORY_LOADED_Offsets:=[]
				for k,_ in this.RelayData.MEMORY_LOADED_Offsets
				{
					this.MEMORY_LOADED_Offsets.Push(k)
				}
				this.LaunchCommand:=this.RelayData.LaunchCommand
				this.HideLauncher:=this.RelayData.HideLauncher
				this.ExeName:=this.RelayData.ExeName
				this.RestoreWindow:=this.RelayData.RestoreWindow
				this.LogFile:=this.RelayData.LogFile
				this.RelayData.State:=2 ;Connected
				this.ForceRelease:=false
			}
			catch
			{
				FormatTime, formattedDateTime,, yyyyMMddTHHmmss ;Can't include : in a filename so using the less human friendly version here
				this.LogFile:=A_LineFile . "\..\RelayFail_" . formattedDateTime . ".csv" ;Create a log for the fail
				FileAppend, % A_TickCount . " Failed to connect to Relay Data COM object`n", % this.LogFile ;Save
				ExitApp
			}
		}
		else
		{
			FormatTime, formattedDateTime,, yyyyMMddTHHmmss ;Can't include : in a filename so using the less human friendly version here
			this.LogFile:=A_LineFile . "\..\RelayFail_" . formattedDateTime . ".csv" ;Create a log for the fail
			FileAppend, % A_TickCount . " Relay launched without Relay Data COM object GUID`n", % this.LogFile ;Save
			ExitApp
		}
	}

	RunRelay()
	{
		this.LogString.=A_Tickcount . ",Starting Game(Relay)`n"
		WinGet, savedActive,, A ;Why is this here? It's taken later - I guess it's just incase we pick up the HWnd instantly
		this.SavedActiveWindow:=savedActive
		this.PID:=0
		this.Hwnd:=0
		this.Stage:=0
		maxTime:=A_TickCount + 50000 ;TODO: Should consider the timeout factor for some stages, i.e. probably a+b*factor
		lastStage:=6
		lastStartStage:=5 ;Last stage of starting the game up, prior to waiting for the .Loaded
		nextReleaseCheck:=0
		while (this.Stage<=lastStage AND A_TickCount<=maxTime)
		{
			;FileAppend, % A_TickCount . " RunRelay() while loop start`n", % this.Relay_LogFile
			if (A_TickCount > nextReleaseCheck) ;Throttle to avoid spamming the COM object
			{
				try
				{
					if (this.RelayData.RequestRelease) ;TODO: Will block this relay script if the main script is in a Critical block. Probably needs to be it's own COM object controlled by the relay, so the main script can command the release?
						this.ForceRelease:=true
					nextReleaseCheck:=A_TickCount + 200
				}
			}
			switch this.Stage
			{
				Case -2: this.CleanUpOverlap()
				Case -1: this.CleanUpOnFailedStart()
				Case 0: this.OpenProcess()
				Case 1: this.SetPID(10000) ;For no apparent reason this usually takes a few hundred ms, but can take an extra 5000 now and then
				Case 2: this.SetProcessToRealTime()
				Case 3: this.SetLastActiveWindowWhileWaitingForGameExe(15000) ;Timeout has to be quite high as we might skip the SetPID stage if Run in OpenProcess() returns the PID TODO: Pass the timeout factor to the helper script and use it for the timers that are impacted by host performance?
				Case 4: this.ActivateLastWindow()
				Case 5: this.OpenProcessReader(5000)
				Case 6: this.WaitForUserLogin(30000) ;Waits for platform login. TODO: Timeout factor should apply here
				Default:
						this.LogString.=A_Tickcount . ",RunRelay() invalid Stage:[" . this.Stage . "]`n"
			}
			if (this.Stage<6) ;Modest sleeps whilst working through initial stages, but waiting for user login requires us to sample as fast as possible
				sleep 60
			else
				sleep 0 ;TODO: We should only move to 0ms once the Loaded state reads 0 (instead of nothing)
		}
		if (this.Stage<=lastStage)
		{
			this.LogString.=A_Tickcount . ",RunRelay() timed out whilst still at stage=[" . this.Stage . "]`n"
			if (this.Stage>lastStartStage)
			{
				this.UpdateState(-2)
				this.CleanUpOverlap() ;Must call directly as the loop is done
			}
			else
			{
				this.UpdateState(-1)
				this.CleanUpOnFailedStart() ;Must call directly as the loop is done
			}
		}
		this.ExitRelay()
	}
	
	ExitRelay(comment:="Standard")
	{
		this.LogString.=A_Tickcount . ",Relay Exit: " . comment . "`n"
		FileAppend, % this.LogString . "`n", % this.LogFile ;Save the log
		ExitApp 
	}

	UpdateState(state)
	{
		try
		{
			this.RelayData.State:=state
		}
		catch
		{
			this.LogString.=A_Tickcount . ",UpdateState() failed to update script status to [" . state . "]`n"
		}
	}

	CleanUpOverlap()
	{
		this.LogString.=A_Tickcount . ",CleanUpOverlap() called`n"
		this.UpdateState(-2)
		this.RelayData.RelayCloseMain()
		this.Stage:=-3
		this.ExitRelay("CleanUpOverlap()") ;Exit, nothing further we can do here
	}

	CleanUpOnFailedStart() ;Do what we can to clean up if the Relay start-up fails
	{
		this.LogString.=A_Tickcount . ",CleanUpOnFailedStart() called`n"
		if(this.PID) ;If we have a PID, try to kill that window. This goes straight for the nuke, as we shouldn't normally end up in this scenario
		{
			if WinExist( "ahk_pid " . this.PID )
			{
				hProcess := DllCall("Kernel32.dll\OpenProcess", "UInt", 0x0001, "Int", false, "UInt", g_SF.PID, "Ptr")
				if(hProcess)
				{
					DllCall("Kernel32.dll\TerminateProcess", "Ptr", hProcess, "UInt", 0)
					DllCall("Kernel32.dll\CloseHandle", "Ptr", hProcess)
					this.LogString.=A_Tickcount . ",CleanUpOnFailedStart() known PID - sending TerminateProcess`n"
				} else
					this.LogString.=A_Tickcount . ",CleanUpOnFailedStart() known PID - failed to get process handle for TerminateProcess`n"
			}
		}
		else ;Kill any copies of the game other than the main one
		{
			this.LogString.=A_Tickcount . ",CleanUpOnFailedStart() no PID - closing non-main IC processes`n"
			WinGet, IDList, List, % "ahk_exe " . this.ExeName
			Loop % IDList
			{
				WinGet, newPID, PID, % "ahk_id " . IDList%A_Index%
				if (newPID!=g_SF.PID)
				{
					hProcess := DllCall("Kernel32.dll\OpenProcess", "UInt", 0x0001, "Int", false, "UInt", newPID, "Ptr")
					if(hProcess)
					{
						DllCall("Kernel32.dll\TerminateProcess", "Ptr", hProcess, "UInt", 0)
						DllCall("Kernel32.dll\CloseHandle", "Ptr", hProcess)
						this.LogString.=A_Tickcount . ",CleanUpOnFailedStart() no PID - sending TerminateProcess`n"
					} else
						this.LogString.=A_Tickcount . ",CleanUpOnFailedStart() no PID failed to get process handle for TerminateProcess`n"
				}
			}
		}
		this.UpdateState(-1)
		this.ExitRelay("CleanUpOnFailedStart()") ;Exit, nothing further we can do here
	}

	WaitForUserLogin(timeOut) ;This version sets up the memory reads and waits for them to return a value. NOTE: It isn't practical to dismiss the splash screen in these loops, as the SendMessage can take 500ms to process at certain points, stopping us catching the platform login
	{
		static MaxTime:=""
		if (MaxTime=="")
		{
			this.MEMORY_LOADED_finalAddress:=this.MemoryManager.getAddressFromOffsets(this.gameBaseAddress, this.MEMORY_LOADED_Offsets*)
			if (this.MemoryManager.read(this.MEMORY_LOADED_finalAddress, this.MEMORY_LOADED_Type)==1) ;If the initial call was made after login we're not playing the state machine game here
			{
				this.LogString.=A_Tickcount . ",WaitForUserLogin() was called after platform login`n"
				this.Stage:=-2
				return
			}
			else
			{
				MaxTime:=A_TickCount + timeout
				return ;Exit here as well, as we've already done a check this timer tick
			}
		}
		if (this.ForceRelease) ;If we're forced out (by the main thread being ready to go) or run out of time
		{
			this.Stage++ ;This is not a fail, as the main instance will be closed and the script will pick the new game instance up when ready
			this.LogString.=A_Tickcount . ",WaitForUserLogin() exit via ForceRelease in [" . A_TickCount-(MaxTime-timeout) . "]ms FinalAddress=[" . this.MEMORY_LOADED_finalAddress . "] Loaded read=[" . this.MemoryManager.read(this.MEMORY_LOADED_finalAddress, this.MEMORY_LOADED_Type) . "]`n"
			this.UpdateState(4)
			return
		}
		else if (A_TickCount > MaxTime)
		{
			this.Stage++ ;This is not a fail, as the main instance will be closed and the script will pick the new game instance up when ready
			this.LogString.=A_Tickcount . ",WaitForUserLogin() exit via Timeout in [" . A_TickCount-(MaxTime-timeout) . "]ms FinalAddress=[" . this.MEMORY_LOADED_finalAddress . "] Loaded read=[" . this.MemoryManager.read(this.MEMORY_LOADED_finalAddress, this.MEMORY_LOADED_Type) . "]`n"
			this.UpdateState(4)
			return
		}
		if (!this.MEMORY_LOADED_finalAddress) ;The read may not be available initially - have to try until it resolves
			this.MEMORY_LOADED_finalAddress:=this.MemoryManager.getAddressFromOffsets(this.gameBaseAddress, this.MEMORY_LOADED_Offsets*)
		if (this.MemoryManager.read(this.MEMORY_LOADED_finalAddress, this.MEMORY_LOADED_Type)==1) ;If the user has loaded
		{
			this.MemoryManager.suspend()
			this.LogString.=A_Tickcount . ",WaitForUserLogin() exit via Suspend in [" . A_TickCount-(MaxTime-timeout) . "]ms FinalAddress=[" . this.MEMORY_LOADED_finalAddress . "] Loaded read=[" . this.MemoryManager.read(this.MEMORY_LOADED_finalAddress, this.MEMORY_LOADED_Type) . "]`n"
			this.UpdateState(5)
			try
			{
				this.RelayData.LogZone("State 5") ;DEBUG - remove this later?
			}
			this.Stage++
		}
	}

	OpenProcessReader(timeout)
	{
		static MaxTime:=""
		if (MaxTime=="")
			MaxTime:=A_TickCount + timeout
		if (A_TickCount<=MaxTime)
		{
			isExeRead:=this.MemoryManagerRefresh()
			;this.MemoryManager.exeName := this.ExeName ;What is the purpose of this?
			if(isExeRead AND this.handle!="")
			{
				this.LogString.=A_Tickcount . ",OpenProcessReader() with PID=[" . this.MemoryManager.PID . "]`n"
				this.Stage++
			}
		}
		else
		{
			this.LogString.=A_Tickcount . ",OpenProcessReader() timed out`n"
			this.Stage:=-1
		}
	}

	MemoryManagerRefresh() ;Replacing part of _MemoryManager so we don't need a full instance of everything memory
	{
		moduleName:="mono-2.0-bdwgc.dll"
		this.MemoryManager:=New _IC_BrivMaster_Memory_Reader_Class("AHK_PID " . this.PID, handle) ;Must use PID
		this.handle:=handle
		if(!IsObject(this.MemoryManager))
			return false
		this.gameBaseAddress:=this.MemoryManager.getModuleBaseAddress(moduleName) + this.MEMORY_baseAddress
		this.LogString.=A_Tickcount . ",MemoryManagerRefresh() complete with gameBaseAddress=[" . this.gameBaseAddress . "]`n"
		return true
	}

	ActivateLastWindow()
	{
		if (!this.RestoreWindow OR this.SavedActiveWindow==this.MainHwnd) ;Don't bother re-activating the main copy of the game
		{
			this.Stage++
			return
		}
		static activateAfter:=""
		if (activateAfter=="")
		{
			activateAfter:=A_TickCount + 80
		}
		else if (A_TickCount >= activateAfter)
		{
			hwnd := this.Hwnd
			WinActivate, ahk_id %hwnd% ; Idle Champions likes to be activated before it can be deactivated
			savedActive := "ahk_id " . this.SavedActiveWindow
			WinActivate, %savedActive%
			this.UpdateState(3)
			this.Stage++
		}
	}

	SetLastActiveWindowWhileWaitingForGameExe(timeout)
	{
		static MaxTime:=""
		if (MaxTime=="")
		{
			MaxTime := A_TickCount + timeout
		}
		if (A_TickCount <= MaxTime)
		{
			this.Hwnd:=WinExist("ahk_pid " . this.PID) ;Must use the PID here as there will be 2 windows
			if (!this.Hwnd)
			{
				WinGet, savedActive,, A
				this.SavedActiveWindow:=savedActive
			}
			else
			{
				this.LogString.=A_Tickcount . ",Relay SetLastActiveWindowWhileWaitingForGameExe() success Hwnd=[" . this.Hwnd . "] after [" . A_TickCount - (MaxTime-timeout) . "]ms`n"
				try
				{
					this.RelayData.RelayHwnd:=this.Hwnd
				}
				catch
				{
					this.LogString.=A_Tickcount . ",SetLastActiveWindowWhileWaitingForGameExe() failed to pass Hwnd=[" . this.Hwnd . "] to main script`n"
				}
				this.Stage++
			}
		}
		else
		{
			this.LogString.=A_Tickcount . ",Relay SetLastActiveWindowWhileWaitingForGameExe() timed out after [" . A_TickCount - (MaxTime-timeout) . "]ms`n"
			this.Stage:=-1
		}
	}

	SetProcessToRealTime()
	{
		try
		{
			this.RelayData.RelayPID:=this.PID ;Here as it's the first stage that definately has a PID (either from the Run command, or by finding it)
		}
		catch
		{
			this.LogString.=A_Tickcount . ",SetProcessToRealTime() failed to pass PID=[" . this.PID . "] to main script`n"
		}
		Process, Priority, % this.PID, Realtime
		this.Stage++
	}

	SetPID(timeout)
	{
		static MaxTime:=""
		if (MaxTime=="")
			MaxTime:=A_TickCount + timeout
		if (A_TickCount < MaxTime)
		{
			this.PID := this.GetNewPID() ;We need to get a PID that is NOT the same as the one in the main script
			if (this.PID) ;If we pick up a PID just exit
			{
				this.LogString.=A_Tickcount . ",SetPID()=[" . this.PID . "] success after [" . A_TickCount - (MaxTime-timeout) . "]ms`n"
				this.Stage++
			}
		}
		else ;Out of time
		{
			this.LogString.logString.=A_TickCount . " SetPID() timed out after [" . A_TickCount - (MaxTime-timeout) . "]ms`n"
			this.Stage:=-1
		}
	}

	GetNewPID() ;Returns a PID that does NOT match the one in the main sharedFunctions - initial COM-based version. This is slower and has more erratic performance than the AHK window-based version, but doesn't need to wait on a window being spawned. With a seperate Relay script the delay is a non-issue so using this option
	{
		for gameProcess in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='" . this.ExeName . "'")
		{
			if (gameProcess.ProcessId!=this.MainPID)
			{
				return gameProcess.ProcessId
			}
		}
		return 0
	}

	OpenProcess()
	{
		programLoc:=this.LaunchCommand
		try
		{
			if (this.HideLauncher)
				Run, %programLoc%,,Hide,openPID
			else
				Run, %programLoc%,,,openPID
			if (this.GetProcessName(openPID)==this.ExeName) ;If we launch the game .exe directly (e.g. Steam) the Run PID will be the game, but for things like EGS it will not so we need to check this
			{
				this.PID:=openPID
				this.Stage+=2 ;Skip finding the PID via window
				this.LogString.=A_Tickcount . ",OpenProcess() opened with PID=[" . openPID . "]`n"
			}
			else
			{
				this.Stage++
				this.LogString.=A_Tickcount . ",OpenProcess() opened without PID`n"
			}
		}
		catch ;Failed to start
		{
			this.LogString.=A_Tickcount . ",OpenProcess() failed to launch game`n"
			this.Stage:=-1
		}
	}

	GetProcessName(processID) ;To check without a window being present
	{
		if (hProcess := DllCall("OpenProcess", "uint", 0x0410, "int", 0, "uint", processID, "ptr"))
		{
			size := VarSetCapacity(buf, 0x0104 << 1, 0)
			if (DllCall("psapi\GetModuleFileNameEx", "ptr", hProcess, "ptr", 0, "ptr", &buf, "uint", size))
			{
				SplitPath, % StrGet(&buf), processExeName
				DllCall("CloseHandle", "ptr", hProcess)
				return processExeName
			}
			DllCall("CloseHandle", "ptr", hProcess)
		}
		return false
	}

}