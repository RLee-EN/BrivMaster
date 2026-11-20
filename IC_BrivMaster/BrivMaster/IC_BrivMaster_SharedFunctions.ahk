;This file is intended for classes used across both the gem farm script and the hub
#include %A_LineFile%\..\IC_BrivMaster_Memory.ahk

class IC_BrivMaster_SharedFunctions_Class
{
	__new()
    {
        this.Memory:=New IC_BrivMaster_MemoryFunctions_Class(A_LineFile . "\..\Offsets\IC_Offsets.json")
		g_ServerCall:=New IC_BrivMaster_ServerCall_Class()
    }

	LoadObjectFromAHKJSON(fileName,preserveBooleans:=false) ;If preserveBooleans is set 'true' and 'false' will be read as strings rather than being converted to -1 or 0, as AHK does not have a boolean type. Needed for game settings file
    {
        FileRead, oData, %fileName%
        data:=""
        try
        {
            if (preserveBooleans)
				data:=AHK_JSON_RAWBOOLEAN.Load(oData)
			else
				data:=AHK_JSON.Load(oData)
        }
        catch err
        {
            err.Message:=err.Message . "`tFile:`t" . fileName
            throw err
        }
        return data
    }

    WriteObjectToAHKJSON(fileName, ByRef object,preserveBooleans:=false)
    {
        if (preserveBooleans)
			objectJSON:=AHK_JSON_RAWBOOLEAN.Dump(object,,"`t")
		else
			objectJSON:=AHK_JSON.Dump(object,,"`t")
        if (!objectJSON)
            return
        FileDelete, %fileName%
        FileAppend, %objectJSON%, %fileName%
        return
    }

