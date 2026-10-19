class IC_BrivMaster_Heroes_Class ;A class for managing heroes. Or Champions, but that's a longer word and I am not being paid by the letter
{
	Static HERO_MIN:=160 ;166 heroes as of 2026-09-30
	Static HERO_MAX:=500
	
	__New()
	{
		this.initialised:=false ;Variables need to be set here to prevent __Get() being called on them
		this.heroCount:=0
		this.Init()
	}

	__Get(heroID)
	{
		if(!this.Init())
			return
		if heroID is integer
		{
			switch heroID ;Create extended objects for heroes that need extra functionality
			{
				case 58: this[heroID]:=new IC_BrivMaster_Briv_Class(heroID,this.IDToIndexMap[heroID]) ;Briv
				case 83: this[heroID]:=new IC_BrivMaster_Elly_Class(heroID,this.IDToIndexMap[heroID]) ;Elly
				case 97: this[heroID]:=new IC_BrivMaster_Tatyana_Class(heroID,this.IDToIndexMap[heroID]) ;Tatyana
				case 139: this[heroID]:=new IC_BrivMaster_Thellora_Class(heroID,this.IDToIndexMap[heroID]) ;Thellora
				default: this[heroID]:=new IC_BrivMaster_Hero_Class(heroID,this.IDToIndexMap[heroID])
			}
		}
	}
	
	InM(heroID) ;Wrapper to avoid creating objects via __Get() when we only want to check for a hero's presence in a formation
	{
		return this.HasKey(heroID) ? this[heroID].InM : false
	}
	
	InA(heroID) ;Wrapper to avoid creating objects via __Get() when we only want to check for a hero's presence in a formation
	{
		return this.HasKey(heroID) ? this[heroID].InA : false
	}

	Init() ;Initialises the heroIndexMap if needed, returns true on success or if already done. This is for use with the hub side where we don't abort if the __new function cannot do this, so hub functions need to check
	{
		if (this.initialised)
			return true
		this.initialised:=this.GenerateHeroIDtoHeroIndexMap()
		return this.initialised
	}
	
	CheckForDataChange() ;Data pushes can change the hero collection, changing the mapping of hero ID to heroIndex. Attempting a simple check of the collection size
	{
		size:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes.size.Read()
		if(size<=IC_BrivMaster_Heroes_Class.HERO_MIN OR size>=IC_BrivMaster_Heroes_Class.HERO_MAX) ;Sanity check, don't force an update if memory reads are not available
		{
			;g_IBM.Logger.AddMessage("CheckForDataChange() Hero collection size [" . size . "] out of bounds and current [" . this.heroCount . "]")
			return false
		}
		if(size==this.heroCount)
		{
			;g_IBM.Logger.AddMessage("CheckForDataChange() Hero collection unchanged from [" . size . "]")
			return false
		}
		this.GenerateHeroIDtoHeroIndexMap()
		g_IBM.Logger.AddMessage("CheckForDataChange() Hero collection size changed from [" . this.heroCount . "] to [" . size . "]")
		return true
	}

	ResetAll() ;Reset all heroes
	{
		refreshIndex:=this.CheckForDataChange()
		for k,v in this
		{
			if k is integer ;Only call for the heroID objects. N.B. This cannot be an expression in AHK v1, i.e. 'if (k is integer)' is not valid
				v.Reset(refreshIndex)
		}
	}

    GenerateHeroIDtoHeroIndexMap() ;Returns true on success
	{
        this.IDToIndexMap:={}
        size:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes.size.Read()
		if(size<=IC_BrivMaster_Heroes_Class.HERO_MIN OR size>=IC_BrivMaster_Heroes_Class.HERO_MAX) ;Sanity check
			return false
        this.heroCount:=size
		loop, %size%
        {
            heroID:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[A_Index - 1].def.ID.Read()
            this.IDToIndexMap[heroID]:=A_Index - 1
        }
		return true
    }
}

