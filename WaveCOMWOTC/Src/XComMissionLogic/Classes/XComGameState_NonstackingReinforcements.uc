class XComGameState_NonstackingReinforcements extends XComGameState_AIReinforcementSpawner;

function EventListenerReturn OnReinforcementSpawnerCreated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleData;
	local XComAISpawnManager SpawnManager;
	local int AlertLevel, ForceLevel;
	local XComGameStateHistory History;

	SpawnManager = `SPAWNMGR;
	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	ForceLevel = BattleData.GetForceLevel();
	AlertLevel = 1;

	// Select the spawning visualization mechanism and build the persistent in-world visualization for this spawner
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));

	NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.ModifyStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));

	// choose reinforcement spawn location

	// build a character selection that will work at this location
	SpawnManager.SelectPodAtLocation(NewSpawnerState.SpawnInfo, ForceLevel, AlertLevel, BattleData.ActiveSitReps);

	if( NewSpawnerState.SpawnVisualizationType == 'ChosenSpecialNoReveal' ||
	   NewSpawnerState.SpawnVisualizationType == 'ChosenSpecialTopDownReveal' )
	{
		NewSpawnerState.SpawnInfo.bDisableScamper = true;
	}

	// enable timed loot for WaveCOM reinforcements
	NewSpawnerState.SpawnInfo.bGroupDoesNotAwardLoot = false;

	NewSpawnerState.SpawnVisualizationType = 'PsiGate';

	if( NewSpawnerState.SpawnVisualizationType != '' && 
	   NewSpawnerState.SpawnVisualizationType != 'TheLostSwarm' && 
	   NewSpawnerState.SpawnVisualizationType != 'ChosenSpecialNoReveal' &&
	   NewSpawnerState.SpawnVisualizationType != 'ChosenSpecialTopDownReveal' )
	{
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = NewSpawnerState.BuildVisualizationForSpawnerCreation;
		NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);
	}

	`TACTICALRULES.SubmitGameState(NewGameState);

	// no countdown specified, spawn reinforcements immediately
	if( Countdown <= 0 )
	{
		NewSpawnerState.SpawnReinforcements();
	}
	// countdown is active, need to listen for AI Turn Begun in order to tick down the countdown
	else
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;

		PlayerState = class'XComGameState_Player'.static.GetPlayerState(NewSpawnerState.SpawnInfo.Team);
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnTurnBegun, ELD_OnStateSubmitted, , PlayerState);
	}

	return ELR_NoInterrupt;
}

