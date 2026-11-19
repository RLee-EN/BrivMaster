class IC_BrivMaster_LevelManager_Class ;A class for managing champion levelling
{
	__New() ;This processes all the formations so it is only done once. As a result to change a target level the script would have to be restarted
	{
		this.levelingDone:={} ;Records if levelling type is completely done, so we don't go through all the checks when we're already done for the run, key by formation, then for z1,min,max, eg levelingDone["Q","min"]==true
		this.savedFormations:={} ;Formations as per standard memory reads
		this.savedFormationChamps:={} ;Champions in each formation, eg savedFormationChamps["E",58]==true -> Briv is in E
		this.currentWorkList:="" ;Current IC_BrivMaster_LevelManager_WorkList_Class object
		this.ExtractFormation(g_SF.Memory.GetSavedFormationSlotByFavorite(1),"Q")
		this.ExtractFormation(g_SF.Memory.GetSavedFormationSlotByFavorite(3),"E")
		this.ExtractFormation(g_SF.Memory.GetActiveModronFormationSaveSlot(),"M")
		this.ExtractFormation(g_SF.Memory.GetSavedFormationSlotByFavorite(2),"W") ;Must be last to allow W-only champions to be identified easily
		this.ProcessFormation(g_IBM_Settings.IBM_LevelManager_Levels)
		this.SetZ1C()
		this.ResetLevellingDone()
		this.maxKeyPresses:=g_IBM_Settings["IBM_LevelManager_Input_Max"]
		this.KEY_ClickDmg:=g_InputManager.getKey("ClickDmg")
		this.ExtactFrontColumn()
		if(g_IBM_Settings["IBM_Level_Options_Ghost"])
			this.CreateGhostFormation()
		this.KEY_Modifier:=g_InputManager.getKey(g_IBM_Settings["IBM_Level_Options_Mod_Key"]=="Ctrl" ? "LCtrl" : g_IBM_Settings["IBM_Level_Options_Mod_Key"]) ;Modifer to hold - the game uses LeftControl in the keybindings, as much as it doesn't seem to make a lick of difference
		this.modifierLevelUpAmount:=g_IBM_Settings["IBM_Level_Options_Mod_Value"] ;How many levels applying the modifier key will give per keypress
	}
	
	SetZ1C() ;Applies Z1C levelling to appropriate heroes (z1c = z1 complete), as these do not change at run time TODO: This needs a review based on the levels of Melf's abilities
	{
		if(g_Heroes.InM(139)) ;Thellora in M, avoid Melf completing z1 too fast if present
		{
			if(g_Heroes.InM(59))
			{
				g_Heroes[59].Master.z1c:=true
				g_Heroes[59].Reset()
			}
		}
		else ;Casino on z1, stop Briv being levelled
		{
			g_Heroes[58].Master.z1c:=true
			g_Heroes[58].Reset()
		}
	}

	LevelFormation(formationIndex, mode:="min", allowedTime:=10000, forcePriority:=false, surpressByID:="", waitForGold:=false)
	{
		if (this.levelingDone[formationIndex,mode]) ;This formation is done for the given mode
			return
		this.CreateWorklist(formationIndex,mode,surpressByID,waitForGold)
		this.LevelWorklist(allowedTime,forcePriority,waitForGold)
	}

	LevelWorklist(allowedTime:=0,forcePriority:=false,waitForGold:=false) ;Default allowedTime is here, as if this is being called directly we're likely looking for single 'taps' whilst monitoring other things
	{
		if (!IsObject(this.currentWorkList)) ;We've called this without using LevelFormation() first
			return
		startTime:=A_TickCount
		runTime:=0
		while (runTime<=allowedTime) ;Note that as we've set runTime to 0, an AllowedTime of 0 will run at least once
		{
			if (this.currentWorkList.Done() OR (forcePriority AND this.currentWorkList.IsPriorityDone())) ;Nothing to do
				break
			this.currentWorkList.Level(this.maxKeyPresses,waitForGold,forcePriority)
			runTime:=A_TickCount-startTime
		}
	}

	CreateWorklist(formationIndex,mode,surpressByID,waitForGold) ;Formation - "Q", if not supplied uses current, mode - "min", supressByID - array of champion IDs to not include in levelling
	{
		if(formationIndex=="") ;Get current
			championIDs:=g_SF.Memory.IBM_GetCurrentFormationChampions()
		else
			championIDs:=this.savedFormationChamps[formationIndex]
		pendingChampCounter:=0 ;Count how many champions still need levelling in the current Mode
		this.currentWorkList:=new IC_BrivMaster_LevelManager_WorkList_Class(this,mode)
		for champID,_ in championIDs
		{
			pendingChampCounter+=this.currentWorkList.AddChamp(champID,surpressByID,waitForGold)
		}
		if(pendingChampCounter==0 AND !(formationIndex==""))
			this.levelingDone[formationIndex,mode]:=true
	}

	GetClickDamageTargetLevel() ;TODO: This needs a way to factor in the increased level curve beyond z2000
	{
		if (g_SF.Memory.ReadCurrentZone()==1) ;On z1 we want to level to meet Thellora's rush target
			return this.clickDamageTargetRush
		else
			return Min(this.clickDamageTargetFinal,g_SF.Memory.ReadHighestZone()+g_IBM.routeMaster.zonesPerJumpQ*2) ;Return the lowest of the reset zone click damage requirement, and 2 jumps from the next landing zone to ensure we don't overlevel, but never have to wait for levelling
	}

	LevelClickDamage(timeout:=500) ;Default 500ms should be good for a min of 3 upgrades, being 300 levels on x100, which should be enough even going 300 zones with Thellora
	{
		startTime:=A_TickCount
		clickTarget:=this.GetClickDamageTargetLevel()
		while (g_SF.Memory.ReadClickLevel() < clickTarget AND g_SF.Memory.IBM_ReadClickLevelUpAllowed() > 0 AND A_TickCount - startTime < timeout)
		{
			this.KEY_ClickDmg.KeyPress() ;No value in trying to build this to be able to use _Bulk() as it will mostly only be one press at a time
			DllCall("Sleep", "UInt", 0)
		}
	}

	SetupFailedConversion()
	{
		this.OverrideMinToSoftCap()
		this.ResetLevellingDone()
		g_IBM.Logger.AddMessage("SetupFailedConversion() Triggered")
	}

	OverrideMinToSoftCap() ;Overrides all min levels to the champion's softcap, for failed conversion recovery
	{
		for k,hero in g_Heroes
		{
			if k is integer
				hero.SetSoftCap()
		}
	}

	ResetLevellingDone()
	{
		this.levelingDone["Q"]:={"min":false,"z1":false}
		this.levelingDone["W"]:={"min":false,"z1":false}
		this.levelingDone["E"]:={"min":false,"z1":false}
		this.levelingDone["M"]:={"min":false,"z1":false}
		;this.levelingDone["A"]:={"min":false,"z1":false} ;A not levelled now the specific Ghost formation exists
		if(g_IBM_Settings["IBM_Level_Options_Ghost"])
			this.levelingDone["GHOST"]:={"min":false,"z1":false}
	}

	ExtractFormation(slot,index) ;Extracts both the usual formation and the champ list in one go
	{
		this.savedFormations[index]:={}
		this.savedFormationChamps[index]:={}
		size:=g_SF.Memory.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Formation.size.Read()
		if(size <= 0 OR size > 500) ;Sanity check
			return ""
		loop, %size%
		{
			champID:=g_SF.Memory.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Formation[A_Index - 1].Read()
			this.savedFormations[index].Push(champID)
			if (champID != -1)
			{
				this.savedFormationChamps[index,champID]:=true
				if(index=="W" AND !this.savedFormationChamps["A"].HasKey(champID)) ;For W, if the champion is not yet read in they are unique to W, which we want to check for fast placement with only stackinging
					this.savedFormationChamps["XW",champID]:=true ;eXclusive W
				this.savedFormationChamps["A",champID]:=true ;"A" is a meta-list of all champions in use
			}
		}
	}

	GetFormation(index) ;Returns saved formation by key, eg "Q", the modron formation "M"
	{
		return this.savedFormations[index]
	}
	
	CreateGhostFormation() ;Create a formation that consists of M, and any other champions that are in seats not used by M, and so are possible candidates for ghost levelling. This can result in multiple champions in the same seat being included if different between Q/W/E. Also creates a list of ghostable heroes
	{
		this.savedFormationChamps["GHOST"]:={}
		this.ghostLevellingHeroes:=[]
		seatList:=[]
		for heroID, _ in this.savedFormationChamps["M"] ;For each hero in the modron formation
		{
			this.savedFormationChamps["GHOST",heroID]:=true
			seatList[g_Heroes[heroID].Seat]:=true
		}
		for heroID, _ in this.savedFormationChamps["A"] ;All heroes
		{
			if(!this.savedFormationChamps["GHOST",heroID] AND !seatList[g_Heroes[heroID].Seat]) ;Not in the list already, and seat not in the seat list
			{
				this.savedFormationChamps["GHOST",heroID]:=true
				this.ghostLevellingHeroes.Push(g_Heroes[heroID])
			}
		}
	}

	ExtactFrontColumn() ;Returns the champions in the front row of the formation, except for Briv, used to suppress levelling so Briv takes all the hits  TODO: This needs to exclude Hew w/avoidance feat
	{
		frontSize:=g_SF.Memory.IBM_GetFrontColumnSize()
		this.frontColumnChampionsMNoBriv:=[]
		loop %frontSize%
		{
			heroID:=this.savedFormations["M"][A_Index]
			if(heroID!=58) ;Exclude Briv
				this.frontColumnChampionsMNoBriv.Push(heroID)
		}
	}
	
	SetupFirstZoneFrontRow()
	{
		if(g_IBM_Settings["IBM_Level_Options_Suppress_Front"]) ;Avoid levelling any front-row hero but Briv - in which case don't prioritise
		{
			frontRow:=[]
			for _, v in this.frontColumnChampionsMNoBriv
			{
				levelsRequired:=g_Heroes[v].GetTargetLevel() ;TODO: Pass the appropiate z1 or min to this? Not it intentionally doesn't consider current level as that should be 0
				if(levelsRequired<=100-this.modifierLevelUpAmount) ;Modifier key levelling, e.g. for x25 100-25=75 will trigger modifier use, 80 would not as it would end up 4x25=100 anyway
				{
					g_Heroes[v].Current.CasinoLevelling:=Ceil(levelsRequired / this.modifierLevelUpAmount) ;E.g. 50 at x25 will be 2
				}
				else
				{
					g_Heroes[v].Current.CasinoLevelling:=0 ;0 indicates x100 levelling
				}
				frontRow.Push(g_Heroes[v])
				this.OverrideLevelByIDLowerToMax(v,"z1",0)
				this.OverrideLevelByIDLowerToMax(v,"min",0)
			}
			return frontRow
		}
		else ;Raise priority to get the hero placed before the formation comes under attack
		{
			for _, v in this.frontColumnChampionsMNoBriv
			{
				this.RaisePriorityForFrontRow(v)
			}
			return [] ;Empty return as we have not lowered any levels
		}
	}
	
	SetupFirstZoneGhost() ;Checks the list of potentially ghostable heroes created at script start to confirm which are seated
	{
		ghostList:=[]
		for _, Hero in this.ghostLevellingHeroes
		{
			if(Hero.ReadSelectedInSeat())
			{
				levelsRequired:=Hero.GetTargetLevel() ;TODO: Pass the appropiate z1 or min to this? Not it intentionally doesn't consider current level as that should be 0
				if(levelsRequired<=100-this.modifierLevelUpAmount) ;Modifier key levelling, e.g. for x25 100-25=75 will trigger modifier use, 80 would not as it would end up 4x25=100 anyway
				{
					Hero.Current.CasinoLevelling:=Ceil(levelsRequired / this.modifierLevelUpAmount) ;E.g. 50 at x25 will be 2
				}
				else
				{
					Hero.Current.CasinoLevelling:=0 ;0 indicates x100 levelling
				}
				ghostList.Push(Hero)
			}
		}
		return ghostList
	}

	OverrideLevelByID(heroID, mode, level) ;Updates the current data (only!)
	{
		if (g_Heroes.hasKey(heroID))
			g_Heroes[heroID].OverrideLevel(mode,level)
	}

	ResetLevelByID(heroID) ;Reset a champion's level to reflect the master settings
	{
		if (g_Heroes.hasKey(heroID))
		{
			g_Heroes[heroID].Reset()
			this.ResetLevellingDone()
		}
	}

	OverrideLevelByIDRaiseToMin(heroID, mode, level) ;Updates the current data (only) - raises the champions target level to level if lower, otherwise do nothing
	{
		if (g_Heroes.hasKey(heroID))
		{
			if (g_Heroes[heroID].Current[mode] < level) ;TODO: Encapsulate
			{
				g_Heroes[heroID].Current[mode]:=level ;TODO: Encapsulate
				this.ResetLevellingDone() ;As we might need to do further levelling after raising
			}
		}
	}

	OverrideLevelByIDLowerToMax(heroID, mode, level) ;Updates the current data (only) - lowers the champions target level to level if higher, otherwise do nothing
	{
		if (g_Heroes.hasKey(heroID))
		{
			if (g_Heroes[heroID].Current[mode] > level)
				g_Heroes[heroID].Current[mode]:=level
		}
	}

	RaisePriorityForFrontRow(heroID) ;Updates the current data (only) - adjusts champion levelling priority for z1 front row - sets to 1/100 if <=0
	{
		if (g_Heroes.hasKey(heroID))
			g_Heroes[heroID].RaisePriorityForFrontRow()
	}

	Reset()
	{
		this.ResetLevellingDone()
		g_Heroes.ResetAll()
		this.clickDamageTargetFinal:=g_IBM.routeMaster.targetZone ;These need a curve for post-z2000 HP. Done in Reset() as __New() is current called before the routemaster is set up
		if (g_Heroes[139].inM)
			this.clickDamageTargetRush:=g_IBM.routeMaster.ThelloraTarget ;Only needs to be high enough for the Thellora target as we will stop there are do the Casino
		else
			this.clickDamageTargetRush:=g_IBM.routeMaster.ThelloraTarget + g_IBM.routeMaster.zonesPerJumpQ*2 ;Include 2 jumps
	}

	ProcessFormation(levelSettings)
	{
		for heroID,_ in this.savedFormationChamps["A"]
		{
			g_Heroes[heroID].ApplyLevelSettings(levelSettings,this.savedFormationChamps) ;g_Heroes' __get() will create the hero object if it doesn't already exist
		}
	}

	SetModifierKey(useModifier)
	{
		if (useModifier)
		{
			this.KEY_Modifier.Press_Bulk()
			startTime:=A_TickCount
			while (g_SF.Memory.IBM_ClickDamageLevelAmount()!=this.modifierLevelUpAmount AND A_TickCount - startTime < 100) ;Allow 100ms for the keypress to apply at maximum to avoid getting stuck. On a fast PC it only took 1 AHK tick (15ms) extra when needed
				g_IBM.IBM_Sleep(1)
		}
		else
		{
			this.KEY_Modifier.Release_Bulk()
			startTime:=A_TickCount
			while (g_SF.Memory.IBM_ClickDamageLevelAmount()==this.modifierLevelUpAmount AND A_TickCount - startTime < 100)
				g_IBM.IBM_Sleep(1)
		}
	}
}