class IC_BrivMaster_Hero_Class ;Represents a single hero. Can be extended for heroes with specific functionality
{
	__New(heroID,heroIndex)
	{
		this.ID:=heroID
		this.HeroIndex:=heroIndex
		this.Seat:=this.ReadChampSeat()
		this.Key:=g_InputManager.getKey("F" . this.Seat) ;So we don't have to re-calc this constantly
		this.Key.Tag:=this.Seat ;Use the tag to track the seat. TODO: If levelling is encapsulated properly this might not be needed
		this.lastUpgradeLevel:=this.GetLastUpgradeLevel()
		this.Master:={} ;Unmodified levelling data
		this.Current:={} ;Current levelling data
	}

	;--------------------------------------------------------------------------------------
	;---Hero related memory reads
	;--------------------------------------------------------------------------------------

	ReadBenched()
	{
		return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].Benched.Read()
	}

	ReadChampSeat()
    {
        return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].def.SeatID.Read()
    }

	GetLastUpgradeLevel() ;Loop upgrades until the upgrade with the highest level is found
	{
		size:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.UserData.HeroHandler.heroes[this.heroIndex].upgradeHandler.upgradesByUpgradeId.size.Read()
		if (size < 1 || size > 1000)
			return 0
		maxUpgradeLevel:=0
		Loop, %size% ;Loop and save the highest level requirement
		{
			requiredLevel:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].upgradeHandler.upgradesByUpgradeId["value",A_Index-1].RequiredLevel.Read()
			if (requiredLevel!=9999) ;This check taken from IC_BrivGemFarm_Levelup; I assume this is the value for 'not available'
				maxUpgradeLevel:=Max(requiredLevel, maxUpgradeLevel)
		}
		return maxUpgradeLevel
	}

	ReadLevel()
    {
        return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].level.Read()
    }

	ReadUltimateCooldown() ;TODO: Does it make sense to have an UltimateReady() wrapper for this? Currently Casino uses direct result to allow for debug/error checking, so might not be very useful
	{
		ULTIMATEITEMS_LIST:=g_SF.Memory.GameManager.game.gameInstances[0].Screen.uiController.ultimatesBar.ultimateItems
        ULTIMATE_CD:=""
		loop, % ULTIMATEITEMS_LIST.size.Read()
        {
            if (this.ID == ULTIMATEITEMS_LIST[A_Index-1].hero.def.ID.Read())
			{
				ULTIMATE_CD:=ULTIMATEITEMS_LIST[A_Index-1].ultimateAttack.internalCooldownTimer.Read()
				break
			}
        }
		return ULTIMATE_CD
	}

	UseUltimate(maxRetries:=50,exitOnceQueued:=false) ;Use ultimate, retrying up to the given number of times if the cooldown doesn't change. If exitOnceQueued is true the function will return as soon as the ultimate is queued - which may mean it never activates if something changes in the game state (area change most likely). Returns the number of attempts made
	{
		;TODO: Not sure this function should be hard coded offsets in a specific file like this - constants in a main file might be better? Applies later in this function as well. Maybe some wrapper somewhere?
		ULTIMATEITEMS_LIST:=g_SF.Memory.GameManager.game.gameInstances[0].Screen.uiController.ultimatesBar.ultimateItems
        ULTIMATE_HOTKEY:=""
		ADDRESS_ULTIMATEITEMS_LIST:=_IBM_MM.instance.getAddressFromOffsets(ULTIMATEITEMS_LIST.BasePtr.BaseAddress,ULTIMATEITEMS_LIST.FullOffsets*)
		ADDRESS_ULTIMATEITEMS_ITEMS:=_IBM_MM.instance.getAddressFromOffsets(ADDRESS_ULTIMATEITEMS_LIST,0x10)
		HEROID_OFFSET:=[ULTIMATEITEMS_LIST.hero.Offset[1],ULTIMATEITEMS_LIST.hero.def.Offset[1],ULTIMATEITEMS_LIST.hero.def.ID.Offset[1]] ;TODO: A lot of this never changes; should be prepared once only. Some kind of ultimate handler object?
		HEROID_TYPE:=ULTIMATEITEMS_LIST.hero.def.ID.ValueType ;TODO: This one can't change
		loop, % _IBM_MM.instance.read(ADDRESS_ULTIMATEITEMS_LIST,"Int",0x18)
        {
            ADDRESS_ULTIMATEITEMS_ITEM:=_IBM_MM.instance.getAddressFromOffsets(ADDRESS_ULTIMATEITEMS_ITEMS,0x20 + (A_Index-1) * 0x8)
			if (this.ID == _IBM_MM.instance.read(ADDRESS_ULTIMATEITEMS_ITEM,HEROID_TYPE,HEROID_OFFSET*))
			{
				ULTIMATE_HOTKEY:=_IBM_MM.instance.read(ADDRESS_ULTIMATEITEMS_ITEM,ULTIMATEITEMS_LIST.HotKey.ValueType,ULTIMATEITEMS_LIST.HotKey.Offset*)
				break
			}
        }
		if (ULTIMATE_HOTKEY=="") ;Return empty
			return
		ULTIMATE_KEY:=g_InputManager.getKey(ULTIMATE_HOTKEY)
		ULTIMATE_KEY.KeyPress()
		retryCount:=0
		ULTIMATEATTACK:=ULTIMATEITEMS_LIST.ultimateAttack
		ADDRESS_ULTIMATEATTACK:=_IBM_MM.instance.getAddressFromOffsets(ADDRESS_ULTIMATEITEMS_ITEM, ULTIMATEATTACK.Offset*)
		while (_IBM_MM.instance.read(ADDRESS_ULTIMATEATTACK,ULTIMATEATTACK.internalCooldownTimer.ValueType,ULTIMATEATTACK.internalCooldownTimer.Offset*)<=0 AND retryCount < maxRetries)
		{
			if (_IBM_MM.instance.read(ADDRESS_ULTIMATEATTACK,ULTIMATEATTACK.queued.ValueType,ULTIMATEATTACK.queued.Offset*)) ;If the ultimate is queued, just wait on it
			{
				retryCount++ ;Counting this as 1/10th of a retry to avoid having to have some duplicate timeout in case the queued attack gets stuck forever
				if (exitOnceQueued)
					return retryCount
				g_IBM.IBM_Sleep(10)
			}
			else
			{
				ULTIMATE_KEY.KeyPress()
				retryCount+=10
				Sleep 0
			}
		}
		return retryCount
	}

	ReadMaxHealth()
    {
        return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].lastMaxHealth.Read()
    }

	ReadOverwhelm()
    {
        return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].overwhelm.Read()
    }

	ReadFielded() ;In current formation. !ReadBenched() should be used in preferance to this
	{
        FORMATION_SLOTS:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.formation.slots
		size:=FORMATION_SLOTS.size.Read()
        if(size <= 0 OR size > 14) ; sanity check, 12 is the max number of concurrent champions possible.
            return false
        loop, %size%
        {
            if (this.ID==FORMATION_SLOTS[A_index - 1].hero.def.ID.Read())
				return true
        }
        return false
    }

	ReadSelectedInSeat() ;Selected in their seat - may not be placed / levelled
	{
		return this.ID==g_SF.Memory.GameManager.game.gameInstances[0].Screen.uiController.bottomBar.heroPanel.activeBoxes[this.Seat - 1].hero.def.ID.read()
	}

    ReadName() ;Not stored as the main script doesn't need to know the names outside of the pre-flight check, which is not performance sensitive
	{
        return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].def.name.Read()
    }

	ReadActiveGameInstanceID() ;This is the instance ID 1 to 4, NOT the ID if the instance in the gameInstances collection
	{
		return  g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].ActiveGameInstanceId_k__BackingField.Read()
	}

	HasCoreSpec(specID) ;True if the hero has the specified specialisation saved in the current modron core
	{
        HERO_SPECS:=g_SF.Memory.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[g_SF.Memory.GetActiveModronFormationSaveSlot()].Specializations[this.ID].List
		size:=HERO_SPECS.size.Read()
		if(size<=0 OR size>5) ;Sanity check
            return false
		loop %size%
		{
			if(HERO_SPECS[A_Index-1].Read()==specID)
				return true
		}
		return false
    }

	;------------------------------------------------------------------------------------
	;---General functions
	;------------------------------------------------------------------------------------

	CanUseUltimate() ;True if the champions is fielded and their ultimate is off cooldown
	{
		ultCD:=this.ReadUltimateCooldown()
		if(ultCD)
			return ultCD<=0 AND !this.ReadBenched()
		return false
	}

	;------------------------------------------------------------------------------------
	;---Levelling functions
	;------------------------------------------------------------------------------------

	Reset(refreshIndex:=false)
	{
		this.Current:=this.Master.Clone()
		if(refreshIndex)
			this.HeroIndex:=this.IDToIndexMap[this.ID]
	}

	ApplyLevelSettings(levelsettings,savedFormationChamps) ;Set up this champion's levelling and formation related properties
	{
		this.inM:=savedFormationChamps["M"].hasKey(this.ID)
		this.inQ:=savedFormationChamps["Q"].hasKey(this.ID)
		this.inW:=savedFormationChamps["W"].hasKey(this.ID)
		this.inE:=savedFormationChamps["E"].hasKey(this.ID)
		this.inA:=this.inM OR this.inQ OR this.inW OR this.inE
		if (levelSettings.hasKey(this.ID))
		{
			champData:=levelSettings[this.ID]
			if champData.hasKey("min")
				this.Master.Min:=champData["min"]
			else
			{
				this.Master.Min:=0
			}
			if champData.hasKey("z1")
				this.Master.z1:=champData["z1"]
			else
			{
				this.Master.z1:=0
			}
			this.Master.z1c:=false ;z1c is not part of the settings loaded
			if champData.hasKey("prio")
				this.Master.priority:=champData["prio"]
			else
				this.Master.priority:=0
			if champData.hasKey("priolimit")
				this.Master.priorityLimit:=champData["priolimit"]
			else
				this.Master.priorityLimit:=""
		}
		else ;No data, apply defaults. This is always level 0 - we do not want to level mistakenly saved champions, only those we've intentionally set a level for
		{
			this.Master.Min:=0
			this.Master.z1:=0
			this.Master.z1c:=false
			this.Master.priority:=0
			this.Master.priorityLimit:=""
		}
		this.Master.PendingLevels:=0
		this.Current:=this.Master.Clone() ;A copy of the master data to allow manipulation at runtime whilst allowing us to reset to default each run
	}

	GetTargetLevel(mode:="min")
	{
		if(mode=="z1")
			return this.Current.z1
		else if (mode=="min")
			return this.Current.min
		else
			return 0
	}

	NeedsLevelling(mode:="min")
	{
		this.Current.Level:=this.ReadLevel() ;TODO: Consider updating this.Current.Level directly in this.ReadLevel() so it can be used for low-priority things without a memory read?
		if (this.Current.Level=="")
			this.Current.Level:=0 ;Or the memory reads were not ready. Need to check something like ReadHeroIsOwned() returns a value maybe? That should possibly be done long before we get this far though
		if(mode=="z1")
			return this.Current.Level < this.Current.z1
		else if (mode=="min")
			return this.Current.Level < this.Current.min
		else
			return 0
	}

	GetPriority(mode:="min",includePending:=true)
	{
		if(mode=="z1") ;Priority settings apply to z1 only
		{
			;this.Current.Level:=g_SF.Memory.IBM_ReadChampLvlByIndex(this.HeroIndex) ;TODO: Decide if we should check this here? It's checked before we add to the levelling Worklist, and after each levelling attempt
			;if (this.Current.Level=="")
			;this.Current.Level:=0 ;Or the memory reads were not ready. Need to check something like ReadHeroIsOwned() returns a value maybe? That should possibly be done long before we get this far though
			expectedLevel:=includePending ? this.Current.Level + this.Current.PendingLevels : this.Current.Level
			if (this.Current.PriorityLimit AND expectedLevel>=this.Current.PriorityLimit)
				return 0
			else
				return this.Current.Priority
		}
		else
			return 0
	}

	CheckZ1cAllowed(mode:="min") ;checks for zone 1 completed conditions
	{
		if(mode=="z1" AND this.Current.z1c)
			return g_SF.Memory.ReadCurrentZone()>1 OR g_SF.Memory.ReadQuestRemaining()==0 ;Allow levelling if the zone is complete on z1
		else
			return true
	}

	GetLevelsRequired(mode:="min") ;Always includes pending. Does not refresh this.Current.Level
	{
		if(mode=="z1")
			return Max(this.Current.z1 - (this.Current.Level + this.Current.PendingLevels),0)
		else if (mode=="min")
			return Max(this.Current.min - (this.Current.Level + this.Current.PendingLevels),0)
		else
			return 0
	}

	SetSoftCap() ;Sets the champions current min level to softcap
	{
		this.Current.Min:=this.lastUpgradeLevel
	}

	OverrideLevel(mode,level)
	{
		this.Current[mode]:=level
	}

	RaisePriorityForFrontRow()
	{
		if (this.Current.Priority<=0)
		{
			this.Current.Priority:=1
			this.Current.PriorityLimit:=100
		}
	}
}

