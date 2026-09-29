class IC_BrivMaster_RouteMaster_Class ;A class for managing routes
{
	zoneCap:=2501
	zones:={}
	leftoverCalculated:=false ;True once this has been calculated - has to be done after Thellora has been fielded
	leftoverHaste:=48
	cycleCount:=0 ;Counts the number of runs since the last game restart
	cycleMax:=1 ;Maximum runs per offline
	cycleForceOffline:=false ;Stack offline in all cases
	cycleDisableOffline:=false ;Stack online in all cases
	offlineSaveTime:=-1 ;Tracks the offline start time so it can be accessed globally
	;Below has to be a string because array literals can't be this long. Going to 400 jumps is a bit overkill
	static IRI_BRIVMASTER_JUMPCOST_METALBORN := "50,52,54,56,58,60,62,64,66,68,70,72,74,76,78,81,84,87,90,93,96,99,102,105,108,112,116,120,124,128,132,136,140,145,150,155,160,165,170,176,182,188,194,200,207,214,221,228,236,244,252,260,269,278,287,296,306,316,326,337,348,359,371,383,396,409,423,437,451,466,481,497,513,530,548,566,585,604,624,645,666,688,711,734,758,783,809,836,864,893,923,953,984,1017,1051,1086,1122,1159,1197,1237,1278,1320,1364,1409,1456,1504,1554,1605,1658,1713,1770,1828,1888,1950,2014,2081,2150,2221,2294,2370,2448,2529,2613,2699,2788,2880,2975,3073,3175,3280,3388,3500,3616,3736,3859,3987,4119,4255,4396,4541,4691,4846,5006,5171,5342,5519,5701,5889,6084,6285,6493,6708,6930,7159,7396,7640,7893,8154,8424,8702,8990,9287,9594,9911,10239,10577,10927,11288,11661,12046,12444,12855,13280,13719,14173,14642,15126,15626,16143,16677,17228,17798,18386,18994,19622,20271,20941,21633,22348,23087,23850,24638,25452,26293,27162,28060,28988,29946,30936,31959,33015,34106,35233,36398,37601,38844,40128,41455,42825,44241,45703,47214,48775,50387,52053,53774,55552,57388,59285,61245,63270,65362,67523,69755,72061,74443,76904,79446,82072,84785,87588,90483,93474,96564,99756,103054,106461,109980,113616,117372,121252,125260,129401,133679,138098,142663,147379,152251,157284,162483,167854,173403,179135,185057,191175,197495,204024,210769,217737,224935,232371,240053,247989,256187,264656,273405,282443,291780,301426,311390,321684,332318,343304,354653,366377,378489,391001,403927,417280,431074,445324,460045,475253,490964,507194,523961,541282,559176,577661,596757,616484,636864,657917,679666,702134,725345,749323,774094,799684,826120,853430,881643,910788,940897,972001,1004133,1037327,1071619,1107044,1143640,1181446,1220502,1260849,1302530,1345589,1390071,1436024,1483496,1532537,1583199,1635536,1689603,1745458,1803159,1862768,1924347,1987962,2053680,2121570,2191705,2264158,2339006,2416328,2496207,2578726,2663973,2752038,2843014,2936998,3034089,3134389,3238005,3345046,3455626,3569862,3687874,3809787,3935730,4065837,4200245,4339096,4482537,4630720,4783802,4941944,5105314,5274085,5448435,5628549,5814617,6006836,6205409,6410546,6622465,6841389,7067551,7301189,7542551,7791892,8049475,8315573,8590468,8874450,9167820,9470888,9783975,10107412,10441541,10786716,11143302,11511676,11892227,12285358,12691486,13111039,13544462,13992213,14454765,14932608,15426248,15936207,16463024,17007256,17569479,18150288,18750298,19370143,20010478,20671981,21355352"

	__New(combine,logBase)
	{
		this.combining:=combine
		this.zonesPerJumpQ:=g_IBM_Settings["IBM_Route_BrivJump_Q"] + 1 ; We want the actual number of zones so adding 1 here, eg 9 jump goes from z1 to z11, so covers 10 zones (because it's the normal +1 progress plus the 9)
		if (g_Heroes[58].inE) ;Feat swap, ignored if Briv is not saved in E
			this.zonesPerJumpE:=g_IBM_Settings["IBM_Route_BrivJump_E"] + 1 ;As above
		else
			this.zonesPerJumpE:=1 ;Walking progresses 1 zone per 'jump'
		this.zonesPerJumpM:=g_IBM_Settings["IBM_Route_BrivJump_M"] + 1 ;Used when Thellora is in M, as we'll do an M-jump out of the Casino
		this.targetZone:=g_SF.Memory.GetModronResetArea()
		this.UpdateThellora(true) ;Must be done after the zones per jump are populated
		this.jumpCosts:=strsplit(IC_BrivMaster_RouteMaster_Class.IRI_BRIVMASTER_JUMPCOST_METALBORN,",")
		if (this.BrivHasThunderStep()) ;Multiplier for Briv stacks on conversion, to accomodate Thunder Step feat (2131)
			this.stackConversionRate:=1.2
		else
			this.stackConversionRate:=1
		this.KEY_autoProgress:=g_InputManager.getKey("g")
		this.KEY_Q:=g_InputManager.getKey("q")
		this.KEY_W:=g_InputManager.getKey("w")
		this.KEY_E:=g_InputManager.getKey("e")
		this.KEY_LEFT:=g_InputManager.getKey("Left")
		this.HybridBlankOffline:=g_IBM_Settings["IBM_OffLine_Blank"] ;Should we avoid trying to get stacks when restarting during hybrid?
		this.RelayBlankOffline:=g_IBM_Settings["IBM_OffLine_Blank_Relay"]
		if (this.RelayBlankOffline)
		{
			this.RelaySetup(logBase)
			revokeFunc:=ObjBindMethod(this, "RelayComObjectRevoke")
			OnExit(revokeFunc)
		}
		switch g_IBM_Settings["IBM_Online_Farideh_Condition"]
		{
			case 3: this.OnlineStacker:=New IC_BrivMaster_RouteMaster_Class.IBM_Online_Stacker_Tatyana_Return(this)
			case 2: this.OnlineStacker:=New IC_BrivMaster_RouteMaster_Class.IBM_Online_Stacker_Attacking(this)
			default: this.OnlineStacker:=New IC_BrivMaster_RouteMaster_Class.IBM_Online_Stacker_Active_Enemies(this)
		}
		this.ThelloraBossAvoidance:=g_IBM_Settings["IBM_Route_Combine_Boss_Avoidance"] ;Should we try to invert the standard combine option to avoid hitting a boss? (Note this was previously only applicable to combining)
		g_SharedData.UpdateOutbound("IBM_RunControl_DisableOffline",false) ;Default to off
		g_SharedData.UpdateOutbound("IBM_RunControl_ForceOffline",false) ;Default to off
		this.LastSafeStackZone:=this.GetLastSafeStackZone() ;No reason to re-calcuate this every zone
		g_SharedData.UpdateOutbound("IBM_ProcessSwap",false) ;Allows the hub to detect process changes on restarts promptly
		this.LoadRoute()
		this.SetStrategyStrings()
	}

	Reset()
	{
		this.leftoverCalculated:=false
		this.leftoverHaste:=48
		this.cycleCount++
		g_IBM.Logger.SetRunCycle(this.cycleCount)
		this.cycleMax:=g_IBM_Settings["IBM_OffLine_Freq"]
		;Only process Run Control input from the hub at the start of a run, as changing mid-run could make a mess
		this.cycleDisableOffline:=g_SharedData.IBM_RunControl_DisableOffline
		if (g_SharedData.IBM_RunControl_ForceOffline)
		{
			this.cycleForceOffline:=true ;Queue
			g_SharedData.UpdateOutbound("IBM_RunControl_ForceOffline",false) ;Clear as this is a one-off
		}
		if (this.RelayBlankOffline)
		{
			this.RelayData.Reset()
		}
		g_SharedData.UpdateOutbound("IBM_RunControl_CycleString","Cycle " . this.cycleCount . "/" . this.cycleMax . (this.cycleForceOffline ? " FO" : ""))
		this.SetInitialStackString()
		g_SharedData.UpdateOutbound("IBM_ProcessSwap",false)
	}

	RelaySetup(logBase) ;One-time relay setup
	{
		this.RelayData:=new IC_BrivMaster_Relay_SharedData_Class(g_Heroes.InA(139) ? this.GetThelloraTarget(g_Heroes[139].rushCap,this.combining) + 1 : 2) ;Zone after Thellora's target, or 2 otherwise, to avoid the Casino / initial levelling respectively
		GuidCreate := ComObjCreate("Scriptlet.TypeLib")
		this.RelayData.GUID := GuidCreate.Guid
		this.RelayData.LogFile:=logBase . "_Relay.csv"
		ObjRegisterActive(this.RelayData, this.RelayData.GUID)
	}

	RelayComObjectRevoke()
	{
		ObjRegisterActive(this.RelayData, "")
	}

	CheckRelayRelease()
	{
		if(this.RelayBlankOffline)
			this.RelayData.PreRelease()
	}

	SetStrategyStrings()
	{
		targetStacks:=this.GetTargetStacks(true)
		jumpString:=this.zonesPerJumpQ . (this.zonesPerJumpE>1 ? "&&" . this.zonesPerJumpE : "") . "z/J"
		stackString:="Using " . targetStacks . " stacks (stacking " . (this.stackConversionRate!=1 ? CEIL((targetStacks-48)/this.stackConversionRate) . " w/TS" : targetStacks-48) . ")"
		if(g_Heroes[139].inM)
		{
			g_SharedData.UpdateOutbound("IBM_RunControl_StatusString",(this.combining ? "Combining" : "Non-combined") . " to z" . this.thelloraTarget . " following by Casino, jumping " . jumpString . " to reset at z" . this.targetZone . ". " . stackString) ;For Home display
			g_IBM.Logger.OutputHeader((this.combining ? "Combining" : "Non-combined") . " to z" . this.thelloraTarget . " following by Casino,Jumping " . jumpString . ",Reset at z" . this.targetZone . "," . stackString) ;CSV for log
		}
		else
		{
			g_SharedData.UpdateOutbound("IBM_RunControl_StatusString","Casino at z1 followed by non-combined to z" . this.thelloraTarget . ", jumping " . jumpString . " to reset at z" . this.targetZone . ". " . stackString)
			g_IBM.Logger.OutputHeader("Casino at z1 followed by non-combine to z" . this.thelloraTarget . ",Jumping " . jumpString . ",Reset at z" . this.targetZone . "," . stackString)
		}
	}

	SetInitialStackString() ;Return the pre-stacking intent, i.e. on/offline and zone
	{
		if (this.ShouldOfflineStack()) ;Offline
			stackString:="Stacking: Expecting offline at z" . g_IBM_Settings["IBM_Offline_Stack_Zone"]
		else
		{
			stackString:="Stacking: Expecting online at or after z" . g_IBM_Settings["IBM_Online_Melf_Min"]
			if(this.ShouldBlankRestart())
			{
				if (this.RelayBlankOffline)
					stackString.=" with relay blank restart"
				else
					stackString.=" with blank restart"
			}
		}
		g_SharedData.UpdateOutbound("IBM_RunControl_StackString",stackString)
	}

	NeedToStack() ;Is stacking this run required, i.e. do we have less Steelbones than needed for the *next* run
	{
		return g_Heroes[58].ReadSBStacks() < this.GetTargetStacks()
	}

	GetTargetStacks(ignoreHaste:=false, forceRecalc:=false) ;Number of Steelbones stacks needed for the next run. Ignore haste is used for the status string showing the expected per run stack usage, rather than in-run calculation
	{
		if(ignoreHaste)
			return this.GetTargetStacksForFullRun(true)
		else
		{
			this.UpdateLeftoverHaste(forceRecalc)
			stacksToGenerate:=this.GetTargetStacksForFullRun() - this.leftoverHaste
			return CEIL(stacksToGenerate / this.stackConversionRate) ;Ceiling as the feat rounds down
		}
	}

	UpdateThellora(force:=false)
	{
		if (g_Heroes[139].UpdateRushTarget() OR force)
			this.thelloraTarget:=this.GetThelloraTarget(g_Heroes[139].rushCap,this.combining)
	}

	IsFeatSwap()
	{
		return this.zonesPerJumpE > 1
	}

	GetThelloraTarget(baseJump,combine)
	{
		if (combine) ;This is determining the Thellora jump, so when combining must use the jump value for M
			return baseJump + this.zonesPerJumpM ;No +1 as already included in this.zonesPerJumpM
		else
			return baseJump + 1
	}

	CheckThelloraBossRecovery() ;If option set, avoid rushing into bosses after a failed run by breaking / making the combine. This will set Briv's z1c in the default case for non-combining
	{
		if(this.combining)
		{
			if(this.ThelloraBossAvoidance)
			{
				thelloraCharges:=Floor(g_Heroes[139].GetCappedRushCharges()) ;Floor as the part-charges are presented as decimals, eg 307.2 = 307 zones plus 20% of the way to another
				rushTargetCombining:=this.GetThelloraTarget(thelloraCharges,true)
				if (rushTargetCombining < this.thelloraTarget AND MOD(rushTargetCombining,5)==0 AND MOD(this.GetThelloraTarget(thelloraCharges,false),5)!=0) ;If we are short on stacks and going to hit a boss, and not combining will land us on anything but a boss
				{
					g_IBM.levelManager.OverrideLevelByID(58,"z1c", true) ;Prevent Briv being levelled prior to completion of z1, breaking the combine
					g_IBM.Logger.AddMessage("Thellora: Broke combine to avoid hitting boss")
				}
			}
		}
		else
		{
			if(this.ThelloraBossAvoidance)
			{
				thelloraCharges:=Floor(g_Heroes[139].GetCappedRushCharges()) ;Floor as the part-charges are presented as decimals, eg 307.2 = 307 zones plus 20% of the way to another
				rushTargetNonCombining:=this.GetThelloraTarget(thelloraCharges,false)
				if (rushTargetNonCombining < this.thelloraTarget AND MOD(rushTargetNonCombining,5)==0 AND MOD(this.GetThelloraTarget(thelloraCharges,true),5)!=0) ;If we are short on stacks and going to hit a boss, and not combining will land us on anything but a boss
				{
					g_IBM.Logger.AddMessage("Thellora: Attempting to combine to avoid hitting boss")
					return
				}
			}
			g_IBM.levelManager.OverrideLevelByID(58,"z1c", true) ;Standard outcome: prevent Briv being levelled prior to completion of z1
		}
	}

	GetTargetStacksForFullRun(assumeStandardRush:=false) ;Returns the expected total stacks for a full run
	{
		rushNext:=assumeStandardRush ? 0 : g_Heroes[139].rushNext ;This is set by the prior UpdateLeftoverHaste() call
		if(rushNext)
			thelloraTarget:=this.GetThelloraTarget(rushNext,this.combining)
		else
			thelloraTarget:=this.thelloraTarget
		if(this.combining) ;We need to do one jump to reach ThelloraTarget in this case, and will leave the Casino on an M jump, not whatever fits the zone
		{
			jumps:=this.zones[thelloraTarget + this.zonesPerJumpM].jumpsToFinish + 2 ;1 for the combine, 1 for the M-jump after the Casino
			if(rushNext AND this.ThelloraBossAvoidance AND this.IsFeatSwap() AND this.zonesPerJumpM > this.zonesPerJumpE) ;If Thellora won't reach her target, we have boss recovery on, we are using feat swapping and the M jump would have been larger than an E jump, we need to generate an additional jump's worth of stacks, as replacing an M with an E would result in us needing 1 more jump Note: As this is a recovery mode trying to work out if the jump being replaced is Q or E doesn't seem worthwhile (it's made complex by her erratic behaviour if not in W)
			{
				jumps++
				g_IBM.Logger.AddThelloraCompensationMessage("GetTargetStacksForFullRun: Added extra jump for combining Thellora recovery for a total of: ",jumps)
			}
		}
		else if(g_Heroes[139].inM) ;Non-combined, but with Casino after the rush and so an M-jump after
		{
			jumps:=this.zones[thelloraTarget + this.zonesPerJumpM].jumpsToFinish + 1 ;1 for the M-jump after the Casino, no combine here
			if(rushNext AND this.ThelloraBossAvoidance AND this.IsFeatSwap()) ;As for combining, but will always be required as even if M=Q, we're only getting 1 standard zone completion when combining instead of 2 when separate, i.e. if M and Q are both 14J, we will replace 15 zones with 14, and potentially need an extra jump. This does highlight the limitations of this approach, as if normally landing after the reset this wouldn't be necessary - it is a recovery mode, however TODO: Could we check the previous zones's jumps to finish and make no adjustment if they are the same?
			{
				jumps++
				g_IBM.Logger.AddThelloraCompensationMessage("GetTargetStacksForFullRun: Added extra jump for non-combining Thellora recovery for a total of: ",jumps)
			}
		}
		else ;No M-jump
			jumps:=this.zones[thelloraTarget].jumpsToFinish ;Simple case
		return this.jumpCosts[jumps]
	}

	UpdateLeftoverHaste(forceRecalc:=false)
	{
		if (this.leftoverCalculated AND !forceRecalc)
			return
		else
		{
			g_Heroes[139].rushNext:=0
			calcResult:=this.UpdateLeftoverHaste_Calculate()
			this.leftoverHaste:=calcResult.haste
			if (g_Heroes[139].inA) ;If Thellora is in use
			{
				targetCharges:=g_Heroes[139].rushCap + (g_Heroes[139].inM ? 0 : 0.2) ;If Thellora is not in M she will not get credit for z1. Note we can't use this.ThelloraTarget as that includes a possible combined jump and the +1. TODO: Check for her presence in W here?
				currentCharges:=g_Heroes[139].ReadRushAreaCharges()
				remainingCharges:=MAX(0,targetCharges-currentCharges)
				if (calcResult.partialRun) ;We can't make the end of this run and will reset early. We need to work out if we need to get extra stacks to make up for Thellora's rush shortfall in the next run
				{
					zonesRemaining:=MAX(0,this.GetStackDepletionZone(calcResult.zone,calcResult.jumpsToDepletion)-calcResult.zone) ;TODO: Consider Thellora not being in W; possibly check if W has not already been used via comparing current changes to currentzone*5, and add a Q jump worth of zones if we still expect to stack. Hard to be precise, but it is a recovery mode
				}
				else
					zonesRemaining:=MAX(0,this.targetZone-calcResult.zone)
				if (zonesRemaining < remainingCharges*5)
				{
					g_Heroes[139].rushNext:=FLOOR(currentCharges + (zonesRemaining/5)) ;Number of charges she will have. Note the floor is required as this will be used as an array index and must be an INT as a result. The // operator returns a float because AHK is dumb. TODO: Like most the Thellora code, should read the feat
				}
				if (g_SF.Memory.ReadHighestZone()>=this.thelloraTarget) ;If we've calculated post-Thellora, don't do so again - whilst technically we could reduce jumps by drifting that is not something we plan to do!
					this.leftoverCalculated:=true
			}
			else
				this.leftoverCalculated:=true
		}
	}

	GetStackDepletionZone(zoneNumber,jumps)
	{
		while(jumps>0)
		{
			currentZone:=this.zones[zoneNumber]
			if (currentZone.jumpZone) ;On Q
			{
				nextZoneNumber:=currentZone.z+this.zonesPerJumpQ
				jumps--
			}
			else
			{
				nextZoneNumber:=currentZone.z+this.zonesPerJumpE
				if (this.zonesPerJumpE>1) ;If Briv is in E this also costs a jump
					jumps--
			}
			zoneNumber:=nextZoneNumber
		}
		return zoneNumber
	}

	UpdateLeftoverHaste_Calculate() ;Returns the number of haste stacks expected to remain at the end of this run, the number of jumps made at the point stacks will run out (normally 0), whether we will run out early, and the zone is also returned to further processing. Examples:
	;.haste=48, .partialRun=false, .jumpsToDepletion=0 and .zone=349 would mean we will expect to make it to the end, having done the calc on z349
	;.haste=48, .partialRun=true, .jumpsToDepletion=80 and .zone=501 would mean would mean we can jump 80 times, then will be out of stacks, having done the calculation on z501
	{
		calcResult:={}
		calcResult.haste:=g_Heroes[58].ReadHasteStacks()
		if (!g_SF.Memory.ReadTransitioning()) ;If we're not in a transition at all, we need to use the current zone as the next zone may be unlocked (eg if stacking) - TODO: Needs to go in a function, as it's used in EnoughHasteForCurrentRun() too
			calcResult.zone:=g_SF.Memory.ReadCurrentZone()
		else ;Use the highest zone, as we should have spent the stacks as we left the previous one
			calcResult.zone:=g_SF.Memory.ReadHighestZone()
		jumps:=this.zones[calcResult.zone].jumpsToFinish
		calcResult.jumpsToDepletion:=0
		calcResult.partialRun:=false
		if (jumps < 1) ;No stacks needed if no jumps required
		{
			return calcResult
		}
        while (jumps > 0)
        {
            if (calcResult.haste < 50) ;Won't jump with <50 stacks, script will in most cases abort the run when they run out
            {
				calcResult.partialRun:=true
				calcResult.jumpsToDepletion:=this.zones[calcResult.zone].jumpsToFinish - jumps
				return calcResult
			}
            calcResult.haste:=Round(calcResult.haste*0.968)
            jumps--
        }
        return calcResult
	}

	EnoughHasteForCurrentRun() ;True if we have enough haste stacks to complete the run
	{
		if (!g_SF.Memory.ReadTransitioning()) ;If we're not in a transition at all, we need to use the current zone as the next zone may be unlocked (eg if stacking)
			zone:=g_SF.Memory.ReadCurrentZone()
		else ;Use the highest zone, as we should have spent the stacks as we left the previous one
			zone:=g_SF.Memory.ReadHighestZone()
		return g_Heroes[58].ReadHasteStacks() >= this.zones[zone].stacksToFinish
	}

	ShouldOfflineStack()
    {
        if (this.HybridBlankOffline) ;This logic is not used if we are doing blank offlines
			return false
		else if (this.cycleForceOffline) ;Force offline takes priority, as it will often be used with offline disabled below
			return true
		else if (this.cycleDisableOffline)
			return false
		else if (this.cycleMax==1) ;Hybrid disabled
            return true
        else if (this.cycleCount>=this.cycleMax) ;Hybrid offline
			return true
		else ;Stack online
			return false
    }

	ExpectingGameRestart()
	{
		return this.ShouldOfflineStack() OR this.ShouldBlankRestart()
	}

	ShouldBlankRestart() ;This is run-based intent, other conditions (per TestForBlankOffline()) may cause a different result
	{
		return this.HybridBlankOffline AND (this.cycleCount>=this.cycleMax OR this.cycleForceOffline) AND (!this.cycleDisableOffline OR this.cycleForceOffline)
	}

	TestForBlankOffline(currentZone)
	{
		if ((this.ShouldBlankRestart() AND this.EnoughHasteForCurrentRun()) OR (this.RelayBlankOffline AND this.RelayData.IsActive())) ;Do not attempt relay if we don't have enough haste to complete the run, as that will require a forced restart. Once we start the relay manager, we are committed
		{
			if (currentZone>g_IBM_Settings["IBM_Offline_Stack_Zone"]) ;CycleCount will be reset on return from offline, so this will only trigger once
				this.BlankRestart()
			else if (this.RelayBlankOffline AND !this.RelayData.HasTriggered()) ;Check for relay only if it isn't already active
			{
				if (currentZone>=this.RelayData.relayZone) ;At or beyond relay start zone
					this.RelayData.Start()
			}
		}
	}

	BlankRestart() ;Restart without stacking TODO: Can we check for offline progress to detect resets here, in case of unwanted autoprogress?
    {
		if(g_IBM_Settings["IBM_OffLine_Blank_Stop"])
			this.ToggleAutoProgress(0,false,true)
		startStacks:=g_Heroes[58].ReadSBStacks()
		offlineStartTime:=A_TickCount
		startZone:=g_SF.Memory.ReadCurrentZone() ; record current zone before saving for bad progression checks
		g_IBM.Logger.AddMessage("BlankRestart Entry:z" . startZone)
		g_IBM.GameMaster.CloseIC("BlankRestart",this.RelayBlankOffline) ;2nd arg is to use PID only, so we don't close the relay copy of the game when in that mode
		if(this.RelayBlankOffline)
		{
			g_IBM.Logger.AddMessage("BlankRestart() returning game in Relay mode")
			this.RelayData.Release()
			g_IBM.routeMaster.ResetCycleCount() ;TODO: Do these make sense here? Might need to be after picked up
		}
		else ;The sleep is to allow launcher like EGS to detect the game has closed, but that is not applicable to relay (which can't use the EGS launcher)
		{
			if (g_IBM_Settings["IBM_OffLine_Sleep_Time"])
			{
				g_SharedData.UpdateOutbound("LoopString","BlankRestart: Sleep")
				ElapsedTime:=0
				while (ElapsedTime < g_IBM_Settings["IBM_OffLine_Sleep_Time"])
				{
					g_SharedData.UpdateOutbound("LoopString","BlankRestart Sleep: " . g_IBM_Settings["IBM_OffLine_Sleep_Time"] - ElapsedTime)
					g_IBM.IBM_Sleep(15)
					ElapsedTime:=A_TickCount
				}
			}
		}
		g_IBM.GameMaster.SafetyCheck() ;TODO: Does this do more harm than good during Blank offlines? It can potentially swap the process back to the wrong one if the window is still in existance? Need to roll our own for the blank codepath? Possibly needs to be changed for all runs
		totalTime:=A_TickCount-offlineStartTime
		generatedStacks:=g_Heroes[58].ReadSBStacks() - startStacks
		returnZone:=g_SF.Memory.ReadCurrentZone()
		if(returnZone<startZone) ;We've gone backwards, this is expected as we don't stop autoprogress, although it can also happen if the exit save fails
		{
			g_IBM.RollBackAction(returnZone)
			g_IBM.Logger.AddMessage("BlankRestart() Exit Rollback Detected,Start@z" . startZone . ",End@z" . returnZone . "," . generatedStacks . ",Time:" . totalTime . ",OfflineTime:" . g_SF.Memory.ReadOfflineTime() . ",Server:" . g_SF.Memory.IBM_GetWebRootFriendly())
		}
		else
			g_IBM.Logger.AddMessage("BlankRestart() Exit, End@z" . returnZone . "," . generatedStacks . ",Time:" . totalTime . ",OfflineTime:" . g_SF.Memory.ReadOfflineTime() . ",Server:" . g_SF.Memory.IBM_GetWebRootFriendly())
        if(g_IBM_Settings["IBM_OffLine_Blank_Stop"])
			this.ToggleAutoProgress(1,false,true)
		g_SharedData.UpdateOutbound("IBM_RunControl_StackString","Restarted at z" . returnZone . " in " . Round(totalTime/ 1000,2) . "s")
		g_IBM.PreviousZoneStartTime:=A_TickCount
    }

	TestForSteelBonesStackFarming() ;Returns true if we have a failure, namely the out of stacks and need to force restart case. TODO: Are we covering needing to stack at the recovery minimum when only offline stacking?
    {
		currentZone:=g_SF.Memory.ReadCurrentZone()
        if (currentZone < 0 OR currentZone>=this.targetZone) ;Don't test while modron resetting
            return 0
		stacks:=g_Heroes[58].ReadSBStacks()
		targetStacks:=this.GetTargetStacks()
 		if (stacks<targetStacks)
		{
			shouldOffline:=this.ShouldOfflineStack()
			if(shouldOffline AND currentZone>=g_IBM_Settings["IBM_Offline_Stack_Zone"]) ;This is now >= so we don't have to go around taking 1 off the stackzone all the time
			{
				this.StackRestart()
				this.StartAutoProgressSoft()
				return 0
			}
			else if (!shouldOffline AND !this.PostponeStacking(currentZone)) ;TODO: Bit silly to have to invert this, change to 'AllowStacking()' or something
			{
				this.OnlineStacker.Stack()
				return 0
			}
		}
        ;Briv ran out of jumps but has enough stacks for a new adventure => restart adventure. With protections from repeating too early. Irisiri - changed >z10 to >Thell target, but this will fail if Thell isn't present
		;04Jul25: Added check for transitioning, so we actually spend the last jump before resetting, otherwise we'll go as soon as the stacks are spent which is before we benefit from them
        if (g_Heroes[58].ReadHasteStacks()<50 AND stacks>=targetStacks AND g_SF.Memory.ReadHighestZone()>this.thelloraTarget AND g_SF.Memory.ReadHighestZone()<this.targetZone AND !g_SF.Memory.ReadTransitioning()) ;Removed the 5-zones-from-end check; if there's an armoured boss we'll not be able to be progress. TODO: With adventure-aware routing we could determine the last safe zone to walk from. Updated to not try and reset during relay restart (which shouldn't really happen since we don't blank if we don't have enough stacks...) Even more TODO: Should we check ReadAreaActive() here as well?
        {
            if (this.RelayBlankOffline AND this.RelayData.IsActive()) ;TODO: Something smart here
			{
				g_IBM.Logger.AddMessage("TestForSteelBonesStackFarming() force restart suppressed due to Relay")
			}
			else
			{
				g_IBM.Logger.AddMessage("Out of stacks:z" . currentZone)
				g_IBM.GameMaster.RestartAdventure("Out of Haste and have Steelbones for next")
				return 1
			}
        }
		return 0
    }

	ResetCycleCount()
	{
		this.cycleForceOffline:=false
		this.cycleCount:=0 ;Reset the count of runs in a cycle at offline. TODO: Could resetting this during the run cause problems? Might need to set a variable and process in Reset() - Note at this point the script expects this to happen
	}
	
	class IBM_Online_Stacker_Attacking extends IC_BrivMaster_RouteMaster_Class.IBM_Online_Stacker ;Trigger Fari's ult based
	{
		__New(RouteMaster)
		{
			Base.__New(RouteMaster)
			this.MEMORY_MELEE_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numAttackingMonstersReached.ValueType ;The types can't change, so store them up front
			this.MEMORY_RANGED_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numRangedAttackingMonsters.ValueType 
		}
		
		InitMemoryReads()
		{
			this.MEMORY_MELEE_ADDRESS:=g_SF.Memory.ResolvePointers(g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numAttackingMonstersReached)
			this.MEMORY_RANGED_ADDRESS:=g_SF.Memory.ResolvePointers(g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numRangedAttackingMonsters)
		}
		
		FaridehUltCheck(ByRef activateFariUlt)
		{
			if(_IBM_MM.instance.Read(this.MEMORY_MELEE_ADDRESS,this.MEMORY_MELEE_TYPE)+_IBM_MM.instance.Read(this.MEMORY_RANGED_ADDRESS,this.MEMORY_RANGED_TYPE)>=this.FaridehUltThreshold)
			{
				g_Heroes[33].UseUltimate(,true) ;Using ExitOnceQueued so we don't stay waiting for the activation and potentially overstack
				activateFariUlt:=0
				;++++++++++++++++++++++
				;START FARI DEBUG BLOCK
				;DllCall("QueryPerformanceCounter", "Int64*", loopTime)
				;DEBUG_FARI_LOG.="Ult Press(Att)," . Round(loopTime/g_IBM.CounterFrequency,3) . ","
				;END FARI DEBUG BLOCK
				;++++++++++++++++++++
			}
		}
	}
	
	class IBM_Online_Stacker_Tatyana_Return extends IC_BrivMaster_RouteMaster_Class.IBM_Online_Stacker
	{
		__New(RouteMaster)
		{
			Base.__New(RouteMaster)
			this.MEMORY_FAF_RETURN_TIMER_TYPE:=g_Heroes[97].MEMORY_FAF_RETURN_TIMER_TYPE
		}
		
		InitMemoryReads()
		{
			this.MEMORY_FAF_RETURN_TIMER_ADDRESS:=g_Heroes[97].GetFindAFeastReturnTimerAddress() ;Requires that Tatyana is fielded & levelled enough to have Find a Feast (80)
			this.FaridehUltThresholdGameTime:=this.FaridehUltThreshold/1000 ;Convert to seconds
		}
		
		FaridehUltCheck(ByRef activateFariUlt)
		{
			if(activateFariUlt==1) ;Waiting on timer being available
			{
				returnTime:=_IBM_MM.instance.Read(this.MEMORY_FAF_RETURN_TIMER_ADDRESS,this.MEMORY_FAF_RETURN_TIMER_TYPE)
				if(returnTime>0)
				{
					;++++++++++++++++++++++
					;START FARI DEBUG BLOCK
					;DllCall("QueryPerformanceCounter", "Int64*", loopTime)
					;this.DEBUG_FARI_LOG.="Ult prime," . Round(loopTime/g_IBM.CounterFrequency,3) . ",returnTime," . returnTime . ","
					;END FARI DEBUG BLOCK
					;++++++++++++++++++++
					if(returnTime<this.FaridehUltThresholdGameTime) ;If >0 but <threshold, use straight away
					{
						g_Heroes[33].UseUltimate(,true) ;Using ExitOnceQueued so we don't stay waiting for the activation and potentially overstack
						activateFariUlt:=0
						;++++++++++++++++++++++
						;START FARI DEBUG BLOCK
						;DllCall("QueryPerformanceCounter", "Int64*", loopTime)
						;this.DEBUG_FARI_LOG.="Ult Press(Taty-I)," . Round(loopTime/g_IBM.CounterFrequency,3) . ",returnTime," . returnTime . ","
						;END FARI DEBUG BLOCK
						;++++++++++++++++++++
					}
					else ;Otherwise prime for future call
						activateFariUlt:=2
				}
			}
			else if(_IBM_MM.instance.Read(this.MEMORY_FAF_RETURN_TIMER_ADDRESS,this.MEMORY_FAF_RETURN_TIMER_TYPE)<this.FaridehUltThresholdGameTime) ;FaridehUltCheck is not called if activateFariUlt=0, so it must be 2 in this case
			{
				g_Heroes[33].UseUltimate(,true) ;Using ExitOnceQueued so we don't stay waiting for the activation and potentially overstack
				activateFariUlt:=0
				;++++++++++++++++++++++
				;START FARI DEBUG BLOCK
				;DllCall("QueryPerformanceCounter", "Int64*", loopTime)
				;this.DEBUG_FARI_LOG.="Ult Press(Taty)," . Round(loopTime/g_IBM.CounterFrequency,3) . ",returnTime," . _IBM_MM.instance.Read(this.MEMORY_FAF_RETURN_TIMER_ADDRESS,this.MEMORY_FAF_RETURN_TIMER_TYPE) . ","
				;END FARI DEBUG BLOCK
				;++++++++++++++++++++
			}
		}
	}
	
	class IBM_Online_Stacker_Active_Enemies extends IC_BrivMaster_RouteMaster_Class.IBM_Online_Stacker
	{
		__New(RouteMaster)
		{
			Base.__New(RouteMaster)
		}
			
		InitMemoryReads()
		{
			this.MEMORY_ACTIVE_MONSTERS_SIZE_ADDRESS:=g_SF.Memory.ResolvePointers(g_SF.Memory.GameManager.game.gameInstances[0].Controller.area.activeMonsters.size)
		}
		
		FaridehUltCheck(ByRef activateFariUlt)
		{
			if(_IBM_MM.instance.Read(this.MEMORY_ACTIVE_MONSTERS_SIZE_ADDRESS,"Int")>=this.FaridehUltThreshold)
			{
				g_Heroes[33].UseUltimate(,true) ;Using ExitOnceQueued so we don't stay waiting for the activation and potentially overstack
				activateFariUlt:=0
				;++++++++++++++++++++++
				;START FARI DEBUG BLOCK
				;DllCall("QueryPerformanceCounter", "Int64*", loopTime)
				;this.DEBUG_FARI_LOG.="Ult Press(Act)," . Round(loopTime/g_IBM.CounterFrequency,3) . ","
				;END FARI DEBUG BLOCK
				;++++++++++++++++++++
			}
		}
	}
	
	class IBM_Online_Stacker ;Prototype to be extended for each Farideh ultimate activation method
	{
		__New(RouteMaster)
		{
			this.RM:=RouteMaster
			this.useFaridehUlt:=g_IBM.LevelManager.savedFormationChamps["W"].HasKey(33)
			if(this.useFaridehUlt)
			{
				g_Heroes[33] ;Ensure the object is created at start-up
				this.FaridehUltThreshold:=g_IBM_Settings["IBM_Online_Farideh_Threshold"]
			}
			this.useBrivBoost:=g_IBM_Settings["IBM_LevelManager_Boost_Use"]
			if (this.useBrivBoost)
				this.BrivBoost:=new IC_BrivMaster_BrivBoost_Class(g_IBM_Settings["IBM_LevelManager_Boost_Multi"])
		}
			
		InitMemoryReads() ;To be extended for each activation method
		{
			
		}
		
		FaridehUltCheck(ByRef activateFariUlt) ;To be extended for each activation method
		{

		}
		
		Stack()
		{
			targetStacks:=this.RM.GetTargetStacks(,true) ;Force recalculation of remaining haste stacks
			g_Heroes[58].InitFastSB()
			stacks:=g_Heroes[58].FastReadSBStacks()
			if(stacks>=targetStacks)
				return
			startStacks:=stacks
			this.RM.SetFormation() ;Ensure the correct formation is set for the zone before we stop progress and try to stack
			this.RM.ToggleAutoProgress(0,false,true)
			KEY:=this.RM.KEY_autoProgress
			DllCall("QueryPerformanceCounter", "Int64*", startTime) ;Start counting time from the point we stop autoprogress - SetFormation() is a normal part of zone completion	
			if(this.useFaridehUlt)
			{
				if(g_SF.Memory.ReadCurrentZone()<g_IBM_Settings["IBM_Online_Melf_Min"]) ;Avoid levelling Farideh in recovery - as a decent DPS she massively increases the stack zone, forcing us to walk much further
				{
					g_IBM.LevelManager.OverrideLevelByIDLowerToMax(33, "min", 0)
					activateFariUlt:=0
				}
				else
 					activateFariUlt:=1
			}
			gameSpeed:=g_SF.Memory.IBM_ReadBaseGameSpeed()
			this.Setup(activateFariUlt,15000/gameSpeed) ;Allow 1500ms at x10 for each state, 1200ms at x12.5
			if(activateFariUlt) ;InitMemoryReads must come after formation switch so Tatyana's effect handler is available
				this.InitMemoryReads()
			g_SharedData.UpdateOutbound("LoopString","Online Stack")
			maxOnlineStackTime:=(200000*g_IBM.CounterFrequency)/gameSpeed ;Reduces the 200s to 16s @ 12.5. Factoring the CounterFrequency in here means we can avoid doing it every loop
			if(g_IBM.failedConversionMode) ;In this case we're probably killing things as we've levelled champions, allow significantly more time
				maxOnlineStackTime*=5
			elapsedTime:=0
			precisionMode:=false
			precisionTrigger:=Floor(targetStacks * 0.90) ;At a steady-state stack rate of 500/s, for 600 stacks this is 60 to go => ~120ms TODO: With the potential for attacks to get fired in salvos is this too low?
			currentZone:=g_SF.Memory.ReadCurrentZone() ;Used to report the stack zone, here as it is recorded before we toggle progress back on
			/*
			;++++++++++++++++++++++
			;START FARI DEBUG BLOCK
			EK_HANDLER:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[g_Heroes[33].HeroIndex].effects.effectKeysByHashedKeyName
			EK_HANDLER_SIZE:=EK_HANDLER.size.Read()
			DEBUG_FARI_READ:=""
			DEBUG_FARI_READ_DEBUFFS:=""
			loop, %EK_HANDLER_SIZE%
			{
				PARENT_HANDLER:=EK_HANDLER["value", A_Index - 1].List[0].parentEffectKeyHandler
				if ("farideh_infernal_aspect_handler"==PARENT_HANDLER.def.Key.Read())
				{
					DEBUG_FARI_READ:=PARENT_HANDLER.activeEffectHandlers[0].QuickClone()
					DEBUG_FARI_READ.FullOffsets.Push(192)
					DEBUG_FARI_READ_DEBUFFS:=PARENT_HANDLER.activeEffectHandlers[0].QuickClone()
					DEBUG_FARI_READ_DEBUFFS.FullOffsets.Push(184,64) ;184 for dictionary, 64 for size property
					Break
				}
			}
			DllCall("QueryPerformanceCounter", "Int64*", loopTime)
			this.DEBUG_FARI_LOG:="Fari Init," . Round(loopTime/g_IBM.CounterFrequency,3) . ",S," . g_Heroes[58].FastReadSBStacks() . ","
			DEBUG_FARI_ALT_ACTIVE:=FALSE
			MEMORY_MELEE_ADDRESS:=_IBM_MM.instance.getAddressFromOffsets(g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numAttackingMonstersReached.BasePtr.BaseAddress,g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numAttackingMonstersReached.FullOffsets*)
			MEMORY_MELEE_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numAttackingMonstersReached.ValueType
			MEMORY_RANGED_ADDRESS:=_IBM_MM.instance.getAddressFromOffsets(g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numRangedAttackingMonsters.BasePtr.BaseAddress,g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numRangedAttackingMonsters.FullOffsets*)
			MEMORY_RANGED_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.numRangedAttackingMonsters.ValueType
			DEBUG_FARI_ZONE_FULL:=false
			DEBUG_FARI_ZONE_100_ACTIVE:=false
			DEBUG_100_ACTIVE_TIME:=0
			MEMORY_ACTIVE_MONSTERS_SIZE_ADDRESS:=g_SF.Memory.ResolvePointers(g_SF.Memory.GameManager.game.gameInstances[0].Controller.area.activeMonsters.size)
			;END FARI DEBUG BLOCK
			;++++++++++++++++++++
			*/
			while(stacks<targetStacks AND elapsedTime<maxOnlineStackTime)
			{
				if(activateFariUlt) ;Avoid the function call if not needed
					this.FaridehUltCheck(activateFariUlt)
				if (precisionMode OR activateFariUlt) ;This will mean if we never reach the FaridehUltThreshold we will be stuck on fast sleeps and not trigger the .gameFocus(). That being a problem requires 2 failures though, and we shouldn't have lost focus since the formation switch in general, so is probably okay
					DllCall("Sleep", "UInt", 0)
				else
				{
					if (stacks>precisionTrigger) ;Once we have hit precisionTrigger stacks go critical and check faster to get maximum precision
					{
						Critical On
						g_InputManager.gameFocus() ;Set Game Focus so we don't have to do it when releasing from the stack (this will cause issues if the game loses focus in the last few hundred ms of stacking)
						precisionMode:=true
					}
					DllCall("Sleep", "UInt", 10)
					;++++++++++++++++++++++
					;START FARI DEBUG BLOCK
					;DllCall("Sleep", "UInt", 0) ;FARI DEBUG - So as to not delay the debug checks
					;END FARI DEBUG BLOCK
					;++++++++++++++++++++
				}
				DllCall("QueryPerformanceCounter","Int64*",loopTime)
				elapsedTime:=loopTime-startTime
				stacks:=g_Heroes[58].FastReadSBStacks()
				/*
				;++++++++++++++++++++++
				;START FARI DEBUG BLOCK
				;T_await:=DEBUG_TATYANA_AWAIT_TIMER.Read("Double")
				;if(T_await)
				;this.DEBUG_FARI_LOG.="Taty:" Round(loopTime/g_IBM.CounterFrequency,3) . ":Await:" . DEBUG_TATYANA_AWAIT_TIMER.Read("Double") . ","
				DllCall("QueryPerformanceCounter","Int64*",loopTime)
				DEBUG_FARI_ULT_NOW:=DEBUG_FARI_READ.Read("Char")
				if(DEBUG_FARI_ULT_NOW!=DEBUG_FARI_ALT_ACTIVE)
				{
					debuffCount:=DEBUG_FARI_READ_DEBUFFS.Read("Int")
					if(DEBUG_FARI_ULT_NOW)
					{
						DEBUG_100_TO_ULT_FIRE:=(loopTime - DEBUG_100_ACTIVE_TIME)/g_IBM.CounterFrequency
						this.DEBUG_FARI_LOG.="Fari Ult Start," . Round(loopTime/g_IBM.CounterFrequency,3) . ",S," . stacks . ",Debuffs," . debuffCount . ",100toStart," . Round(DEBUG_100_TO_ULT_FIRE,3) . ","
					}
					else
						this.DEBUG_FARI_LOG.="Fari Ult End," . Round(loopTime/g_IBM.CounterFrequency,3) . ",S," . stacks . ",Debuffs," . debuffCount . ","
					DEBUG_FARI_ALT_ACTIVE:=DEBUG_FARI_ULT_NOW
				}
				;DllCall("QueryPerformanceCounter","Int64*",loopTime)
				;if(!DEBUG_FARI_ZONE_FULL AND _IBM_MM.instance.Read(MEMORY_MELEE_ADDRESS,MEMORY_MELEE_TYPE) + _IBM_MM.instance.Read(MEMORY_RANGED_ADDRESS,MEMORY_RANGED_TYPE)>=100)
				;{
				;	debuffCount:=DEBUG_FARI_READ_DEBUFFS.Read("Int")
				;	this.DEBUG_FARI_LOG.="Fari 100 Atk," . Round(loopTime/g_IBM.CounterFrequency,3) . ",S," . stacks . ",Debuffs," . debuffCount . ","
				;	DEBUG_FARI_ZONE_FULL:=true
				;}
				DllCall("QueryPerformanceCounter","Int64*",loopTime)
				if(!DEBUG_FARI_ZONE_100_ACTIVE AND _IBM_MM.instance.Read(MEMORY_ACTIVE_MONSTERS_SIZE_ADDRESS,"Int")>=100)
				{
					DEBUG_100_ACTIVE_TIME:=loopTime
					debuffCount:=DEBUG_FARI_READ_DEBUFFS.Read("Int")
					this.DEBUG_FARI_LOG.="Fari 100 Act," . Round(loopTime/g_IBM.CounterFrequency,3) . ",S," . stacks . ",Debuffs," . debuffCount . ","
					DEBUG_FARI_ZONE_100_ACTIVE:=true
				}
				;END FARI DEBUG BLOCK
				;++++++++++++++++++++				
				*/
			}
			;++++++++++++++++++++++
			;START FARI DEBUG BLOCK
			;DllCall("QueryPerformanceCounter", "Int64*", loopTime)
			;debuffCount:=DEBUG_FARI_READ_DEBUFFS.Read("Int")
			;this.DEBUG_FARI_LOG.="Fari Stacked," . Round(loopTime/g_IBM.CounterFrequency,3) . ",S," . stacks . ",Debuffs," . debuffCount . ","
			;END FARI DEBUG BLOCK
			;++++++++++++++++++++
			KEY.KeyPress_Bulk() ;Enable autoprogress as fast as we can. If we're stuck the following will handle it. Using _Bulk for this reason-game focus is set when precision is turned on
			;++++++++++++++++++++++
			;START FARI DEBUG BLOCK
			;g_IBM.Logger.AddMessage(this.DEBUG_FARI_LOG)
			;END FARI DEBUG BLOCK
			;++++++++++++++++++++
			if(ElapsedTime>=maxOnlineStackTime)
			{
				Critical Off
				g_IBM.GameMaster.RestartAdventure("Online stack took too long (" . ROUND(ElapsedTime/(g_IBM.CounterFrequency*1000),1) . "s)")
				g_IBM.GameMaster.SafetyCheck()
				g_IBM.PreviousZoneStartTime:=A_TickCount
				return
			}
			g_IBM.PreviousZoneStartTime:=A_TickCount
			runComplete:=g_SF.Memory.ReadHighestZone()>=this.RM.targetZone ;If we'll jump from stack zone straight to reset zone things get a bit weird as the game behaves differently transitioning to the reset zone
			if (!runComplete AND g_SF.Memory.ReadQuestRemaining()>0)
			{
				g_IBM.Logger.AddMessage("Online stack zone not complete - falling back")
				this.RM.FallBackFromZone()
			}
			else
				this.RM.ToggleAutoProgress(1, false, true)
			Critical Off
			generatedStacks:=stacks-startStacks
			g_SharedData.UpdateOutbound("IBM_RunControl_StackString","Stacking: Completed online at z" . currentZone . " generating " . generatedStacks . " stacks in " . Round(ElapsedTime/g_IBM.CounterFrequency,0) . "ms")
			g_IBM.Logger.AddMessage("Online{z" . currentZone . " Tar=" . targetStacks . " Gen=" . generatedStacks . "}," . g_Heroes[58].FastReadSBStacks() . "," . ROUND(ElapsedTime/g_IBM.CounterFrequency,0))
			if (!runComplete)
			{
				this.RM.SetFormation(,true) ;Use the high zone, as the current zone is complete
				this.RM.WaitForTransition() ;Wait for the zone transition so that a normal SetFormation() doesn't overwrite the highzone call
			}
		}
				
		Setup(expectFari,timeOut:=1000)
		{
			fastLevelList:=this.GetFastLevelList()
			MEMORY_QUEST_ADDRESS:=g_SF.Memory.ResolvePointers(g_SF.Memory.GameManager.game.gameInstances[0].ActiveCampaignData.currentArea.QuestRemaining)
			MEMORY_QUEST_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].ActiveCampaignData.currentArea.QuestRemaining.ValueType
			KEY_W:=this.RM.KEY_W
			this.RM.WaitForTransition()
			endTime:=A_TickCount+timeOut
			active:=g_SF.Memory.ReadAreaActive()
			while(!active AND A_TickCount<endTime) ;Wait for the zone to become active. The zone should complete ~35ms later at 12.5x, so we can briefly use a faster loop there without thrashing our CPU too much
			{
				DllCall("Sleep", "UInt", 1)
				active:=g_SF.Memory.ReadAreaActive()
			}
			endTime:=A_TickCount+timeOut ;Reset end time, this is applied once - if one fastLevelList times out the rest need to as well
			quest:=_IBM_MM.instance.Read(MEMORY_QUEST_ADDRESS,MEMORY_QUEST_TYPE)
			for _,Hero in fastLevelList
			{
				while(quest>0 AND A_TickCount<endTime)
				{
					quest:=_IBM_MM.instance.Read(MEMORY_QUEST_ADDRESS,MEMORY_QUEST_TYPE) ;No delay, single read - we want to catch completion as closely as possible
				}
				KEY_W.KeyPress_Bulk() ;Trying _Bulk here as we just stopped progress
				loopCount:=0
				while(!Hero.ReadSelectedInSeat() and loopCount<12) ;TODO: On my desktop usually managed by 8 *before* swap improvements were made - so this should be plenty, but probably needs checking on a slower system
				{
					if(loopCount) ;As there's no sleep before the first loop, avoid sending an immediate second input - we could potentially use an initial 'if' block to avoid this check, but whether it matters much will depend on how often it actually gets run
						KEY_W.KeyPress_Bulk()
					loopCount++
				}
				if (Hero.Current.UseModifierForFast)
				{
					g_IBM.LevelManager.SetModifierKey(true)
					Hero.Key.KeyPress_Bulk()
					g_IBM.LevelManager.SetModifierKey(false) ;TODO: if the next hero needs modifier as well this is a waste
				}
				else
					Hero.Key.KeyPress_Bulk()
			}
			if(quest>0) ;If the fast handlers didn't wait for quest completion (e.g. because there were none)
			{
				while(quest>0 AND A_TickCount<endTime) 
				{
					DllCall("Sleep", "UInt", 1) ;Sleep in this version as no massive rush to deploy champions
					quest:=_IBM_MM.instance.Read(MEMORY_QUEST_ADDRESS,MEMORY_QUEST_TYPE)
				}
				KEY_W.KeyPress_Bulk()
			}
			startTime:=A_TickCount
			elapsedTime:=0
			g_SharedData.UpdateOutbound("LoopString","Setting stack farm formation")
			while(!this.FormationCheckWithFari(expectFari) AND elapsedTime<timeOut) ;TODO: We might want to make a check that returns true if the formation is selected, either on field or in their bench seat, as this will fail if someone doesn't get placed after levelling due to the formation being under attack
			{
				KEY_W.KeyPress() ;Not using _Bulk here as the swap here is a failure mode
				g_IBM.levelManager.LevelFormation("W","min",0)
				DllCall("Sleep", "UInt", 10)
				elapsedTime:=A_TickCount - startTime
			}
			if(elapsedTime>=timeOut)
			{
				g_IBM.Logger.AddMessage("FAIL: Online Stack Setup() did not set W formation within " . timeOut . "ms")
				g_IBM.Logger.AddMessage("DEBUG: Fari Level=[" . g_Heroes[33].ReadLevel() . "] Formation=" . this.DEBUG_FORMATION_STRING())
			}
			if (this.useBrivBoost) ;Should this be moved before StackFarmSetup()? Or possibly into StartFarmSetup(this.useBrivboost) (as online only) - we want the first W press to occur before we start doing Other Stuff so the formation switch happens ASAP
				this.BrivBoost.Apply()
			g_IBM.levelManager.LevelFormation("W", "min") ;Ensures we're levelled, and applies any changes made based by Briv Boost if used
		}
		
		FormationCheckWithFari(faridehRequired:=false) ;True if the formations exactly match, EXCEPT for Farideh (33), who is ignored if faridehRequired=false, or if true she must be present, but in any slot. TODO: Might be best to change this to only check Briv is alone in the first column, and the required champions are present otherwise?
		{
			w:=g_IBM.levelManager.GetFormation("W")
			currentFormation:=g_SF.Memory.GetCurrentFormation()
			fariFound:=false
			if(!IsObject(currentFormation))
				return false
			loop, % currentFormation.Count()
			{
				if(currentFormation[A_Index]==33) ;Fari, set flag but do any further checks since we don't care where she is. Note this means Fari could have taken the place of another champion who is not placed, but we shouldn't be levelling most champions in W
				{
					fariFound:=true
				}
				else ;Fari might still be in this spot in the W formation, in which case ignore her
				{
					if(w[A_Index]!=currentFormation[A_Index] AND w[A_Index]!=33) ;Ignore if the W match is Fari
						return false
				}
			}
			return !faridehRequired OR fariFound
		}
		
		GetFastLevelList()
		{
			fastLevelList:={} ;Champions to be levelled at the start of the formation swap to W
			for heroID,_ in g_IBM.LevelManager.savedFormationChamps["XW"] ;eXclusive W
			{
				if(g_Heroes[heroID].NeedsLevelling())
				{
					if (g_Heroes[heroID].GetLevelsRequired() < 100)
						g_Heroes[heroID].Current.UseModifierForFast:=true ;Modifier press TODO: If this works out, encapsulate it better?
					else
						g_Heroes[heroID].Current.UseModifierForFast:=false ;Normal press
					fastLevelList.Push(g_Heroes[heroID])
				}
			}
			return fastLevelList
		}
		
		DEBUG_FORMATION_STRING() ;Returns the formation size and members as a string TODO: Decide if this should be a standard part of the fail log message and if so, rename accordingly
		{
			size:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.slots.size.Read()
			if(size<=0 OR size>14) ;Sanity check
				return "X:[]"
			formation:=":["
			champCount:=0
			loop, %size%
			{
				heroID:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.slots[A_index - 1].hero.def.ID.Read()
				if (heroID>0)
					champCount++
				else
					heroID:="_"
				formation.=heroID . ";"
			}
			formation:=champCount . formation . "]"
			return formation
		}
	}

	PostponeStacking(currentZone) ;Used to delay stacking whilst waiting for the target stack zone and preferred stacking zone
    {
        if(currentZone<g_IBM_Settings["IBM_Offline_Stack_Min"]) ;Never attempt to stack below minimum recovery stack zone
			return true
		if (g_Heroes[58].ReadHasteStacks()<50) ;Stack immediately if Briv can't jump
            return false
		if (currentZone>this.LastSafeStackZone) ;Stack immediately to avoid resetting before stacking
			return false
		if(currentZone<g_IBM_Settings["IBM_Online_Melf_Min"]) ;Below target minimum online zone (legacy setting - bad name). Here as this will be called once we pass the recovery minimum
			return true
		if (this.zones[currentZone].stackZone==false)
			return true
		return false
    }

	GetLastSafeStackZone()
    {
        lastZone:=this.targetZone - 1
        ; Move back one zone if the last zone before reset is a boss.
        if (Mod(lastZone,5)==0)
            lastZone--
        return lastZone - this.zonesPerJumpQ
    }

    ShouldAvoidRestack(stacks, targetStacks) 	; avoids attempts to stack again after stacking has been completed and level not reset yet.
    {
        if ( stacks >= targetStacks )
            return 1
        if (g_SF.Memory.ReadCurrentZone() == 1) ; likely modron has reset
            return 1
        if (g_SF.Memory.ReadCurrentZone() < g_IBM_Settings["IBM_Offline_Stack_Min"]) ; don't stack below min stack zone ;TODO: Is this useful?
            return 1
        return 0
    }

	StackRestart() ;TODO: Put rollback detection back into this?
    {
		startStacks:=lastStacks:=stacks:=g_Heroes[58].ReadSBStacks()
		targetStacks:=this.GetTargetStacks(,true) ;Force recalculation of remaining haste stacks
        if (this.ShouldAvoidRestack(stacks, targetStacks))
        {
			return
		}
        retryAttempt := 0
        if (this.cycleMax == 1) ;If doing hybrid we should never retry - the purpose of going offline is to clear memory bloat, and that is fulfilled whether we stack or not
			maxRetries:= 2
		else
			maxRetries:=0
		offlineStartTime:=A_TickCount
        while (stacks < targetStacks AND retryAttempt <= maxRetries )
        {
			this.StackFailRetryAttempt++ ; per run
            retryAttempt++               ; pre stackfarm call
            this.StackFarmSetup()
            if (this.targetZone != "" AND g_SF.Memory.ReadCurrentZone() > this.targetZone)
            {
                g_SharedData.UpdateOutbound("LoopString","Attempted to offline stack after modron reset - verify settings")
                break
            }
			this.offlineSaveTime:=g_IBM.GameMaster.CloseIC( "StackRestart" . (this.StackFailRetryAttempt > 1 ? (" - Warning: Retry #" . this.StackFailRetryAttempt - 1 . ". Check Stack Settings."): "") )
			g_SharedData.UpdateOutbound("LoopString","Stack Sleep: ")
            ElapsedTime:=0
			sleepStart:=A_TickCount ;Seperate to the save timer, this is the delay in restarting the game specifically
			while ( ElapsedTime < g_IBM_Settings["IBM_OffLine_Sleep_Time"] )
            {
                g_SharedData.UpdateOutbound("LoopString","Stack Sleep: " . g_IBM_Settings["IBM_OffLine_Sleep_Time"] - ElapsedTime)
                g_IBM.IBM_Sleep(15)
				ElapsedTime := A_TickCount - sleepStart
            }
			g_IBM.GameMaster.SafetyCheck()
            stacks:=g_Heroes[58].ReadSBStacks()
            ;check if save reverted back to below stacking conditions
            if (g_SF.Memory.ReadCurrentZone() < g_IBM_Settings["IBM_Offline_Stack_Min"])
            {
                g_SharedData.UpdateOutbound("LoopString","Stack Sleep: Failed (zone < min)")
                Break  ; "Bad Save? Loaded below stack zone, see value."
            }
            lastStacks:=stacks
			g_IBM.Logger.AddMessage("Offline:" . g_SF.Memory.ReadCurrentZone() . "," . stacks . ",Time:" . A_TickCount - this.offlineSaveTime . ",Attempt:" . retryAttempt . ",OfflineTime:" . g_SF.Memory.ReadOfflineTime() . ",Server:" . g_SF.Memory.IBM_GetWebRootFriendly())
			this.offlineSaveTime:=-1 ;Flags as not active
        }
        g_IBM.PreviousZoneStartTime:=A_TickCount
		generatedStacks:=g_Heroes[58].ReadSBStacks() - startStacks
		totalTime:=A_TickCount-offlineStartTime
		if (retryAttempt > maxRetries+1) ;We're a bit screwed at this point, +1 as retryAttempt is really 'tryAttempt'
        {
			g_SharedData.UpdateOutbound("LoopString","Failed to generate target " . targetStacks . " stacks in " . maxRetries . " attempts. Verify settings")
			g_SharedData.UpdateOutbound("IBM_RunControl_StackString","FAIL: Attempted to stack offline at z" . g_SF.Memory.ReadCurrentZone() . " generating " . generatedStacks . " stacks in " . Round(totalTime/ 1000,2) . "s" . (retryAttempt>1 ? " using " . retryAttempt . " attempts" : ""))
        }
        else
		{
			g_SharedData.UpdateOutbound("IBM_RunControl_StackString","Stacking: Completed offline at z" . g_SF.Memory.ReadCurrentZone() . " generating " . generatedStacks . " stacks in " . Round(totalTime/ 1000,2) . "s" . (retryAttempt>1 ? " using " . retryAttempt . " attempts" : ""))
		}
    }

	StackFarmSetup()
    {
		if (!this.KillCurrentBoss())
            this.FallBackFromBossZone()
        this.KEY_W.KeyPress()
        this.ToggleAutoProgress(0,false,true)
		g_IBM.levelManager.LevelFormation("W", "min")
		this.WaitForTransition(this.KEY_W)
		StartTime:=A_TickCount
        ElapsedTime:=0
		TimeOut:=5000
        g_SharedData.UpdateOutbound("LoopString","Setting stack farm formation")
        while (!this.FormationCheckWithFari() AND ElapsedTime < TimeOut)
        {
			this.KEY_W.KeyPress() ;Not using _Bulk here as the swap here is a failure mode
            g_IBM.levelManager.LevelFormation("W", "min") ;Should this be here?
			g_IBM.IBM_Sleep(15)
            ElapsedTime:=A_TickCount - StartTime
        }
		if (elapsedTime >= TimeOut)
			g_IBM.Logger.AddMessage("FAIL: StackFarmSetup() did not set W formation within " . TimeOut . "ms")
    }

	KillCurrentBoss(maxLoopTime:=25000)
    {
        currentZone := g_SF.Memory.ReadCurrentZone()
        if mod(currentZone, 5)
            return 1
        StartTime := A_TickCount
        ElapsedTime := 0
        g_SharedData.UpdateOutbound("LoopString","Killing boss before stacking")
        while ( !mod( g_SF.Memory.ReadCurrentZone(), 5 ) AND ElapsedTime<maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
            this.SetFormation()
            if(!g_SF.Memory.ReadQuestRemaining()) ; Quest complete, still on boss zone. Skip boss bag.
                this.ToggleAutoProgress(1,0,false)
            g_IBM.IBM_Sleep(50)
        }
        if(ElapsedTime >= maxLoopTime)
            return 0
        this.WaitForTransition()
        return 1
    }

	WaitForTransition(KEY:="", maxLoopTime:=5000) ;KEY is a IC_BrivMaster_InputManager_Key_Class object
    {
        if !g_SF.Memory.ReadTransitioning()
            return
        StartTime:=A_TickCount
        ;g_SharedData.UpdateOutbound("LoopString","Waiting for transition...") ;Not sure if this will generally be displayed long enough to be useful
        if (KEY)
			g_InputManager.gameFocus() ;Set focus once and use _Bulk()
		while (g_SF.Memory.ReadTransitioning()==1 AND A_TickCount - StartTime < maxLoopTime)
        {
			If (KEY)
				KEY.KeyPress_Bulk()
			g_IBM.IBM_Sleep(15)
        }
        return
    }

	FallBackFromBossZone(KEY:="", maxLoopTime:=5000)
    {
        fellBack:=false
        currentZone := g_SF.Memory.ReadCurrentZone()
        if (Mod(currentZone, 5))
            return fellBack
        StartTime:=A_TickCount
        ElapsedTime:=0
        g_SharedData.UpdateOutbound("LoopString","Falling back from boss zone")
        while (!Mod(g_SF.Memory.ReadCurrentZone(), 5) AND ElapsedTime < maxLoopTime)
        {
            this.KEY_LEFT.KeyPress()
			fellBack:=true
			g_IBM.IBM_Sleep(15)
			ElapsedTime:=A_TickCount - StartTime
        }
        this.WaitForTransition(KEY)
        return fellBack
    }

	FallBackFromZone(maxLoopTime:=5000)
    {
        StartTime:=A_TickCount
        ElapsedTime:=0
        while(g_SF.Memory.ReadCurrentZone()==-1 AND ElapsedTime < maxLoopTime)
        {
			g_IBM.IBM_Sleep(15)
			ElapsedTime:=A_TickCount-StartTime
        }
        currentZone:=g_SF.Memory.ReadCurrentZone()
        StartTime:=A_TickCount
        ElapsedTime:=0
        g_SharedData.UpdateOutbound("LoopString","Falling back from zone...")
        while(!g_SF.Memory.ReadTransitioning() AND ElapsedTime < maxLoopTime)
        {
            this.KEY_LEFT.KeyPress()
			g_IBM.IBM_Sleep(15) ;Sleep as we don't want to go back multiple zones
			ElapsedTime:=A_TickCount - StartTime
        }
        this.WaitForTransition()
    }

	SetFormation(fastCheck:=false,useHighZone:=false) ;To be called with FastCheck during straightforward progression, e.g. not after stacking, falling back, other fun things. Note we can't always use highZone because when a zone completes, the highzone is momentarily this+1 before the jump applies - if we can find a good check for that we could move over. ReadTransitioning() would appear to work as a test - if true, can use highzone safely, if false then?
    {
		static trustRecent:=false ;Do we believe that the ReadMostRecentFormationFavorite() is respresentative? Needed as it changes even if the formation swap fails
		if (!fastCheck)
			trustRecent:=false ;Reset to false for all normal calls
		isEZone:=this.ShouldWalk(useHighZone ? g_SF.Memory.ReadHighestZone() : g_SF.Memory.ReadCurrentZone())
		Thread, NoTimers ;Here to handle the animation skip, maybe isn't needed for feat swap as a result?
		benchReturn:=this.BenchBrivConditions(isEZone) ;check to bench briv
		lastFormation:=g_SF.Memory.ReadMostRecentFormationFavorite() ;New Sep25 read, used in all cases as it is part of the bad formation check
        if (benchReturn AND lastFormation!=3) ;New Sep25 read. Formation 3 is E
        {
			this.KEY_E.KeyPress()
			if (benchReturn==2)
			{
				if (this.zones[g_SF.Memory.ReadHighestZone()].jumpZone) ;Only put Briv back in urgently if we need to jump right away. Note this does not have to consider featswap because we'll never enter this block with Briv in E, as we can't animation skip in that case
				{
					g_IBM.IBM_Sleep(15) ;Avoid swapping back instantly, given issues with multiple key presses
					startTime:=A_TickCount
					while (g_SF.Memory.ReadFormationTransitionDir()==4 AND !g_Heroes[58].ReadBenched() AND (A_TickCount-startTime)<1000) ;Whilst we're in the transition and Briv is still on the field
					{
						g_IBM.IBM_Sleep(15)
					}
					this.KEY_Q.KeyPress_Bulk() ;_Bulk as follows the E.KeyPress()
					while (g_SF.Memory.ReadFormationTransitionDir()==4 AND (A_TickCount-startTime)<1000) ;Having gone back to Q, wait for the transition to end (so we don't swap Briv straight back out again) TODO: We could block via a static variable or something instead of sleeping here? Not that transitions take overly long
					{
						g_IBM.IBM_Sleep(15)
					}
				}
			}
			Thread, NoTimers, False
			return
        }
		else
			Thread, NoTimers, False
		;check to unbench briv
        if (this.UnBenchBrivConditions(isEZone) AND lastFormation!=1) ;Formation 1 is Q
        {
			this.KEY_Q.KeyPress()
			return
        }
		if (trustRecent AND fastCheck)
		{
			if !(lastFormation==1 OR lastFormation==3)
				isEZone ? this.KEY_E.KeyPress() : this.KEY_Q.KeyPress()
		}
		else
		{
			if !(g_SF.IsCurrentFormation(g_IBM.levelManager.GetFormation("Q")) OR g_SF.IsCurrentFormation(g_IBM.levelManager.GetFormation("E")))
				isEZone ? this.KEY_E.KeyPress() : this.KEY_Q.KeyPress()
			else
				trustRecent:=true ;As we've checked we're on Q or E via formation read, we should be in normal progression
		}
    }

	 ;Should be benched based on game conditions. As part of drift checking, return as follows:
	 ;0 - as false before, do not bench
	 ;1 - as true before for most conditions, bench
	 ;2 - bench for animation override
    BenchBrivConditions(isEZone)
    {
		;ReadTransitionDirection() 		| 0 = Static (instant), 1 = Forward, 2 = Backward, 3=JumpDown, 4=FallDown
		;ReadFormationTransitionDir() 	| 0 = OnFromLeft, 1 = OnFromRight, 2 = OnFromTop, 3 = OffToLeft, 4 = OffToRight, 5 = OffToBottom
		if (this.zonesPerJumpE == 1 AND g_SF.Memory.ReadTransitionDirection() == 1 AND g_SF.Memory.ReadFormationTransitionDir() == 4 )
			return 2
        if (isEZone)
			return 1
        return 0
    }

    UnBenchBrivConditions(isEZone) ;True/False on whether Briv should be unbenched based on game conditions.
    {
        if (isEZone)
            return false
		if (this.zonesPerJumpE > 1) ;Don't do transition-based checks when feat swapping
			return true ;Not a walk zone so go to Q
		if (g_SF.Memory.ReadFormationTransitionDir()!=4) ;if transition direction is not "OffToRight"
			return true
        return false
    }

	ShouldWalk(zone)
	{
		return this.zones[zone].jumpZone==False
	}

	GetStandardFormationKey(zone) ;Returns the key object for Q or E as appropriate for the zone
	{
		if (this.ShouldWalk(zone))
			return this.Key_E
		return this.KEY_Q
	}

	GetStandardFormation(zone) ;Returns Q or E formation from the level manager as appropriate for the zone
	{
		if (this.ShouldWalk(zone))
			return g_IBM.levelManager.GetFormation("E")
		return g_IBM.levelManager.GetFormation("Q")
	}

	LoadRoute() ;Once per script-run loading of the route
	{
		loop, % this.targetZone
		{
			if (!this.zones.hasKey(A_Index)) ;For most routes the majority will be calculated on the first iteration, with subsequent calls only populating a few zones until it meets the existing route
			{
				currentZone:=new IC_BrivMaster_RouteMaster_Zone_Class
				currentZone.z:=A_Index
				this.zones[A_Index]:=currentZone
				this.ProcessRoute(currentZone)
			}
		}
		;Pre-calculate the jumps, by looking at all the end nodes. This can be targetZone to targetZone + jump -1 (eg for 9J (10z/jump) to z1060, we can at most hit the reset by jumping from 1059 and hitting 1069)
		endZone:=this.targetZone
		while (endZone < this.targetZone + this.zonesPerJumpQ AND endZone <= this.zoneCap+1) ;Less than due to the above
		{
			if (this.zones.hasKey(endZone)) ;We can only jump beyond the reset, not walk, so not every zone in the range will be hittable (eg for 1069 above with 9J, 1059 must be a jump)
			{
				;OutputDebug % "`nendZone recurse:" . endZone . "`n"
				this.JumpsRecurse(this.zones[endZone],0) ;When combining we include the jump with Thellora as a baseline. This is so measuring to the thelloraTarget gives the true number of jumps (and jumps before Thellora don't have meaning)
			}
			endZone++
		}
	}

	JumpsRecurse(currentZone, startingJumps) ;Calculates the number of jumps from z1 to currentZone. TODO: Doing this by recursion seems to cause problems sometimes, do it in a fixed loop?
	{
		for _,inZone in currentZone.incomingZones
		{
			jumpsDone:=startingJumps
			if (inZone.jumpZone) ;jump on Q
			{
				jumpsDone++
				if (inZone.jumpsToFinish:=-1) ;Not yet processed
				{
					inZone.jumpsToFinish:=jumpsDone
					inZone.stacksToFinish:=this.jumpCosts[jumpsDone] ;Currently assuming Metalborn always
				}
			}
			else ;walk on E, or with feat swap jump on E
			{
				if (this.IsFeatSwap())
					jumpsDone++
				if (inZone.jumpsToFinish:=-1) ;Not yet processed
				{
					inZone.jumpsToFinish:=jumpsDone
					inZone.stacksToFinish:=this.jumpCosts[jumpsDone] ;Currently assuming Metalborn always
				}
			}
			this.JumpsRecurse(inZone, jumpsDone)
		}
	}

	ProcessRoute(currentZone) ;currentZone is the zone we are starting the the calculation from
	{
		while (currentZone.z < this.targetZone) ;Less than as we can't proceed from the reset zone
		{
			typeIndex:=MOD(currentZone.z,50)
			if (typeIndex==0)
				typeIndex:=50 ;Deal with the array being 1-indexed
			currentZone.jumpZone:=g_IBM_Settings["IBM_Route_Zones_Jump"][typeIndex]==1
			currentZone.stackZone:=g_IBM_Settings[ "IBM_Route_Zones_Stack" ][typeIndex]==1
			if (currentZone.jumpZone) ;On Q
				nextZoneNumber:=currentZone.z+this.zonesPerJumpQ
			else
				nextZoneNumber:=currentZone.z+this.zonesPerJumpE
			if (this.zones.hasKey(nextZoneNumber)) ;Already processed, just link
			{
				currentZone.nextZone:=this.zones[nextZoneNumber] ;Set the next zone
				this.zones[nextZoneNumber].incomingZones[currentZone.z]:=currentZone ;Add to the incoming zones
				break ;We've joined an existing route, so no further calculation required
			}
			else
			{
				nextZone:=new IC_BrivMaster_RouteMaster_Zone_Class
				nextZone.z:=nextZoneNumber
				nextZone.incomingZones[currentZone.z]:=currentZone
				currentZone.nextZone:=nextZone
				this.zones[nextZoneNumber]:=nextZone
			}
			currentZone:=nextZone
		}
	}

	BrivHasThunderStep() ;Thunder step 'Gain 20% More Sprint Stacks When Converted from Steelbones', feat 2131
	{
		If (g_SF.Memory.HeroHasAnyFeatsSavedInFormation(58, g_SF.Memory.GetSavedFormationSlotByFavorite(1)) or g_SF.Memory.IBM_HeroHasAnyFeatsSavedInFormation(58, g_SF.Memory.GetSavedFormationSlotByFavorite(3))) ;If there are feats saved in Q or E (which would overwrite any others in M)
		{
			thunderInQ:=g_SF.Memory.HeroHasFeatSavedInFormation(58, 2131, g_SF.Memory.GetSavedFormationSlotByFavorite(1))
			thunderInE:=g_SF.Memory.HeroHasFeatSavedInFormation(58, 2131, g_SF.Memory.GetSavedFormationSlotByFavorite(3))
			return (thunderInQ OR thunderInE)
		}
		else if (g_SF.Memory.HeroHasAnyFeatsSavedInFormation(58, g_SF.Memory.GetActiveModronFormationSaveSlot())) ;Briv has feats in M
			return g_SF.Memory.HeroHasFeatSavedInFormation(58, 2131 ,g_SF.Memory.GetActiveModronFormationSaveSlot())
		else ;Non-feat swap might not have feats saved in formations at all
		{
			feats:=g_SF.Memory.GetHeroFeats(58)
			for k, v in feats
				if (v==2131)
					return true
		}
		return false
	}

	; IsToggled is 0 for off or 1 for on. ForceToggle always hits G. ForceState will press G until AutoProgress is read as on (<5s).
    ToggleAutoProgress( isToggled := 1, forceToggle := false, forceState := false )
    {
        Critical, On
        StartTime:=A_TickCount
        if ( forceToggle )
            this.KEY_autoProgress.KeyPress()
        if ( g_SF.Memory.ReadAutoProgressToggled() != isToggled )
            this.KEY_autoProgress.KeyPress() ;Irisiri: If forceToggle is true, this will be a 2nd press without giving the game a chance to process?
        while ( g_SF.Memory.ReadAutoProgressToggled() != isToggled AND forceState AND A_TickCount - StartTime < 1000 )
        {
            this.KEY_autoProgress.KeyPress_Bulk()
			g_IBM.IBM_Sleep(15)
        }
        Critical, Off
    }
	
	StartAutoProgressSoft() ;Simplified autoprogress submission for optimising exit from stacking
	{
		if (g_SF.Memory.ReadAutoProgressToggled()!=1)
            this.KEY_autoProgress.KeyPress()
	}

	InitZone()
    {
        g_IBM.levelManager.LevelClickDamage()
        this.StartAutoProgressSoft()
        g_IBM.PreviousZoneStartTime:=A_TickCount
    }
}


class IC_BrivMaster_RouteMaster_Zone_Class ;A class representing a single zone
{
	z:=0
	nextZone:=""
	jumpZone:=false ;Jump or walk (or jump on Q vs jump on E for featswap)
	stackZone:=false ;Online stacking
	incomingZones:={} ;Zones which connect to this one (via walk or via jump), used to back-calculate costs
	jumpsToFinish:=-1
	stacksToFinish:=-1
}

class IC_BrivMaster_Relay_SharedData_Class ;Allows for communication between this main script and the Relay script
{
	/*
	States:
		0: Not running
		1: Main script has launched Relay
		2: Connected (Relay has accessed COM object)
		3: Game started
		4: Game started and Relay ended before platform login
		5: Game held after platform login
		6: Complete (any outcome)
		-1: Failed to launch
		-2: Failed to suspend (game will have started, current instance will be invalid)
	*/

	__New(relayClamp)
	{
		this.MEMORY_baseAddress:=g_SF.Memory.GameManager.game.gameUser.Loaded.basePtr.ModuleOffset + 0 ;Memory structure data for the reads we need TODO: This has been changed from the whole address to the module offset, since if the module moves in a new process the base address for the old one is worthless... Maybe rename throughout
		this.MEMORY_LOADED_Type:=g_SF.Memory.GameManager.game.gameUser.Loaded.valueType
		offSets:=g_SF.Memory.GameManager.game.gameUser.Loaded.GetOffsets() ;We need to turn this into a SafeArray for access via COM
		offsetSize:=offSets.Count()
		ArrayObj:=ComObjArray(12, offsetSize)
		loop %offsetSize%
			ArrayObj[A_Index-1]:=offSets[A_Index] ;Com Array is 0-indexed, vs AHK 1-indexed
		this.MEMORY_LOADED_Offsets:=ArrayObj
		this.LaunchCommand:=g_IBM_Settings["IBM_Game_Launch"]
		this.HideLauncher:=g_IBM_Settings["IBM_Game_Hide_Launcher"]
		this.ExeName:=g_IBM_Settings["IBM_Game_Exe"]
		this.relayZone:=MAX(g_IBM_Settings["IBM_OffLine_Blank_Relay_Zones"],relayClamp) ;Do not try and relay restart until after Thellora's jump
		this.Reset()
	}

	Reset()
	{
		this.RelayPID:=0
		this.RelayHwnd:=0
		this.HelperPID:=0
		this.State:=0
		this.RequestRelease:=false
	}

	Start()
	{
		if (this.State==0)
		{
			this.RelayPID:=0 ;Make sure things are reset
			this.RelayHwnd:=0
			this.HelperPID:=0
			this.RequestRelease:=false
			this.MainPID:=g_IBM.GameMaster.PID
			this.MainHwnd:=g_IBM.GameMaster.Hwnd
			this.RestoreWindow:=g_IBM_Settings["IBM_Route_Offline_Restore_Window"]
			scriptLocation := A_LineFile . "\..\IC_BrivMaster_RouteMaster_Relay.ahk"
			guid:=this.GUID
			Run, %A_AhkPath% "%scriptLocation%" "%guid%",,,helperPID
			g_IBM.Logger.AddMessage("Relay Start() ran helper script at z=[" . g_SF.Memory.ReadCurrentZone() . "] with PID=[" . helperPID . "]")
			this.HelperPID:=helperPID
			this.State:=1
		}
	}

	IsActive() ;Currently running
	{
		return this.State!=0 AND this.State!=6 ;Any any state but unstarted and complete
	}

	HasTriggered() ;Has been activated this run
	{
		return this.State!=0
	}

	PreRelease() ;Resume the process ASAP
	{
		if (this.State==5) ;Expected state, just resume process and move on
		{
			this.SuspendProcess(this.RelayPID,False)
			g_IBM.Logger.AddMessage("Relay PreRelease() state 5 - resuming")
		}
		else if (this.State==6) ;DEBUG: Relay is in a complete state. This might be possible during relay run recovery? TODO: This can be called when a second CloseIC() is called after the relay handover, e.g. because the run gets stuck
		{
			this.SuspendProcess(this.RelayPID,False)
			g_IBM.Logger.AddMessage("Relay PreRelease() state 6 - resuming - DEBUG")
		}
		else if (this.State>0) ;Request release
		{
			this.RequestRelease:=true
			g_IBM.Logger.AddMessage("Relay PreRelease() state 1 to 4 - request release")
		}
	}

	Release()
	{
		if (this.State==5) ;Expected state, just resume process and move on
		{
			this.SuspendProcess(this.RelayPID,False)
			this.ProcessSwap()
			g_IBM.Logger.AddMessage("Relay Release() state 5")
			this.State:=6 ;Complete
			return
		}
		else if (this.State==4) ;Never suspended, either because the relay missed the login, or because the main script asked the relay to abort via RequestRelease
		{
			this.ProcessSwap()
			g_IBM.Logger.AddMessage("Relay Release() state 4")
			this.State:=6 ;Complete
			return
		}
		else if (this.State==3 OR this.State==2) ;Relay started (2), and maybe started the game (3) but has yet to suspend it, in this case we need to take care that we don't get stuck by a race condition with the Relay suspending the process after we set RequestRequest:=true, but before it is read through the COM object
		{
			this.RequestRelease:=true
			g_IBM.Logger.AddMessage("Relay Release() state [" . this.State . "]")
			maxTime:=A_TickCount + 5000 ;Time for the relay to finish opening the game if necessary
			while (A_TickCount < maxTime)
			{
				if (this.State!=3 AND this.State!=2) ;Once the state changes re-call
				{
					g_IBM.Logger.AddMessage("Relay Release() state changed to [" . this.State . "] - recursing Release()")
					this.Release()
				}
				g_IBM.IBM_Sleep(15)
			}
			g_IBM.Logger.AddMessage("Relay Release() state [" . this.State . "] recursion exit or failed to detect state change")
			this.CleanUpOnFail()
		}
		else if (this.State==1) ;Relay never connected
		{
			g_IBM.Logger.AddMessage("Relay Release() state [" . this.State . "]")
			this.CleanUpOnFail()
		}
		else if (this.State==0 OR this.State==-1) ;We never actually started the relay, or it failed to start the game
		{
			g_IBM.Logger.AddMessage("Relay Release() state [" . this.State . "]")
			this.CleanUpOnFail()
		}
		else if (this.State==-2) ;Relay failed to stop the game after platform login, game should have been closed via RelayCloseMain() already
		{
			g_IBM.Logger.AddMessage("Relay Release() state [" . this.State . "]")
			this.ProcessSwap()
		}
		else
			g_IBM.Logger.AddMessage("Relay Release() with invalid state [" . this.State . "]")
		this.State:=6 ;Complete
	}
	
	SuspendProcess(PID,doSuspend:=True) ;Only used for the relay, as memory manager .suspend() / .resume() can be used for attached processes
	{
		h:=DllCall("OpenProcess","uInt",0x0800,"Int",0,"Int",PID)
		if (!h)
			return
		if (doSuspend)
			DllCall("ntdll.dll\NtSuspendProcess","Int",h)
		else
			DllCall("ntdll.dll\NtResumeProcess","Int",h)
		DllCall("CloseHandle","Int",h)
	}

	LogZone(message) ;DEBUG - remove later?
	{
		g_IBM.Logger.AddMessage("Relay LogZone() at z[" . g_SF.Memory.ReadCurrentZone() . "] message=[" . message . "]")
	}

	CleanUpOnFail()
	{
		if (g_SF.GetProcessName(this.HelperPID) == "AutoHotkey.exe") ;Kill the relay script
		{
			g_IBM.Logger.AddMessage("CleanUpOnFail() found Relay AHK script PID=[" . this.HelperPID . "] still running - killing")
			closeString:="ahk_pid " . this.HelperPID
			WinKill, %closeString% ;TODO: Should this use GameMaster.TerminateProcess?
		}
		WinGet, recoveryPID, PID, % "ahk_exe " . g_IBM_Settings["IBM_Game_Exe"] ;Check for IC processes
		if (recoveryPID)
		{
			g_IBM.Logger.AddMessage("CleanUpOnFail() recovery PID found=[" . recoveryPID . "]")
			g_IBM.GameMaster.PID:=recoveryPID
			this.SuspendProcess(g_IBM.GameMaster.PID,False) ;Ensure the process is not stuck suspended
			g_IBM.GameMaster.Hwnd:=WinExist("ahk_pid " . recoveryPID)
			g_SF.Memory.OpenProcessReader(recoveryPID) ;Open this PID specifically
			g_ServerCall.Update()
		}
		else ;Otherwise open as normal
		{
			g_IBM.GameMaster.OpenIC("CleanUpOnFail()")
		}
	}

	ProcessSwap()
	{
		logText:="ProcessSwap() changing PID=[" . g_IBM.GameMaster.PID . "] and Hwnd=[" . g_IBM.GameMaster.Hwnd . "] "
		g_IBM.GameMaster.PID:=this.RelayPID
		g_IBM.GameMaster.Hwnd:=this.RelayHwnd
		g_IBM.Logger.AddMessage(logText . "to PID=[" . g_IBM.GameMaster.PID . "] and Hwnd=[" . g_IBM.GameMaster.Hwnd . "]")
		g_SF.Memory.OpenProcessReader(g_IBM.GameMaster.PID)
		if (g_IBM.GameMaster.WaitForGameReady(10000*g_IBM_Settings["IBM_OffLine_Timeout"],true)) ;Default is 5, so 50s. Call WaitForGameReady() with skipFinal:=true as we won't know where in the offline calc we are if we happen to trigger one
			g_IBM.Logger.AddMessage("ProcessSwap() completed switching process")
		else
			g_IBM.Logger.AddMessage("ProcessSwap() WaitForGameReady() call failed whilst switching process")
		g_IBM.DialogSwatter.Start()
		g_ServerCall.Update()
		g_SharedData.UpdateOutbound("IBM_ProcessSwap",true) ;Allows the hub to react
	}

	RelayCloseMain() ;Called from the Relay script via COM to close the main IC process during recovery
	{
		g_IBM.GameMaster.CloseIC("Relay failed to halt at platform login",true) ;Close via PID
		this.Release()
	}
}

class IC_BrivMaster_BrivBoost_Class ;A class used to work out what level Briv needs to be to survive on a given zone
{

	__New(targetMulti)
	{
		this.BuildBrivLevelTable(130,{70:95,180:165,265:290,340:510,455:890,575:1560,695:2730,815:4775,935:7800,1050:14200,1170:24000,1300:42500})
		this.ZoneCache:={} ;Store results so we don't have to recalculate the same zone again
		this.DPSGrowthRateCurve:=g_SF.Memory.IBM_ReadDPSGrowthCurve()
		if (this.DPSGrowthRateCurve.Count()==0)
		{
			MSGBOX Briv Boost failed to read the DPS growth rate curve at adventure start. If this error persists please disable Briv Boost
			ExitApp
		}
		this.areaAndCampaignMonsterDamageMultiplier:=g_SF.Memory.IBM_ReadAreaMonsterDamageMultiplier()*g_SF.Memory.IBM_ReadCampaignMonsterDamageMultiplier()
		this.monsterBaseDPS:=g_SF.Memory.IBM_ReadMonsterBaseDPS()
		this.maxMonsters:=100
		this.overwhelmAdditivePenalty:=0.1
		this.targetMultiplier:=targetMulti ;If we exactly matched Briv's HP to enemy damage he would be one-shot as soon as we reached 100 enemies attaching . This factor allows us to survive that and some enrage. 8 seems to be good for a fast stack, might need a bit more for long ones
	}

	Apply()
	{
		currentLevel:=g_Heroes[58].ReadLevel()
		if (!currentLevel) ;If Briv is somehow unlevelled
			currentLevel:=0
		targetLevel:=this.GetBrivBoostTargetLevel(g_SF.Memory.ReadHighestZone(),currentLevel)
		if(targetLevel > currentLevel)
		{
			g_IBM.levelManager.OverrideLevelByIDRaiseToMin(58, "min", targetLevel)
			g_IBM.Logger.AddMessage("BrivBoost{C=" . currentLevel . " T=" . targetLevel . "}")
		}
	}

	GetBrivBoostTargetLevel(zone,currentLevel) ;This is the main function to be called when using this class
	{
		if (!this.ZoneCache.HasKey(zone))
			this.ZoneCache[zone]:=this.GetPreFlamesDamage(zone)
		flamesAdjusted:=this.ZoneCache[zone]*(2**g_Heroes[83].GetNumFlamesCards())
		brivHPMultiplier:=g_Heroes[58].ReadMaxHealth() / this.GetBrivBaseHPforLevel(currentLevel)
		targetBrivLevel:=this.GetBrivLevelForBaseHP(flamesAdjusted/brivHPMultiplier)
		targetBrivLevel100:=CEIL(targetBrivLevel/100)*100 ;Adjust for x100 levelling
		return targetBrivLevel100
	}

	GetPreFlamesDamage(zone) ;This takes the curve, area/campaign, monster totals and overwhelm into account (overwhelm should not change as we only check on W). It does not take Flames into account as that will vary
	{
		damage:=this.GetCurveValue(zone) ;Mimcing ComputeMonsterAttackDPS
		damage*=this.areaAndCampaignMonsterDamageMultiplier
		damage*=this.maxMonsters ;Monster count
		damage*=1+Max(this.maxMonsters-g_Heroes[58].ReadOverwhelm(),0)*this.overwhelmAdditivePenalty ;Overwhelm
		damage*=this.targetMultiplier ;HP margin factor
		return damage
	}

	GetBrivLevelForBaseHP(baseHP)
	{
		for level, HP in this.BrivLevelTable
		{
			if (HP>=baseHP)
				return level
			maxlevel:=level
		}
		return maxlevel
	}

	GetBrivBaseHPforLevel(brivLevel)
	{
		for level, HP in this.BrivLevelTable
		{
			if (level<=brivLevel)
				lastHP:=HP
			else
				break
		}
		return lastHP
	}

	GetCurveValue(index)
	{
		result:=this.monsterBaseDPS
		Loop % this.DPSGrowthRateCurve.Count()
		{
			i:=A_Index
			if (this.DPSGrowthRateCurve[i].level>index)
				break
			value:=this.DPSGrowthRateCurve[i].value
			num:=(i!=this.DPSGrowthRateCurve.Count AND index > this.DPSGrowthRateCurve[i+1].level) ? this.DPSGrowthRateCurve[i+1].level - this.DPSGrowthRateCurve[i].level : index - this.DPSGrowthRateCurve[i].level ;Apply for zones from either the next data point, or from the current zone
			result*=value**num
		}
        return result
	}

	BuildBrivLevelTable(baseHP,upgradeList) ;Produce a table of Level:Total HP so we don't have to step through upgrades all the time TODO: This should build from Defs
	{
		level:=1
		HP:=baseHP
		this.BrivLevelTable:={}
		this.BrivLevelTable[level]:=HP
		for uLevel, uHP in upgradeList
		{
			level:=uLevel
			HP+=uHP
			this.BrivLevelTable[level]:=HP
		}
	}

	;Below is code for reading upgrades for reference
	/*
	DEBUG_UpgradeList()
	{
		heroIndex:=g_SF.Memory.GetHeroHandlerIndexByChampID(58) ;Legacy, this probably becomes part of the hero object?
		;size:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[heroIndex].upgradeHandler.upgradesByUpgradeId.size.Read()
		size := g_SF.Memory.ReadHeroUpgradesSize(58) ;Would need replacing as removed, probably becomes part of the hero object?
		upgradeList:={}
		Loop, %size%
        {
			id:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[heroIndex].upgradeHandler.upgradesByUpgradeId["value",A_Index-1].Id.Read()
            ;OutputDebug % "Calling g_SF.Memory.IBM_ReadHeroUpgradeRequiredLevelByIndex`n" ;Note - removed, take from IC Core if needed
			level:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[heroIndex].upgradeHandler.upgradesByUpgradeId[id].RequiredLevel.Read()
			effectString:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[heroIndex].upgradeHandler.upgradesByUpgradeId[id].Def.baseEffectString.Read()
			effectSplit:=StrSplit(effectString,",")
            if (effectSplit[1]=="health_add")
			{
				upgradeList[A_Index]:={}
				upgradeList[A_Index].id:=id
				upgradeList[A_Index].level:=level
				upgradeList[A_Index].health:=effectSplit[2]
			}
        }
        return upgradeList
	}
	*/

}