class IC_BrivMaster_LevelManager_WorkList_Class ;A class to manage the processing of a levelling job
{
	__New(levelManager,mode)
	{
		this.champs:={}
		this.parent:=levelManager
		this.mode:=mode
		this.minPriority:=0 ;Minimum priority of added champions
		this.maxPriority:=0 ;Maximum priority of added champions
	}

	Level(maxKeyPresses,byRef waitForGold, forcePriority) ;WaitforGold is ByRef as we only want to call it on the first iteration
	{
		keyList100:=[]
		keyList10:=[] ;Note this is the modifier list, which can now be either x10 or x25
		this.GetKeyList(maxKeyPresses,keyList100,keyList10,forcePriority)
		if (keyList100.Count()==0 AND keyList10.Count()==0) ;Due to z1c restrictions, it is possible that .Done() is false but there is nothing to do this iteration
			return
		if (waitForGold) ;Wait for gold if requested, for start-of-run calls only
		{
			this.WaitForAreaActive()
			g_IBM.Logger.SetActiveStartTime()
			g_InputManager.gameFocus() ;Placed to be as close to the input as possible without delaying it
			waitForGold:=!this.WaitForFirstGold(keyList100.Count()>0 ? keyList100[1].tag : keyList10[1].tag)
		}
		else
			g_InputManager.gameFocus()
		Critical On ;We do not want timers trying to also press keys whilst we are levelling, given 629+ issues with multiple keys, and the possible use of modifer keys
		for _, key in keyList100
			key.KeyPress_Bulk()
		if (keyList10.Count()>0) ;Check this one so the modifier key is not used unnecessarily
		{
			this.parent.SetModifierKey(true)
			for _, key in keyList10
				key.KeyPress_Bulk()
			this.parent.SetModifierKey(false)
		}
		Critical Off
		this.UpdateLevels()
	}