class IC_BrivMaster_Briv_Class extends IC_BrivMaster_Hero_Class
{
	__new(heroID,heroIndex)
	{
		base.__new(heroID,heroIndex)
		this.MEMORY_SB_ADDRESS:=""
		this.MEMORY_SB_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.StatHandler.BrivSteelbonesStacks.ValueType ;Cannot change
	}

	Reset()
	{
		base.Reset()
		this.MEMORY_SB_ADDRESS:="" ;Stops rubbish being read if InitFastSB() has not been called
	}

	;--------------------------------------------------------------------------------------
	;---Hero related memory reads
	;--------------------------------------------------------------------------------------

	ReadSBStacks()
	{
        return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.StatHandler.BrivSteelbonesStacks.Read()
    }

	FastReadSBStacks() ;InitFastSB() must have been called prior to using this call
	{
		return _IBM_MM.instance.read(this.MEMORY_SB_ADDRESS,this.MEMORY_SB_TYPE)
	}

    ReadHasteStacks()
	{
        return g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.StatHandler.BrivSprintStacks.Read()
    }

	;------------------------------------------------------------------------------------
	;---General functions
	;------------------------------------------------------------------------------------

	InitFastSB() ;Resolves the pointers to the current Steelbones stat for direct reads, this is intended for online stacking where we spam-read SB stacks. ;TODO: Since this is part of the statHandler is should really only change when the game restarts - can we make use of these reads all the time?
	{
		this.MEMORY_SB_ADDRESS:=g_SF.Memory.ResolvePointers(g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.StatHandler.BrivSteelbonesStacks)
	}
}