	GetProcessName(processID) ;To check without a window being present
	{
		if(hProcess:=DllCall("OpenProcess", "uint", 0x0410, "int", 0, "uint", processID, "ptr"))
		{
			size:=VarSetCapacity(buf, 0x0104 << 1, 0)
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
	
    IsCurrentFormation(testformation:="") ;Returns true if the formation array passed is the same as the formation currently on the game field. Always false on empty formation reads. Requires full formation.
    {
        if(!IsObject(testFormation))
            return false
        currentFormation := this.Memory.GetCurrentFormation()
        if(!IsObject(currentFormation))
            return false
        if(currentFormation.Count()!=testformation.Count()) 
            return false
        loop, % currentFormation.Count()
            if(testformation[A_Index]!=currentFormation[A_Index])
                return false
        return true
    }
	
	InDianaCheeseWindow()
	{
		currentTime:=SubStr(A_NowUTC, 9, 2)*60 + SubStr(A_NowUTC, 11, 2) ;Time in minutes passed midnight
		return currentTime>1139 AND currentTime<1170 ;18:59 to 19:30 UTC, which is 11:59 to 12:30 British Columbia time as they no longer do DST
	}
}

class IC_BrivMaster_SharedData_Class ;In the shared file as the SettingsPath static is used by the hub for the save/load location TODO: This seems like a lousy reason to load this into the hub, move settings path to SharedFunctions?
{
	static SettingsPath:=A_LineFile . "\..\IC_BrivMaster_Settings.json"

	__New()
	{
		this.BossesHitThisRun:=0
		this.TotalBossesHit:=0
        this.TotalRollBacks:=0
        this.BadAutoProgress:=0
		this.IBM_RunControl_DisableOffline:=false
		this.IBM_RunControl_ForceOffline:=false
		this.IBM_ProcessSwap:=false
		this.IBM_RunControl_CycleString:=""
		this.IBM_RunControl_StatusString:=""
		this.IBM_RunControl_StackString:=""
		this.IBM_BuyChests:=false
		this.RunLogResetNumber:=0
		this.RunLog:=""
		this.LoopString:=""
		this.LastCloseReason:=""
	}

	Close() ;Taken from what was IC_BrivGemFarmRun_SharedData_Class in IC_BrivGemFarm_Run.ahk
    {
        if (g_SF.Memory.ReadUserIsInited()="") ; Invalid game state
            ExitApp
        g_IBM.RouteMaster.WaitForTransition()
        g_IBM.RouteMaster.FallBackFromZone()
        g_IBM.RouteMaster.ToggleAutoProgress(false, false, true)
        ExitApp
    }

	ShowGUI()
    {
        Gui, Show, NA
    }

	Init()
    {
        this.UpdateSettingsFromFile()
		this.IBM_OutboundDirty:=false ;Track if we've made changes to the data so the hub doesn't make unnecessary checks
    }

    UpdateSettingsFromFile() ;Load settings from the GUI settings file.
    {
        settings:=g_SF.LoadObjectFromAHKJSON(IC_BrivMaster_SharedData_Class.SettingsPath)
        if (!IsObject(settings))
            return false
		for k,v in settings
		{
			if(k!="HUB") ;Do not load hub-only settings
				g_IBM_Settings[k]:=v
		}
		settings:=""
		g_IBM.RefreshGemFarmWindow()
    }

	UpdateOutbound(key,value) ;Update if the value has changed at mark the outbound data as dirty
	{
		if (this[key]!=value)
		{
			this[key]:=value
			this.IBM_OutboundDirty:=true
		}
	}

	ResetRunStats() ;Resets per-run stats from the main object (boss hits, rollbacks, bad autoprogression). This allows them to all be cleared in one go without spam setting the IBM_OutboundDirty flag
	{
		this.BossesHitThisRun:=0
		this.TotalBossesHit:=0
        this.TotalRollBacks:=0
        this.BadAutoProgress:=0
		this.IBM_OutboundDirty:=true
	}

	UpdateOutbound_Increment(key) ;Increment a value, used for things like boss hit tracking
	{
		if (this.HasKey(key))
			this[key]++
		else
			this[key]:=1
		this.IBM_OutboundDirty:=true
	}
}

class IC_BrivMaster_InputManager_Class ;A class for managing input related matters
{
	keyList:={} ;Indexed by key per the script (e.g. "F1","ClickDmg"), contains the mapped Key, lParam for SendMessage for down, and lParam for SendMessage for up

	__new() ;Currently it is up to code using this to add the necessary keys TODO: Pass the object containing the HWnd to be used byRef, so it can be used with g_IBM.GameMaster.Hwnd in main and g_SF.Hwnd in hub?
	{
		this.gameFocus()
	}

	addKey(key)
	{
		if (!this.keyList.HasKey(key))
			this.keyList[key]:=new IC_BrivMaster_InputManager_Class.IC_BrivMaster_InputManager_Key_Class(key)
	}

	getKey(key)
	{
		if (!this.keyList.HasKey(key))
			this.addkey(key)
		return this.keyList[key]
	}

	gameFocus() ;We need a way to detect IC losing focus, as that appears to be the only case that this needs to be re-called
	{
		hwnd:=g_IBM.GameMaster.Hwnd
		ControlFocus,, ahk_id %hwnd%
	}
	
	class IC_BrivMaster_InputManager_Key_Class ;Represents a single key
	{
		__new(key)
		{
			this.key:=key
			if(g_IBM_Settings["IBM_Scan_Codes"].HasKey(key)) ;Following key logic taken from SH_KeyHelper.ahk
			{
				formattedSC:=Format("sc{:X}", g_IBM_Settings["IBM_Scan_Codes",key])    ;Reformat for use in GetKeyVK (sc + hex. e.g. scC0)
				vk:=GetKeyVK(formattedSC)            ;Get virtual key value (dec)
				this.mappedKey:=Format("0x{:X}", vk) ;convert virtual key to hex code 
				sc:=g_IBM_Settings["IBM_Scan_Codes",key] << 16
				this.lparamDown:=Format("0x{:X}", 0x0 | sc)
				this.lparamUp:=Format("0x{:X}", 0xC0000001 | sc)
			}
			else
				g_IBM.Logger.AddMessage("InputManager: No scancode for key=[" . key . "]")
			this.tag:="" ;Used for tracking arbitary infomation on the key, e.g. the associated seat for F-keys
		}

		Press() ;Hold a key and do not release
		{
			hwnd:=g_IBM.GameMaster.Hwnd
			mk:=this.mappedKey ;We have to copy the variables locally due to limitations of AHK :(
			lD:=this.lparamDown
			ControlFocus,, ahk_id %hwnd%
			SendMessage, 0x0100, %mk%, %lD%,, ahk_id %hwnd%,,,,1000
		}

		Release() ;Release a key
		{
			hwnd:=g_IBM.GameMaster.Hwnd
			mk:=this.mappedKey
			lU:=this.lparamUp
			ControlFocus,, ahk_id %hwnd% ;As above
			SendMessage, 0x0101, %mk%, %lU%,, ahk_id %hwnd%,,,,3000
		}

		KeyPress() ;Press then release a key
		{
			startCritical:=A_IsCritical ;Store existing state of critical
			Critical, On
			hwnd:=g_IBM.GameMaster.Hwnd
			mk:=this.mappedKey
			lD:=this.lparamDown
			lU:=this.lparamUp
			ControlFocus,, ahk_id %hwnd% ;As above
			SendMessage, 0x0100, %mk%, %lD%,, ahk_id %hwnd%,,,,1000
			SendMessage, 0x0101, %mk%, %lU%,, ahk_id %hwnd%,,,,3000
			if (!startCritical) ;Only turn critical off if wasn't on when we entered this function
				Critical, Off
		}

		Press_Bulk() ;The _Bulk versions do not set ControlFocus, and are intended for code that will send a lot of input together (e.g. levelling) and that code will be responsible for calling ControlFocus once
		{
			hwnd:=g_IBM.GameMaster.Hwnd
			mk:=this.mappedKey ;We have to copy the variables locally due to limitations of AHK :(
			lD:=this.lparamDown
			SendMessage, 0x0100, %mk%, %lD%,, ahk_id %hwnd%,,,,1000
		}

		Release_Bulk() ;Release a key
		{
			hwnd:=g_IBM.GameMaster.Hwnd
			mk:=this.mappedKey
			lU:=this.lparamUp
			SendMessage, 0x0101, %mk%, %lU%,, ahk_id %hwnd%,,,,3000
		}

		KeyPress_Bulk() ;Press then release a key
		{
			hwnd:=g_IBM.GameMaster.Hwnd
			mk:=this.mappedKey
			lD:=this.lparamDown
			lU:=this.lparamUp
			SendMessage, 0x0100, %mk%, %lD%,, ahk_id %hwnd%,,,,1000
			SendMessage, 0x0101, %mk%, %lU%,, ahk_id %hwnd%,,,,3000
		}
	}
}

class IC_BrivMaster_ServerCall_Class extends IBM_ServerCall_Class
{
	__New()
    {
        this.userID:=0
		this.userHash:=""
		this.instanceID:=0
		this.networkID:=11
		this.clientVersion:=999
		this.activeModronID:=1
		this.activePatronID:=0
		this.playServerRegex:="^https?://ps(?:lt)?\d+\.idlechampions.com/~idledragons/"
		this.webRoot:=""
		this.md5Module:=DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
    }
	
	UpdatePlayServer()
    {
		newRead:=g_SF.Memory.ReadWebRoot() ;This is an unreliable read; we need to ensure it not only returns a value but that it is a url
		if(RegExMatch(newRead,this.playServerRegex))
		{
			this.webRoot:=newRead
			return
		}
		else if(RegExMatch(this.webRoot,this.playServerRegex)) ;If the existing webRoot is valid, keep it
			return
		this.webRoot:="http://master.idlechampions.com/~idledragons/" ;Try requesting from master, this will not necessarily give our own playserver but should return a valid one, allowing redirects on future calls
		response:=this.ServerCall("getPlayServerForDefinitions") ;No args actually required for this
		if (response!="" AND RegExMatch(response.play_server,this.playServerRegex))
		{
			this.webRoot:=response.play_server
			return
		}
		currentPlayServers:=["lt1","lt2","lt3","lt4"] ;Select randomly from a hard coded server pool (current as of 2026-07-16)
		Random, psIndex, 1, currentPlayServers.Count()
		this.webRoot:="http://ps" . currentPlayServers[psIndex] . ".idlechampions.com/~idledragons/"
    }
	
	UpdateStackData()
    {
		newRead:=g_SF.Memory.ReadInstanceID()
        if(newRead)
            this.InstanceID:=newRead
        this.sprint:=g_Heroes[58].ReadHasteStacks() ;Note: the reason for this naming is that the stat in the game is called 'BrivSprintStacks'
        this.steelbones:=g_Heroes[58].ReadSBStacks()
    }

    Update()
    {
        newRead:=g_SF.Memory.ReadUserID()
        if(newRead)
            this.UserID:=newRead
        newRead:=g_SF.Memory.ReadUserHash()
        if(newRead)
            this.UserHash:=newRead
		this.UpdateStackData()
        newRead:=g_SF.Memory.ReadBaseGameVersion()
        if(newRead)
            this.clientVersion:=newRead

        newRead:=g_SF.Memory.ReadPlatform()
        if(newRead)
            this.networkID:=newRead
        newRead:=g_SF.Memory.ReadActiveGameInstance()
        if(newRead)
            this.activeModronID:=newRead
        newRead:=g_SF.Memory.ReadPatronID()
        if(newRead)
            this.activePatronID:=newRead
		this.UpdatePlayServer()
        this.dummyData:="&language_id=1&timestamp=0&request_id=0&network_id=" . this.networkID . "&mobile_client_version=" . this.clientVersion . "&offline_v2_build=1"
    }

	ShouldCallPreventStackFail(forceSave:=false) 
	{
		if (this.steelbones=="" OR this.sprint=="") ;If either value is missing, we can't put the conversion together
			return false
		if (!forceSave AND this.steelbones==0) ;If not forcing and we have no SB to convert, we shouldn't send a pointless save
			return false
		return true
	}

	CallPreventStackFail(message,launchScript:=false) ;This function should be called after UpdateStackData() is used and ShouldCallPreventStackFail() returns true
    {
		stacks:=this.sprint + Floor(this.steelbones * g_IBM.RouteMaster.stackConversionRate)
		g_IBM.Logger.AddMessage("Servercall Save via: "  . message . " Converted Haste=[" . stacks . "] from Haste=[" . this.sprint . "] and Steelbones=[" . this.steelbones . "] with stackConversionRate=[" . Round(g_IBM.RouteMaster.stackConversionRate,1) . "]")
		jsonString:="{""stats"":{""briv_steelbones_stacks"":0,""briv_sprint_stacks"":" . stacks . "}}"
		boundaryHeader:=this.GetBoundryHeader()
		save:=this.GetSaveFromJSON(jsonString,boundaryHeader)
		if(launchScript) ;Do server call from new script to prevent hanging script due to network issues.
        {
            webRoot:=this.webRoot
            scriptLocation:=A_LineFile . "\..\IC_BrivMaster_SaveStacks.ahk"
            Run, %A_AhkPath% "%scriptLocation%" "%webRoot%" "%save%" "%boundaryHeader%"
        }
        else
        {
            try
                response:=this.ServerCallSave(save,boundaryHeader)
            catch
                g_IBM.Logger.AddMessage("Failed to save Briv stacks")			
        }
		return response ;Note this will only be meaningful for the synchronous version of the call
    }
	
    ServerCallSave(saveBody,boundaryHeader,retryNum:=0) ; Special server call specifically for use with saves. saveBody must be encoded before using this call.
    {
        response:=""
        WR:=ComObjCreate("WinHttp.WinHttpRequest.5.1")  
        WR.SetTimeouts("0","15000","7500","30000") ;https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts defaults: 0 (DNS Resolve), 60000 (connection timeout. 60s), 30000 (send timeout), 60000 (receive timeout)
        Try 
		{
            WR.Open("POST",this.webroot . "post.php?call=saveuserdetails&", true)
            WR.SetRequestHeader("Accept-Encoding", "identity")
			WR.SetRequestHeader("Content-Type", "multipart/form-data; boundary=""" . boundaryHeader . """")
            WR.SetRequestHeader("User-Agent", "BestHTTP")
            WR.Send(saveBody)
            WR.WaitForResponse(-1)
            data:=WR.ResponseText
            if(data) ;Don't try to JSON.Load the string if empty TODO: Review this codepath, does it retry in the no response case? I don't think so...
			{
				try
				{
					response:=AHK_JSON.Load(data)
					if(!(response.switch_play_server=="")) ;NOT(response.switch_play_server=="") => switch_play_server exists. TODO: Should this retry when the server was valid? Probably not given the nature of this call - if the server is down we probably want to return to the run
					{
						retryNum++
						this.WebRoot:=response.switch_play_server
						if(retryNum<=3)
						{						
							WR:=""
							return this.ServerCallSave(saveBody,boundaryHeader,retryNum) 
						}
					}
				}
			}
        }
		WR:=""
        return response
    }

    __Delete() ;Free library after use
    {
        DllCall("FreeLibrary", "Ptr", this.md5Module)
    }

    MD5Save(stringVal) ;Creates a salted md5 checksum for a save string. Modified from https://www.autohotkey.com/boards/viewtopic.php?f=6&t=21
    {
        stringVal:=stringVal . "somethingpoliticallycorrect"
        VarSetCapacity(MD5_CTX, 104, 0)
		DllCall("advapi32\MD5Init", "Ptr", &MD5_CTX)
        DllCall("advapi32\MD5Update", "Ptr", &MD5_CTX, "AStr", stringVal, "UInt", StrLen(stringVal))
        DllCall("advapi32\MD5Final", "Ptr", &MD5_CTX)
        loop, 16
            o.=Format("{:02" (case ? "X" : "x") "}", NumGet(MD5_CTX, 87 + A_Index, "UChar"))
        StringLower, o,o
        return o
    }

    GetSaveFromJSON(jsonString,boundaryHeader,timeStamp:="0") ;Converts user's data into form data that can be submitted for a save
    {
		userData:=g_zlib.Deflate(jsonString)
		checksum:=this.MD5Save(jsonString)
        mimicSave:="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""call""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: 15`r`n`r`n"
        mimicSave.="saveuserdetails`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""language_id""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: 1`r`n`r`n"
        mimicSave.="1`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""user_id""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: "  StrLen(this.userID)  "`r`n`r`n"
        mimicSave.=this.userID . "`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""hash""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: 32`r`n`r`n"
        mimicSave.=this.userHash . "`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""details_compressed""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: "  (StrLen(userData))  "`r`n`r`n"
        mimicSave.=userData . "`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""checksum""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: 32`r`n`r`n"
        mimicSave.=checksum . "`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""timestamp""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: "  StrLen(timeStamp)  "`r`n`r`n"
        mimicSave.=timeStamp . "`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""request_id""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: 1`r`n`r`n"
        mimicSave.="1`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""network_id""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: " StrLen(this.networkID)  "`r`n`r`n"
        mimicSave.=this.networkID . "`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""mobile_client_version""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: "  StrLen(this.clientVersion)  "`r`n`r`n"
        mimicSave.=this.clientVersion . "`r`n"
        mimicSave.="--" . boundaryHeader . "`r`n"
        mimicSave.="Content-Disposition: form-data; name=""instance_id""`r`n"
        mimicSave.="Content-Type: text/plain; charset=utf-8`r`n"
        mimicSave.="Content-Length: "  StrLen(this.instanceID)  "`r`n`r`n"
        mimicSave.=this.instanceID . "`r`n"
        mimicSave.="--" . boundaryHeader . "--`r`n"
        return mimicSave
    }
	
	GetBoundryHeader()
	{
		Random, r1, 0, 65535
		Random, r2, 0, 65535
		return "BestHTTP_HTTPMultiPartForm_" . Format("{:04X}", r2) . Format("{:04X}", r1) ;Random is limited to signed int32, so instead of faffing about with that just glue two 16-bit values together
	}

    ;============================================================
    ;Various server call functions that should be pretty obvious.
    ;============================================================
    ;Except this one, it is used internally and shouldn't be called directly.
    ServerCall(callName, parameters:="", timeout:=60000, retryNum:=0) 
    {
        response:=""
        URLtoCall:=this.webRoot . "post.php?call=" . callName . parameters
        WR:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WR.SetTimeouts(0,45000,30000,timeout) ;https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts defaults: 0 (DNS Resolve), 60000 (connection timeout. 60s), 30000 (send timeout), 60000 (receive timeout)
        Try
		{
            WR.Open("POST",URLtoCall,true)
            WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
            WR.Send()
            WR.WaitForResponse(-1)
            data:=WR.ResponseText
            Try
            {
                response:=AHK_JSON.Load(data)
                if(!(response.switch_play_server==""))
                {
                    retryNum++
                    this.WebRoot:=response.switch_play_server
                    if(retryNum<=3) 
                    {
						WR:=""
						return this.ServerCall(callName,parameters,timeout,retryNum)
					}
                }
            }
        }
		WR:=""
        return response
    }

    CallLoadAdventure(adventureToLoad) ;Starts a new adventure and returns the response
    {
        patronTier:=this.activePatronID ? 1 : 0
        advParams:=this.dummyData . "&patron_tier=" . patronTier . "&user_id=" . this.userID . "&hash=" . this.userHash . "&instance_id=" . this.instanceID 
            . "&game_instance_id=" . this.activeModronID . "&adventure_id=" . adventureToLoad . "&patron_id=" . this.activePatronID
        return this.ServerCall("setcurrentobjective", advParams)
    }

    CallEndAdventure() ;Calling this loses everything earned during the adventure, should only be used when stuck
    {
        advParams:=this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&game_instance_id=" this.activeModronID
        return this.ServerCall("softreset",advParams)
    }

    CallBuyChests(chestID,chests,chestType:="") ;Buys <chests> number of <chestID> chests. Only works with basic non-patron non-event chests
    {
        if(chests>250)
            chests:=250
        else if(chests<1)
            return
        chestParams:=this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&chest_type_id=" chestID "&count=" chests
        return this.ServerCall("buysoftcurrencychest",chestParams)
    }

    CallOpenChests(chestID, chests) ;Open <chests> number of <chestID> chest
    {
        if(chests>1000)
            chests:=1000
        else if(chests<1)
            return
        chestParams:="&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id=" this.userID "&hash=" this.userHash 
            . "&instance_id=" this.instanceID "&chest_type_id=" chestid "&game_instance_id=" this.activeModronID "&count=" chests
        return this.ServerCall("opengenericchest",chestParams,60000)
    }
}

class IBM_ServerCall_Class ;Simple generic servercall class, this is SH_ServerCalls without the proxy settings
{
    __New()
    {
        return this
    }

    BasicServerCall(url, timeout:=60000) 
    {
        response:=""
        WR:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WR.SetTimeouts( 0, 45000, 30000, timeout)
        Try
		{
            WR.Open("GET", Url, true)
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.SetRequestHeader( "Accept","application/json" )
            WR.Send()
            WR.WaitForResponse(-1)
            data:=WR.ResponseText
            Try
            {
                response:=AHK_JSON.Load(data) ;We could potentially handle an empty return / exception from AKH_JSON.Load() rather than have BasicServerCallRaw(), but that might mean something JSON-adjacent gets processed when it shouldn't
            }
        }
        catch exception
		{
			WR:=""
			return exception
		}
        WR:=""
		return response
    }
	
	BasicServerCallRaw(url, timeout:=60000) ;Does not parse as JSON
    {
        data:=""
        WR:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WR.SetTimeouts( 0, 45000, 30000, timeout)
        Try
		{
            WR.Open("GET", Url, true)
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.SetRequestHeader( "Accept","application/json" )
            WR.Send()
            WR.WaitForResponse(-1)
            data:=WR.ResponseText
        }
        catch exception
		{
			WR:=""
			return exception
		}
        WR:=""
		return data
    }
}