static function bool InitiateReinforcements(
	Name EncounterID, 
	optional int OverrideCountdown, 
	optional bool OverrideTargetLocation,
	optional const out Vector TargetLocationOverride,
	optional int IdealSpawnTilesOffset,
	optional XComGameState IncomingGameState,
	optional bool InKismetInitiatedReinforcements,
	optional Name InSpawnVisualizationType = 'PsiGate',
	optional bool InDontSpawnInLOSOfXCOM,
	optional bool InMustSpawnInLOSOfXCOM,
	optional bool InDontSpawnInHazards,
	optional bool InForceScamper,
	optional bool bAlwaysOrientAlongLOP, 
	optional bool bIgnoreUnitCap)
{
	local XComGameState_NonstackingReinforcements NewAIReinforcementSpawnerState, ExistingSpawnerState;
	local XComGameState NewGameState;
	local XComTacticalMissionManager MissionManager;
	local ConfigurableEncounter Encounter;
	local XComAISpawnManager SpawnManager;
	local Vector DesiredSpawnLocation;

	local bool ReinforcementsCleared;
	local int TileOffset;
	
	if( !bIgnoreUnitCap && LivingUnitCapReached(InSpawnVisualizationType == 'TheLostSwarm') )
	{
		return false;
	}

	SpawnManager = `SPAWNMGR;

	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.GetConfigurableEncounter(EncounterID, Encounter);

	if (IncomingGameState == none)
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Creating Reinforcement Spawner");
	else
		NewGameState = IncomingGameState;

	// Update AIPlayerData with CallReinforcements data.
	NewAIReinforcementSpawnerState = XComGameState_NonstackingReinforcements(NewGameState.CreateNewStateObject(class'XComGameState_NonstackingReinforcements'));
	NewAIReinforcementSpawnerState.SpawnInfo.EncounterID = EncounterID;

	NewAIReinforcementSpawnerState.SpawnVisualizationType = InSpawnVisualizationType;
	NewAIReinforcementSpawnerState.bDontSpawnInLOSOfXCOM = InDontSpawnInLOSOfXCOM;
	NewAIReinforcementSpawnerState.bMustSpawnInLOSOfXCOM = InMustSpawnInLOSOfXCOM;
	NewAIReinforcementSpawnerState.bDontSpawnInHazards = InDontSpawnInHazards;
	NewAIReinforcementSpawnerState.bForceScamper = InForceScamper;

	if( OverrideCountdown > 0 )
	{
		NewAIReinforcementSpawnerState.Countdown = OverrideCountdown;
	}
	else
	{
		NewAIReinforcementSpawnerState.Countdown = Encounter.ReinforcementCountdown;
	}

	if (Encounter.TeamToSpawnInto == eTeam_TheLost)
	{
		NewAIReinforcementSpawnerState.Countdown++; // Losts turn is after alien's turn, so to properly match the alien's reinforcement interval you need to add 1 turn
	}

	if( OverrideTargetLocation )
	{
		DesiredSpawnLocation = TargetLocationOverride;
	}
	else
	{
		DesiredSpawnLocation = SpawnManager.GetCurrentXComLocation();
	}

	NewAIReinforcementSpawnerState.SpawnInfo.SpawnLocation = SpawnManager.SelectReinforcementsLocation(
		NewAIReinforcementSpawnerState, 
		DesiredSpawnLocation, 
		IdealSpawnTilesOffset, 
		InMustSpawnInLOSOfXCOM,
		InDontSpawnInLOSOfXCOM,
		InSpawnVisualizationType == 'ATT',
		bAlwaysOrientAlongLOP); // ATT vis type requires vertical clearance at the spawn location

	ReinforcementsCleared = false;
	TileOffset = 0;

	while (!ReinforcementsCleared)
	{
		if (TileOffset > 15)
		{
			// Max tries
			//Discard gamestate and return
			if (IncomingGameState == none)
				`XCOMHISTORY.CleanupPendingGameState(NewGameState);
			`log("!!!!!!REINF SPAWNER FAILED TO SPAWN!!!!!!! TOO CLUTTERED!!!",, 'WaveCOM');
			return false;
		}
		ReinforcementsCleared = true;
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_NonstackingReinforcements', ExistingSpawnerState)
		{
			// Must not be same reinforcements object and must be pending for reinforcements
			if (ExistingSpawnerState.ObjectID != NewAIReinforcementSpawnerState.ObjectID && ExistingSpawnerState.Countdown > 0)
			{
				if (NewAIReinforcementSpawnerState.SpawnInfo.SpawnLocation == ExistingSpawnerState.SpawnInfo.SpawnLocation)
				{
					ReinforcementsCleared = false;
					// Move reinforcements away and reroll
					TileOffset++;
					NewAIReinforcementSpawnerState.SpawnInfo.SpawnLocation = SpawnManager.SelectReinforcementsLocation(
						NewAIReinforcementSpawnerState, 
						DesiredSpawnLocation, 
						IdealSpawnTilesOffset + TileOffset, 
						InMustSpawnInLOSOfXCOM,
						InDontSpawnInLOSOfXCOM,
						InSpawnVisualizationType == 'ATT',
						bAlwaysOrientAlongLOP); // ATT vis type requires vertical clearance at the spawn location
					break;
				}
			}
		}
	}

	NewAIReinforcementSpawnerState.bKismetInitiatedReinforcements = InKismetInitiatedReinforcements;

	if (IncomingGameState == none)
		`TACTICALRULES.SubmitGameState(NewGameState);

	return true;
}

function EventListenerReturn OnSpawnReinforcementsComplete(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local array<XComGameState_Unit> AffectedUnits;
	local XComGameState_Unit AffectedUnit;
	local int i;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(default.SpawnReinforcementsCompleteChangeDesc);

	if( SpawnVisualizationType != '' && 
	   SpawnVisualizationType != 'TheLostSwarm' &&
	   SpawnVisualizationType != 'ChosenSpecialNoReveal' &&
	   SpawnVisualizationType != 'ChosenSpecialTopDownReveal' )
	{
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForSpawnerDestruction;
	}

	for( i = 0; i < SpawnedUnitIDs.Length; ++i )
	{
		AffectedUnits.AddItem(XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitIDs[i])));

		if( SpawnVisualizationType == 'ChosenSpecialNoReveal' ||
		   SpawnVisualizationType == 'ChosenSpecialTopDownReveal' )
		{
			AffectedUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SpawnedUnitIDs[i]));
			AffectedUnit.bTriggerRevealAI = true;
			// Trigger Lightning Reflexes properly
			if (AffectedUnit.HasSoldierAbility('LightningReflexes', true) )
			{
				AffectedUnit.bLightningReflexes = true;
			}
		}
	}

	// if there was an ATT, remove it now
	if( TroopTransportRef.ObjectID > 0 )
	{
		NewGameState.RemoveStateObject(TroopTransportRef.ObjectID);
	}

	// remove this state object, now that we are done with it
	NewGameState.RemoveStateObject(ObjectID);

	NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);

	AlertAndScamperUnits(NewGameState, AffectedUnits, bForceScamper, GameState.HistoryIndex, SpawnVisualizationType);

	return ELR_NoInterrupt;
}