class IC_BrivMaster_Thellora_Class extends IC_BrivMaster_Hero_Class
{
	__new(heroID,heroIndex)
	{
		base.__new(heroID,heroIndex)
		this.STAT_RUSH_TRIGGERED:="thellora_plateaus_of_unicorn_run_has_triggered"
		this.STAT_AREA_CHARGES:="thellora_plateaus_of_unicorn_run_areas"
		this.rushCap:=g_SF.Memory.IBM_GetCurrentCampaignFavourExponent()
		this.rushNext:=0 ;If non-zero, the expected next rush zone, which could be lower than the cap if in recovery
	}

	Reset()
	{
		base.Reset()
		this.rushNext:=0
	}

	;--------------------------------------------------------------------------------------
	;---Hero related memory reads
	;--------------------------------------------------------------------------------------

	ReadRushTriggered() ;Has Thellora rushed yet this run? Looking up this stat seems fairly fast, so need for caching like in ReadRushAreaCharges()
	{
		return g_SF.Memory.GameManager.game.gameInstances[0].StatHandler.ServerStats[this.STAT_RUSH_TRIGGERED].Read()==1
	}

	ReadRushAreaCharges() ;How many zones does Thellora have stored? The stat dictionary has ~570 items as of 08Dec25, so searching through it means calls can take >60ms on a fast PC. Cache the index instead, using a hard coded last-known value as the start point
	{
		static cachedIndex:=421 ;Default index taken from v645 20Apr26, although this will be game data not client build dependant. This is obviously subject to change, but the actual location is likely to be close to this (and closer to this than 0, more to the point)
		MEMORY_SERVERSTATS:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.StatHandler.ServerStats
		if(MEMORY_SERVERSTATS["key",cachedIndex].Read()==this.STAT_AREA_CHARGES) ;Valid cache
		{
			return MEMORY_SERVERSTATS["value", cachedIndex].Read()
		}
		size:=MEMORY_SERVERSTATS.size.Read()
		if (size<0 OR size>5000) ;Sanity check
			return 0
		index:=cachedIndex ;First search from the cached index - it's more likely to have been pushed down the list by the addition of new stats than pulled up by one being deleted (I think...)
		while(++index<size) ;++index as we've already checked index. < size because collection is 0-indexed, so if size=100 last valid index=99
		{
			if (MEMORY_SERVERSTATS["key",index].Read()==this.STAT_AREA_CHARGES)
			{
				g_IBM.Logger.AddMessage("ReadRushAreaCharges() CACHE MISS cachedIndex=[" . cachedIndex . "] index=[" . index . "] please report this message") ;As the default may change we want to be informed
				cachedIndex:=index
				return MEMORY_SERVERSTATS["value", cachedIndex].Read()
			}
		}
		index:=cachedIndex ;Secondly search backwards from the index, as if a stat has been removed it's probably just a few
		while(--index>=0) ;--index as we checked index previously
		{
			if (MEMORY_SERVERSTATS["key",index].Read()==this.STAT_AREA_CHARGES)
			{
				g_IBM.Logger.AddMessage("ReadRushAreaCharges() CACHE MISS cachedIndex=[" . cachedIndex . "] index=[" . index . "] please report this message")
				cachedIndex:=index
				return MEMORY_SERVERSTATS["value", cachedIndex].Read()
			}
		}
		return 0
	}