	WaitForAreaActive()
	{
		StartTime:=A_TickCount
		while (!g_SF.Memory.ReadAreaActive() AND A_TickCount - StartTime < 10000 )
		{
			Sleep 0
		}
	}

	WaitForFirstGold(checkSeat)
	{
		StartTime := A_TickCount
		gold:=g_SF.Memory.IBM_ReadGoldFirst8BytesBySeat(checkSeat) ;Reading the first 8 bytes is sufficent since the test is just for 0, and x^y==0 is true iff x==0
		while ((gold==0 OR gold=="") AND A_TickCount - StartTime < 10000 ) ;Note that the seat gold value will be null whilst the new run gets set up by the game
		{
			Sleep 0
			gold:=g_SF.Memory.IBM_ReadGoldFirst8BytesBySeat(checkSeat)
		}
		return gold>0
	}

	GetKeyList(maxKeyPresses,byRef keyList100,byRef keyList10,forcePriority) ;Populates the 2 provided keylists. If forcePriority=true then all priority > 1 champions will be added regardless of maxKeyPresses. TODO: Can this continue to count up champions with prio > 0 to allow us to do the IsPriorityDone check here instead of as a separate loop? Note that keyList10 may now be x10 or x25
	{
		curPriority:=this.maxPriority
		while (curPriority>=this.minPriority AND (keyList100.Count() < maxKeyPresses OR (forcePriority AND curPriority>0))) ;Iterate over all used priority levels from highest to lowest
		{
			champList:=this.GetChampsAtPriority(curPriority) ;Get a list of champions at this priority with the number of levels required
			while (champList.Count() > 0 AND (keyList100.Count() < maxKeyPresses OR (forcePriority AND curPriority>0)))
			{
				for champID,_ in champList.Clone() ;Clone so we can remove from the real list
				{
					Champion:=this.Champs[champID]
					levelsRequired:=Champion.GetLevelsRequired(this.mode)
					if (levelsRequired >= 200) ;Add and don't remove as we need more than 1 press
					{
						keyList100.push(Champion.Key)
						Champion.Current.PendingLevels+=100 ;TODO: Should this be encapsulated?
						if (Champion.GetPriority(this.mode,true)!=curPriority) ;The pending levels may take us over the priorityLimit and change the champion's priority
						{
							champList.Delete(champID)
						}
						if (keyList100.Count() >= maxKeyPresses AND (!forcePriority OR curPriority<=0))
							Break ;Breaks out of the For loop. The while loop will handle itself
					}
					else if (levelsRequired >= 100) ;Add and remove since we're <200
					{
						keyList100.push(Champion.Key)
						Champion.Current.PendingLevels+=100 ;TODO: Should this be encapsulated?
						champList.Delete(champID)
						if (keyList100.Count() >= maxKeyPresses AND (!forcePriority OR curPriority<=0))
							Break ;Breaks out of the For loop. The while loop will handle itself
					}
					else
					{
						champList.Delete(champID)
					}
				}
			}
			curPriority--
		}
		k100Count:=keyList100.Count()+1 ;The modifier key cycle required for x10/x25 levelling is considered to be a key press as well
		curPriority:=this.maxPriority
		while (curPriority>=this.minPriority AND (keyList10.Count()+k100Count < maxKeyPresses OR (forcePriority AND curPriority>0))) ;Iterate over all used priority levels from highest to lowest
		{
			champList:=this.GetChampsAtPriority(curPriority) ;Get a list of champions at this priority with the number of levels required
			while (champList.Count() > 0 AND (keyList10.Count()+k100Count < maxKeyPresses OR (forcePriority AND curPriority>0)))
			{
				for champID,_ in champList.Clone() ;Clone so we can remove from the real list
				{
					Champion:=this.Champs[champID]
					levelsRequired:=Champion.GetLevelsRequired(this.mode)
					if (levelsRequired < 100) ;Due to the z1c condition being dynamic a champion can be read in to GetChampsAtPriority() for x10 after having being ignored for x100
					{
						if (levelsRequired > this.parent.modifierLevelUpAmount) ;Add and don't remove as we need more than 1 press
						{
							keyList10.push(Champion.Key)
							Champion.Current.PendingLevels+=this.parent.modifierLevelUpAmount
							if (Champion.GetPriority(this.mode,true)!=curPriority) ;The pending levels may take us over the priorityLimit and change the champion's priority
							{
								champList.Delete(champID)
							}
							if (keyList10.Count()+k100Count >= maxKeyPresses AND (!forcePriority OR curPriority<=0))
								Break ;Breaks out of the For loop. The while loop will handle itself
						}
						else if (levelsRequired > 0) ;Add and remove since we're <=10
						{
							keyList10.push(Champion.Key)
							Champion.Current.PendingLevels+=this.parent.modifierLevelUpAmount
							champList.Remove(champID)
							if (keyList10.Count()+k100Count >= maxKeyPresses AND (!forcePriority OR curPriority<=0))
								Break ;Breaks out of the For loop. The while loop will handle itself
						}
						else
							champList.Delete(champID)
					}
					else
						champList.Delete(champID)
				}
			}
			curPriority--
		}
	}