	;------------------------------------------------------------------------------------
	;---General functions
	;------------------------------------------------------------------------------------

	UpdateRushTarget() ;Returns true if memory read was available and the cap actually changed
	{
		cap:=g_SF.Memory.IBM_GetCurrentCampaignFavourExponent()
		if (cap AND this.rushCap!=cap)
		{
			this.rushCap:=cap
			return true
		}
		return false
	}

	GetCappedRushCharges() ;Assumes that the cap is current
	{
		return Min(this.ReadRushAreaCharges(),this.rushCap)
	}
}

class IC_BrivMaster_Elly_Class extends IC_BrivMaster_Hero_Class
{
	__new(heroID,heroIndex)
	{
		base.__new(heroID,heroIndex)
		this.EFFECT_HANDLER_CARDS:="" ;Deck of Many Things effect handler cards object, dereferrenced from main memory functions for performance
		this.MEMORY_COTF_ULT_ACTIVE_ADDRESS:=""
		this.MEMORY_COTF_ULT_ACTIVE_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].effects.effectKeysByHashedKeyName.List[0].parentEffectKeyHandler.activeEffectHandlers[0].IsUltimateActive.ValueType ;This is a rather long way of writing "Char"
		this.EFFECT_KEY_DoMT:="ellywick_deck_of_many_things"
		this.EFFECT_KEY_CotF:="ellywick_call_of_the_feywild"
	}

	Reset()
	{
		base.Reset()
		this.EFFECT_HANDLER_CARDS:=""
		this.MEMORY_COTF_ULT_ACTIVE_ADDRESS:=""
	}

	;--------------------------------------------------------------------------------------
	;---Hero related memory reads
	;--------------------------------------------------------------------------------------

	InitDoMTHandler()
	{
		EK_HANDLER:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].effects.effectKeysByHashedKeyName
		EK_HANDLER_SIZE := EK_HANDLER.size.Read()
		loop, %EK_HANDLER_SIZE%
		{
			PARENT_HANDLER:=EK_HANDLER["value", A_Index - 1].List[0].parentEffectKeyHandler
			if (this.EFFECT_KEY_DOMT == PARENT_HANDLER.def.Key.Read())
			{
				this.EFFECT_HANDLER_CARDS:=PARENT_HANDLER.activeEffectHandlers[0].Clone()
				break
			}
		}
		if (this.EFFECT_HANDLER_CARDS)
			this.EFFECT_HANDLER_CARDS.IBM_ReBase() ;Breaks the links with the main memory management structure. This will mean it could (and usually will) become invalid on reset or restart
	}

	ReadEllywickUltimateActive() ;Uses InitCotFUltActive to set up the memory read. This will fail if the game has been restarted since the first call in the run
	{
		if(this.InitCotFUltActive())
			return _IBM_MM.instance.read(this.MEMORY_COTF_ULT_ACTIVE_ADDRESS,this.MEMORY_COTF_ULT_ACTIVE_TYPE)
		else
			return ""
	}

	InitCotFUltActive() ;Tries to initialise this.MEMORY_COTF_ULT_ACTIVE_ADDRESS, returns true if already set up or if setup is successful
	{
		if(this.MEMORY_COTF_ULT_ACTIVE_ADDRESS)
			return true
		EK_HANDLER:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].effects.effectKeysByHashedKeyName
		EK_HANDLER_SIZE:=EK_HANDLER.size.Read()
		loop, %EK_HANDLER_SIZE%
		{
			PARENT_HANDLER:=EK_HANDLER["value", A_Index - 1].List[0].parentEffectKeyHandler
			if (this.EFFECT_KEY_CotF==PARENT_HANDLER.def.Key.Read())
			{
				this.MEMORY_COTF_ULT_ACTIVE_ADDRESS:=g_SF.Memory.ResolvePointers(PARENT_HANDLER.activeEffectHandlers[0].IsUltimateActive)
				return true
			}
		}
		return false
	}

	GetNumCardsOfType(cardType) ;3 is Gem, 5 is Flames
	{
		numCards:=0
		loop, % this.EFFECT_HANDLER_CARDS.cardsInHand.size.Read()
		{
			if (cardType==this.EFFECT_HANDLER_CARDS.cardsInHand[A_index - 1].CardType.Read())
				numCards++
		}
		return numCards
	}

	ReadNumCards()
	{
		size:=this.EFFECT_HANDLER_CARDS.cardsInHand.size.Read()
		return size=="" ? 0 : size
	}

	UseUltimate(maxRetries:=50,exitOnceQueued:=false) ;Use ultimate, retrying up to the given number of times if the cooldown doesn't change. If exitOnceQueued is true the function will return as soon as the ultimate is queued - which may mean it never activates if something changes in the game state (area change most likely). Returns the number of attempts made. This is an override to make use of Elly's IsUltimateActive read, done because the ultimates bar method is not accurate enough when we need to follow with a DM reset
	{
		;TODO: Not sure this function should be hard coded offsets in a specific file like this - constants in a main file might be better? Applies later in this function as well. Maybe some wrapper somewhere?
		ULTIMATEITEMS_LIST:=g_SF.Memory.GameManager.game.gameInstances[0].Screen.uiController.ultimatesBar.ultimateItems
        ULTIMATE_HOTKEY:=""
		ADDRESS_ULTIMATEITEMS_LIST:=g_SF.Memory.ResolvePointers(ULTIMATEITEMS_LIST)
		ADDRESS_ULTIMATEITEMS_ITEMS:=_IBM_MM.instance.getAddressFromOffsets(ADDRESS_ULTIMATEITEMS_LIST,0x10)
		HEROID_OFFSET:=[ULTIMATEITEMS_LIST.hero.Offset[1],ULTIMATEITEMS_LIST.hero.def.Offset[1],ULTIMATEITEMS_LIST.hero.def.ID.Offset[1]] ;TODO: A lot of this never changes; should be prepared once only. Some kind of ultimate handler object?
		HEROID_TYPE:=ULTIMATEITEMS_LIST.hero.def.ID.ValueType ;TODO: This one can't change
		loop, % _IBM_MM.instance.read(ADDRESS_ULTIMATEITEMS_LIST,"Int",0x18)
        {
            ADDRESS_ULTIMATEITEMS_ITEM:=_IBM_MM.instance.getAddressFromOffsets(ADDRESS_ULTIMATEITEMS_ITEMS,0x20 + (A_Index-1) * 0x8)
			if (this.ID == _IBM_MM.instance.read(ADDRESS_ULTIMATEITEMS_ITEM,HEROID_TYPE,HEROID_OFFSET*))
			{
				ULTIMATE_HOTKEY:=_IBM_MM.instance.read(ADDRESS_ULTIMATEITEMS_ITEM,ULTIMATEITEMS_LIST.HotKey.ValueType,ULTIMATEITEMS_LIST.HotKey.Offset*)
				break
			}
        }
		if (ULTIMATE_HOTKEY=="") ;Return empty
			return
		if(!this.InitCotFUltActive()) ;Return empty
			return
		ULTIMATE_KEY:=g_InputManager.getKey(ULTIMATE_HOTKEY) ;TODO: Maybe the input manager should be passed as an argument to this function? Or if moved to an object it could just be passed over once at setup of that
		ULTIMATE_KEY.KeyPress()
		retryCount:=0
		ULTIMATEATTACK:=ULTIMATEITEMS_LIST.ultimateAttack
		ADDRESS_ULTIMATEATTACK:=_IBM_MM.instance.getAddressFromOffsets(ADDRESS_ULTIMATEITEMS_ITEM, ULTIMATEATTACK.Offset*)
		while (_IBM_MM.instance.read(this.MEMORY_COTF_ULT_ACTIVE_ADDRESS,this.MEMORY_COTF_ULT_ACTIVE_TYPE)!=1 AND retryCount < maxRetries) ;Check Elly's IsUltimateActive
		{
			if (_IBM_MM.instance.read(ADDRESS_ULTIMATEATTACK,ULTIMATEATTACK.queued.ValueType,ULTIMATEATTACK.queued.Offset*)) ;If the ultimate is queued, just wait on it
			{
				retryCount++ ;Counting this as 1/10th of a retry to avoid having to have some duplicate timeout in case the queued attack gets stuck forever
				if (exitOnceQueued)
					return retryCount
				g_IBM.IBM_Sleep(10)
			}
			else
			{
				ULTIMATE_KEY.KeyPress()
				retryCount+=10
				Sleep 0
			}
		}
		return retryCount
	}

	;------------------------------------------------------------------------------------
	;---General functions
	;------------------------------------------------------------------------------------

	GetNumGemCards()
	{
		return this.GetNumCardsOfType(3)
	}

	GetNumFlamesCards()
	{
		return this.GetNumCardsOfType(5)
	}
}

class IC_BrivMaster_Tatyana_Class extends IC_BrivMaster_Hero_Class
{
	__new(heroID,heroIndex)
	{
		base.__new(heroID,heroIndex)
		this.MEMORY_FAF_RETURN_TIMER_TYPE:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].effects.effectKeysByHashedKeyName.List[0].parentEffectKeyHandler.activeEffectHandlers[0].awaitReturnTimer.t.ValueType ;This is a rather long way of writing "Double"
		this.EFFECT_KEY_FAF:="tatyana_find_a_feast"
	}
	
	GetFindAFeastReturnTimerAddress() ;Returns the address of the Find a Feast Handler's await return timer; the read itself is not encapsulated since it's part of the stack loop
	{
		EK_HANDLER:=g_SF.Memory.GameManager.game.gameInstances[0].Controller.userData.HeroHandler.heroes[this.heroIndex].effects.effectKeysByHashedKeyName
		EK_HANDLER_SIZE:=EK_HANDLER.size.Read()
		loop, %EK_HANDLER_SIZE%
		{
			PARENT_HANDLER:=EK_HANDLER["value", A_Index - 1].List[0].parentEffectKeyHandler
			if (this.EFFECT_KEY_FAF==PARENT_HANDLER.def.Key.Read())
			{
				return g_SF.Memory.ResolvePointers(PARENT_HANDLER.activeEffectHandlers[0].awaitReturnTimer.t)
			}
		}
		g_IBM.Logger.AddMessage("Tatyana: unable to find Find a Feast handler")
		return ""
	}
}