	GetChampsAtPriority(curPriority)
	{
		champList:={}
		for champID,Champ in this.champs
		{
			if ((Champ.GetPriority(this.mode,true)==curPriority) AND Champ.CheckZ1cAllowed(this.mode))
				champList[champID]:=true
		}
		return champList
	}

	UpdateLevels()
	{
		for champID,_ in this.Champs.Clone() ;Clone because we will be removing entries from the main list
		{
			this.Champs[champID].Current.PendingLevels:=0
			if (!this.Champs[champID].NeedsLevelling(this.Mode))
				this.Champs.Delete(champID)
		}
	}

	IsPriorityDone()
	{
		for _,Champion in this.Champs
		{
			if ((Champion.GetPriority(this.mode,false) > 0) AND Champion.CheckZ1cAllowed(this.mode)) ;GetPriority() does not include pending levels here
				return false
		}
		return true
	}

	Done()
	{
		return this.Champs.Count()==0
	}

	AddChamp(heroID,surpressByID,startOfRun)
	{
		if (!g_Heroes.hasKey(heroID)) ;No data
			return 0
		if(g_Heroes[heroID].NeedsLevelling(this.mode))
		{
			if (startOfRun OR g_Heroes[heroID].ReadSelectedInSeat()) ;We can't check for selection at the very start as the game will still be loading in, so have to assume M has loaded as it should. Expecting WaitForGold to be passed as startOfRun here
			{
				if (!this.ValueIsInList(surpressByID,heroID))
				{
					this.Champs[heroID]:=g_Heroes[heroID]
					this.UpdatePriorityMinMax(g_Heroes[heroID].GetPriority(this.mode,false)) ;No point including pending levels as there won't be any
				}
			}
			return 1
		}
		else
		return 0
	}

	ValueIsInList(simpleArray, findValue) ;true if the value is in the given simple Array
	{
		for _,v in simpleArray
		{
			if (v==findValue)
				return true
		}
		return false
	}

	UpdatePriorityMinMax(current)
	{
		if (current<this.minPriority)
			this.minPriority:=current
		if (current>this.maxPriority)
			this.maxPriority:=current
	}
}