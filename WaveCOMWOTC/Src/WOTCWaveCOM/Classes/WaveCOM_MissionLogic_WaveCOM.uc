class WaveCOM_MissionLogic_WaveCOM extends XComGameState_MissionLogic config(WaveCOM);

var config bool REFILL_ITEM_CHARGES;

enum eWaveStatus
{
	eWaveStatus_Preparation,
	eWaveStatus_Combat,
};

var eWaveStatus WaveStatus;
var int CombatStartCountdown;
var int WaveNumber;
var bool AliensDefeated;

var array<name> ActiveSitReps;

var int OldSupply;

struct WaveEncounter {
	var name EncounterID;
	var int Earliest;
	var int Latest;
	var int Weighting;
	var name IncludeTacticalTag;
	var name ExcludeTacticalTag;
	var bool TacticalTagOverride; // If this is true, this will remove all other encounters without tacticaltagoverride if it is valid, requires IncludeTacticalTag

	structdefaultproperties
	{
		Earliest = 0
		Latest = 1000
		Weighting = 1
	}
};

struct SitRepWaveModifier {
	var int WaveCountMod;
	var name SitRep;
};

struct RollForSitRep {
	var name SitRepTemplateName;
	var int Weight;
};

var const config int WaveCOMKillSupplyBonusBase;
var const config float WaveCOMKillSupplyBonusMultiplier;
var const config int WaveCOMWaveSupplyBonusBase;
var const config float WaveCOMWaveSupplyBonusMultiplier;
var const config float WaveCOMWaveSupplyBonusMax;
var const config int WaveCOMIntelBonusBase;
var const config float WaveCOMKillIntelBonusBase;
var const config int WaveCOMPassiveXPPerKill;
var const config array<int> WaveCOMPodCount;
var const config array<int> WaveCOMForceLevel;
var const config array<WaveEncounter> WaveEncounters;
var const config array<SitRepWaveModifier> SitRepModifiers;
var const config array<int> MaxLostWaves;
var const config array<RollForSitRep> SitRepGenerateData;
var const config array<int> SitRepChance;

delegate EventListenerReturn OnEventDelegate(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData);

function EventListenerReturn RemoveExcessUnits(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local StateObjectReference ItemReference, BlankReference;
	local XComGameState_Unit UnitState, CosmeticUnit;
	local XComGameState_Item ItemState;
	local XComGameState NewGameState;
	local TTile NextTile;
	local Vector NextSpawn;
	local X2EquipmentTemplate EquipmentTemplate;
	local Object this;
	local XGUnit Visualizer;
	local WaveCOMGameStateContext_UpdateUnit EffectContext;
	local XComPerkContentShared	hPawnPerk;
	local XGWeapon WeaponVis;
	local XComWeapon WeaponMeshVis;
	local array<XComGameState_Unit> UnitToSyncVis;

	class'WaveCOM_UILoadoutButton'.static.ChooseSpawnLocation(NextSpawn);
	NextTile = `XWORLD.GetTileCoordinatesFromPosition(NextSpawn);

	`log(" WaveCOM MissionLogic :: Begin clearing excess units. Coordinates:" @ NextTile.X $ "," $ NextTile.Y $ "," $ NextTile.Z);

	// Remove excess Units
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (`XCOMHQ.Squad.Find('ObjectID', UnitState.GetReference().ObjectID) != INDEX_NONE)
		{
			if (UnitState.TileLocation == NextTile) // If a new tile chosen is occupied, that means any unit on that tile are extras
			{
				EffectContext = class'WaveCOMGameStateContext_UpdateUnit'.static.CreateChangeStateUU("Removing Excess Units", UnitState);
				NewGameState = EffectContext.GetGameState();

				`log("Cleaning Abilities");
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				class'WaveCOM_UIArmory_FieldLoadout'.static.ClearAbilities(UnitState, NewGameState);
				Visualizer = XGUnit(UnitState.FindOrCreateVisualizer());
				foreach Visualizer.GetPawn().arrTargetingPerkContent(hPawnPerk)
				{
					hPawnPerk.RemovePerkTarget( XGUnit(Visualizer.GetPawn().m_kGameUnit) );
				}
				Visualizer.GetPawn().StopPersistentPawnPerkFX(); // Remove all abilities visualizers

				foreach UnitState.InventoryItems(ItemReference)
				{
					ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemReference.ObjectID));
					if( ItemState.OwnerStateObject.ObjectID == UnitState.ObjectID )
					{
						EquipmentTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
						if( EquipmentTemplate != none && EquipmentTemplate.CosmeticUnitTemplate != "" && ItemState.CosmeticUnitRef.ObjectID != 0)
						{
							`log("Murdering a gremlin");
							CosmeticUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ItemState.CosmeticUnitRef.ObjectID));
							CosmeticUnit.RemoveUnitFromPlay();
							ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemReference.ObjectID));
							class'WaveCOM_UIArmory_FieldLoadout'.static.UnRegisterForCosmeticUnitEvents(ItemState, ItemState.CosmeticUnitRef);
							ItemState.CosmeticUnitRef = BlankReference;
						}

						WeaponVis = XGWeapon(ItemState.GetVisualizer());
						if (WeaponVis != None && ItemState.GetMyTemplate().iItemSize > 0)
						{
							WeaponMeshVis = WeaponVis.GetEntity();
							if (WeaponMeshVis != None)
							{
								WeaponMeshVis.Mesh.SetHidden(false);
							}
						}
					}
				}
				class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState);
				UnitState.RemoveUnitFromPlay();
				`XWORLD.ClearTileBlockedByUnitFlag(UnitState);
				`XEVENTMGR.TriggerEvent('UpdateDeployCostDelayed',,, NewGameState);

				if(NewGameState.GetNumGameStateObjects() > 0)
				{
					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
				}
				else
				{
					`XCOMHISTORY.CleanupPendingGameState(NewGameState);
				}
			}
			else
			{
				// Refresh unit state to ensure events are registered correctly.
				FullRefreshSoldier(UnitState.GetReference());
				UnitToSyncVis.AddItem(UnitState);
			}
		}
	}

	class'WaveCOM_UIArmory_FieldLoadout'.static.SyncVisualizers(UnitToSyncVis);

	this = self;

	`XEVENTMGR.UnRegisterFromEvent(this, 'HACK_RemoveExcessSoldiers');

	return ELR_NoInterrupt;
}

function SetupMissionStartState(XComGameState StartState)
{
	local XComGameState_BlackMarket BlackMarket;
	local XComGameState_BattleData BattleData;
	local Object ThisObj;

	`log("WaveCOM :: Setting Up State - Refresh Black Market and Remove extra units");
	
	BlackMarket = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	BlackMarket = XComGameState_BlackMarket(StartState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarket.ObjectID));
	BlackMarket.ResetBlackMarketGoods(StartState);

	UpdateCombatCountdown(StartState);

	class'X2DownloadableContentInfo_WOTCWaveCOM'.static.FixGroupSpawn(); // TEMP FIX FOR TACTICAL TRANSFER CAUSING NO ACTIONS

	ThisObj = self;
	
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData.SetGlobalAbilityEnabled( 'PlaceEvacZone', false, StartState);
	BattleData.SetGlobalAbilityEnabled( 'ChosenKidnapMove', false, StartState);

	`XEVENTMGR.RegisterForEvent(ThisObj, 'HACK_RemoveExcessSoldiers', RemoveExcessUnits, ELD_OnStateSubmitted,, StartState);
	`XEVENTMGR.TriggerEvent('HACK_RemoveExcessSoldiers', StartState, StartState, StartState);
}

function RegisterEventHandlers()
{	
	`log("WaveCOM :: Setting Up Event Handlers");

	OnAlienTurnBegin(Countdown);
	OnNoPlayableUnitsRemaining(HandleTeamDead);
}

function UpdateCombatCountdown(optional XComGameState NewGameState)
{
	local WaveCOM_MissionLogic_WaveCOM MissionState;
	
	if (NewGameState != none)
		MissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.GetGameStateForObjectID(ObjectID));
	if (MissionState == none)
		MissionState = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if (MissionState.WaveStatus == eWaveStatus_Preparation)
	{
		if (NewGameState != none)
			ModifyMissionTimerInState(true, MissionState.CombatStartCountdown, "Prepare", "Next Wave in", Bad_Red, NewGameState);
		else
			ModifyMissionTimer(true, MissionState.CombatStartCountdown, "Prepare", "Next Wave in", Bad_Red);
	}
	else
	{
		if (NewGameState != none)
			ModifyMissionTimerInState(true, MissionState.WaveNumber, "Wave Number", "In Progress",, NewGameState); // hide timer
		else
			ModifyMissionTimer(true, MissionState.WaveNumber, "Wave Number", "In Progress"); // hide timer
	}
}

function EventListenerReturn Countdown(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local WaveCOM_MissionLogic_WaveCOM NewMissionState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> ItemStates;
	local XComGameState_Unit UnitState;
	local WaveCOM_MissionLogic_WaveCOM MissionState;

	MissionState = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));

	if (MissionState.WaveStatus == eWaveStatus_Preparation)
	{

		History = `XCOMHISTORY;
	
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Collect Wave Loot during Preparation");
		NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', ObjectID));
		NewMissionState.CombatStartCountdown -= 1;
		`log("WaveCOM :: Counting Down - " @ NewMissionState.CombatStartCountdown);
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		// recover loot collected during preparation turns
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.GetTeam() == eTeam_XCom)
			{
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				ItemStates = UnitState.GetAllItemsInSlot(eInvSlot_Backpack, NewGameState);
				foreach ItemStates(ItemState)
				{
					ItemState.OwnerStateObject = XComHQ.GetReference();
					UnitState.RemoveItemFromInventory(ItemState, NewGameState);
					XComHQ.PutItemInInventory(NewGameState, ItemState, false);
				}
			}
		}
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		if (NewMissionState.CombatStartCountdown == 0)
		{
			InitiateWave();
		}

		class'X2DownloadableContentInfo_WOTCWaveCOM'.static.FixGroupSpawn(); // TEMP FIX FOR TACTICAL TRANSFER CAUSING NO ACTIONS
	}

	UpdateCombatCountdown();
	return ELR_NoInterrupt;
}

static function int GetForceLevel(int InWaveNumber)
{
	local int ForceLevel;
	if (InWaveNumber > default.WaveCOMForceLevel.Length - 1)
	{
		ForceLevel = default.WaveCOMForceLevel[default.WaveCOMForceLevel.Length - 1];
	}
	else
	{
		ForceLevel = default.WaveCOMForceLevel[InWaveNumber];
	}
	ForceLevel = Clamp(ForceLevel, 1, 20);

	return ForceLevel;
}

static function int GetSitRepChance(int InWaveNumber)
{
	local int Chance;
	if (InWaveNumber > default.SitRepChance.Length - 1)
	{
		Chance = default.SitRepChance[default.SitRepChance.Length - 1];
	}
	else
	{
		Chance = default.SitRepChance[InWaveNumber];
	}
	Chance = Clamp(Chance, 0, 100);

	`log(Chance $ "% to roll a sitrep",, 'WaveCOM');

	return Chance;
}

function InitiateWave()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local WaveCOM_MissionLogic_WaveCOM NewMissionState;
	local array<WaveEncounter> WeightedStack;
	local WaveEncounter Encounter;
	local int Pods, Weighting, MaxWeight, ForceLevel, idx;
	local Vector ObjectiveLocation;
	local SitRepWaveModifier SitRepMod;
	local bool bRemoveNonOverrideEncounters;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Force Level");

	NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', ObjectID));
	NewMissionState.WaveStatus = eWaveStatus_Combat;
	NewMissionState.WaveNumber = NewMissionState.WaveNumber + 1;
	NewMissionState.AliensDefeated = false;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData.InternalActivateChosenAlert();
	ObjectiveLocation = BattleData.MapData.ObjectiveLocation;
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	ForceLevel = GetForceLevel(NewMissionState.WaveNumber);

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	AlienHQ.ForceLevel = ForceLevel;

	BattleData.SetForceLevel(ForceLevel);
	BattleData.LostQueueStrength = 0; // Reset Lost counter
	if (NewMissionState.WaveNumber > default.MaxLostWaves.Length - 1)
	{
		BattleData.LostMaxWaves = default.MaxLostWaves[default.MaxLostWaves.Length - 1];
	}
	else
	{
		BattleData.LostMaxWaves = default.MaxLostWaves[NewMissionState.WaveNumber];
	}
	BattleData.bLostSpawningDisabledViaKismet = false; // Re-enable lost spawning in case we want it.
	BattleData.LostSpawningLevel = BattleData.SelectLostActivationCount();
	
	`SPAWNMGR.ForceLevel = ForceLevel;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	if (NewMissionState.WaveNumber > WaveCOMPodCount.Length - 1)
	{
		Pods = WaveCOMPodCount[WaveCOMPodCount.Length - 1];
	}
	else
	{
		Pods = WaveCOMPodCount[NewMissionState.WaveNumber];
	}

	foreach default.SitRepModifiers(SitRepMod)
	{
		if ( XComHQ.TacticalGameplayTags.Find(SitRepMod.SitRep) != INDEX_NONE )
		{
			Pods += SitRepMod.WaveCountMod;
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	MaxWeight = 0;

	foreach default.WaveEncounters(Encounter)
	{
		if (Encounter.Earliest <= NewMissionState.WaveNumber && Encounter.Latest >= NewMissionState.WaveNumber && Encounter.Weighting > 0)
		{
			if( Encounter.IncludeTacticalTag != '' && XComHQ.TacticalGameplayTags.Find(Encounter.IncludeTacticalTag) == INDEX_NONE )
			{
				continue;
			}

			// if this pre-placed encounter depends on not having a tactical gameplay tag, and that tag is present, the encounter group will not spawn
			if( Encounter.ExcludeTacticalTag != '' && XComHQ.TacticalGameplayTags.Find(Encounter.ExcludeTacticalTag) != INDEX_NONE )
			{
				continue;
			}

			if ( Encounter.TacticalTagOverride && Encounter.IncludeTacticalTag != '')
			{
				bRemoveNonOverrideEncounters = true;
			}

			WeightedStack.AddItem(Encounter);

			MaxWeight += Encounter.Weighting;
		}
	}

	if (bRemoveNonOverrideEncounters)
	{
		for (idx = 0; idx < WeightedStack.Length; idx++)
		{
			if (!WeightedStack[idx].TacticalTagOverride)
			{
				WeightedStack.Remove(idx, 1);
				idx--;
			}
		}
	}

	while (Pods > 0 && WeightedStack.Length > 0)
	{
		idx = -1;
		Weighting = Rand(MaxWeight);
		while (Weighting >= 0 && WeightedStack.Length > idx + 1)
		{
			Weighting -= WeightedStack[++idx].Weighting;
		}
		Encounter = WeightedStack[idx];
		class'XComGameState_NonstackingReinforcements'.static.InitiateReinforcements(
			Encounter.EncounterID,
			1, // FlareTimer
			true, // bUseOverrideTargetLocation,
			ObjectiveLocation, // OverrideTargetLocation, 
			40, // Spawn tiles offset
			,
			,
			,
			false,
			false,
			true,
			true,
			false,
			true
		);
		--Pods;
	}

	`XEVENTMGR.TriggerEvent('WaveCOM_WaveStart');

}

function HandleTeamDead(array<XGPlayer> LosingPlayers, array<XGPlayer> AllPlayers)
{
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local XGPlayer LosingPlayer, APlayer;
	local WaveCOM_MissionLogic_WaveCOM MissionState, NewMissionState;
	local bool NoAliensLeft, NoLostLeft;

	MissionState = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	NoAliensLeft = true;
	NoLostLeft = true;
	foreach AllPlayers(APlayer)
	{
		if (APlayer.m_eTeam == eTeam_Alien)
		{
			NoAliensLeft = MissionState.AliensDefeated;
			`log("HandleTeamDead called - No aliens left?" @ NoAliensLeft,, 'WaveCOM');
		}
		else if (APlayer.m_eTeam == eTeam_TheLost)
		{
			NoLostLeft = BattleData.bLostSpawningDisabledViaKismet;
			`log("HandleTeamDead called - No losts left?" @ NoLostLeft,, 'WaveCOM');
		}
	}

	foreach LosingPlayers(LosingPlayer)
	{
		`log("HandleTeamDead called: dying player" @ ETeam(LosingPlayer.m_eTeam),, 'WaveCOM');
		if (LosingPlayer.m_eTeam == eTeam_Alien && !NewMissionState.AliensDefeated)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update alien defeated");
			NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', ObjectID));
			NewMissionState.AliensDefeated = true;
			NoAliensLeft = true;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if (LosingPlayer.m_eTeam == eTeam_TheLost && !BattleData.bLostSpawningDisabledViaKismet)
		{
			// Stop Lost reinforcements
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update lost defeated");

			BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
			BattleData.bLostSpawningDisabledViaKismet = true;
			NoLostLeft = true;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if (LosingPlayer.m_eTeam == eTeam_XCom)
		{
			`TACTICALRULES.EndBattle(LosingPlayer, eUICombatLose_UnfailableGeneric, false);
		}
	}

	if (NoLostLeft && NoAliensLeft && MissionState.WaveStatus == eWaveStatus_Combat)
	{
		`log("Alines and losts are dead, beginning prep phase",, 'WaveCOM');
		BeginPreparationRound();
	}
}

function ShowWaveCompleteMessage(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata ActionMetadata, EmptyMetadata;
	local X2Action_StartStopSound SoundAction;
	local X2Action_UpdateUI UIUpdateAction;
	local X2Action_Delay DelayAction;
	local X2Action_CentralBanner BannerAction;
	local XComGameState_HeadquartersXCom XComHQ, OldHQ;
	local XComGameStateContext Context;
	local WaveCOM_MissionLogic_WaveCOM MissionState;
	
	local X2SitRepTemplate SitRepTemplate;
	local X2SitRepTemplateManager SitRepManager;
	local int idx;

	Context = VisualizeGameState.GetContext();

	OldHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	OldHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetGameStateForObjectID(OldHQ.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	XComHQ = XComGameState_HeadquartersXCom(VisualizeGameState.GetGameStateForObjectID(OldHQ.ObjectID));

	MissionState = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	SitRepManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();

	ActionMetadata = EmptyMetadata;
	ActionMetadata.StateObject_OldState = OldHQ;
	ActionMetadata.StateObject_NewState = XComHQ;

	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	UIUpdateAction.UpdateType = EUIUT_SetHUDVisibility;
	UIUpdateAction.DesiredHUDVisibility.bMessageBanner = true;

	BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	BannerAction.BannerText = "WAVE" @ MissionState.WaveNumber @ "COMPLETE!";
	BannerAction.BannerState = eUIState_Normal;

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAction.Sound = new class'SoundCue';
	SoundAction.Sound.AkEventOverride = AkEvent'XPACK_SoundTacticalUI.Panic_Check_Start';
	SoundAction.bIsPositional = false;
	SoundAction.WaitForCompletion = true;

	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	DelayAction.Duration = 2.5;
	DelayAction.bIgnoreZipMode = true;

	BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	BannerAction.BannerText = "+" $ XComHQ.GetSupplies() - OldSupply @ "Supplies";
	BannerAction.BannerState = eUIState_Good;

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAction.Sound = new class'SoundCue';
	SoundAction.Sound.AkEventOverride = AkEvent'SoundTacticalUI.TacticalUI_UnitFlagPositive';
	SoundAction.bIsPositional = false;
	SoundAction.WaitForCompletion = false;

	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	DelayAction.bIgnoreZipMode = true;
	DelayAction.Duration = 3.0; 

	for (idx = 0; idx < MissionState.ActiveSitReps.Length; idx++)
	{
		SitRepTemplate = SitRepManager.FindSitRepTemplate(MissionState.ActiveSitReps[idx]);
		BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		BannerAction.BannerText = "Next Wave SitRep:" @ SitRepTemplate.GetFriendlyName();
		BannerAction.BannerState = eUIState_Bad;

		SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		SoundAction.Sound = new class'SoundCue';
		SoundAction.Sound.AkEventOverride = AkEvent'SoundTacticalUI.TacticalUI_UnitFlagWarning';
		SoundAction.bIsPositional = false;
		SoundAction.WaitForCompletion = false;

		DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		DelayAction.bIgnoreZipMode = true;
		DelayAction.Duration = 2.5; 
	}

	// 6a) Lower Special Event overlay
	BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	BannerAction.BannerText = "";

	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	UIUpdateAction.UpdateType = EUIUT_RestoreHUDVisibility;
}

function CollectLootToHQ()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local float FloatingIntel;
	local int LootIndex, SupplyReward, BonusReward, IntelReward, KillCount;
	local X2ItemTemplateManager ItemTemplateManager;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> ItemStates;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Unit UnitState, OldUnitState;
	local array<XComGameState_Unit> BondingSoldiers;
	local WaveCOM_MissionLogic_WaveCOM MissionState;
	local array<XComGameState_Unit> UnitToSyncVis;

	local LootResults PendingAutoLoot;
	local Name LootTemplateName;
	local array<Name> RolledLoot;

	History = `XCOMHISTORY;

	MissionState = WaveCOM_MissionLogic_WaveCOM(History.GetGameStateForObjectID(ObjectID));
	
	KillCount = 0;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Collect Wave Loot");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = ShowWaveCompleteMessage;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	// Reset AP Events
	BattleData.TacticalEventGameStates.Length = 0;
	BattleData.TacticalEventAbilityPointsGained = 0;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		OldUnitState = XComGameState_Unit(History.GetOriginalGameStateRevision(UnitState.ObjectID));
		if( UnitState.IsAdvent() || UnitState.IsAlien() || OldUnitState.GetTeam() == eTeam_TheLost )
		{
			if ( !UnitState.bBodyRecovered ) {
				class'X2LootTableManager'.static.GetLootTableManager().RollForLootCarrier(UnitState.GetMyTemplate().Loot, PendingAutoLoot);

				// repurpose bBodyRecovered as a way to determine whether we got the loot yet
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UnitState.bBodyRecovered = true;
				UnitState.RemoveUnitFromPlay(); // must be done in the name of performance
				UnitState.OnEndTacticalPlay(NewGameState); // Release all event handlers to improve performance
				++KillCount;

				if( PendingAutoLoot.LootToBeCreated.Length > 0 )
				{
					foreach PendingAutoLoot.LootToBeCreated(LootTemplateName)
					{
						ItemTemplate = ItemTemplateManager.FindItemTemplate(LootTemplateName);
						SupplyReward = SupplyReward + Round(ItemTemplate.TradingPostValue * WaveCOMKillSupplyBonusMultiplier);
						SupplyReward = SupplyReward + WaveCOMKillSupplyBonusBase;
						if ( OldUnitState.GetTeam() != eTeam_TheLost )
						{
							FloatingIntel += WaveCOMKillIntelBonusBase;
						}
						RolledLoot.AddItem(ItemTemplate.DataName);
					}

				}
				PendingAutoLoot.LootToBeCreated.Remove(0, PendingAutoLoot.LootToBeCreated.Length);
				PendingAutoLoot.AvailableLoot.Remove(0, PendingAutoLoot.AvailableLoot.Length);
			}
		}
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.AddXp(KillCount * WaveCOMPassiveXPPerKill);
			UnitState.bRankedUp = false; // reset ranking to prevent blocking of future promotions

			ItemStates = UnitState.GetAllItemsInSlot(eInvSlot_Backpack, NewGameState);
			foreach ItemStates(ItemState)
			{
				ItemState.OwnerStateObject = XComHQ.GetReference();
				UnitState.RemoveItemFromInventory(ItemState, NewGameState);
				XComHQ.PutItemInInventory(NewGameState, ItemState, false);
			}

			// Recover all dead soldier's items.
			if (UnitState.IsDead())
			{
				ItemStates = UnitState.GetAllInventoryItems(NewGameState, true);
				foreach ItemStates(ItemState)
				{
					ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));

					if (UnitState.RemoveItemFromInventory(ItemState, NewGameState)) //  possible we'll have some items that cannot be removed, so don't recover them
					{
						ItemState.OwnerStateObject = XComHQ.GetReference();
						XComHQ.PutItemInInventory(NewGameState, ItemState, false);
					}
				}
				
				XComHQ.Squad.RemoveItem(UnitState.GetReference()); // Remove from squad
				UnitState.RemoveUnitFromPlay(); // RIP
				UnitState.OnEndTacticalPlay(NewGameState); // Release all event handlers to improve performance
			}
			else if (XComHQ.Squad.Find('ObjectID', UnitState.ObjectID) != INDEX_NONE)
			{
				BondingSoldiers.AddItem(UnitState);
			}
		}
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	for( LootIndex = 0; LootIndex < RolledLoot.Length; ++LootIndex )
	{
		// create the loot item
		`log("Added Loot: " @RolledLoot[LootIndex]);
		ItemState = ItemTemplateManager.FindItemTemplate(
			RolledLoot[LootIndex]
		).CreateInstanceFromTemplate(NewGameState);

		// assign the XComHQ as the new owner of the item
		ItemState.OwnerStateObject = XComHQ.GetReference();

		// add the item to the HQ's inventory (false so it automatically goes to stack)
		XComHQ.PutItemInInventory(NewGameState, ItemState, false);
	}

	BonusReward = default.WaveCOMWaveSupplyBonusBase;
	BonusReward = BonusReward + Round(MissionState.WaveNumber * default.WaveCOMWaveSupplyBonusMultiplier);
	if (default.WaveCOMWaveSupplyBonusMax > 0)
	{
		BonusReward = min(BonusReward, default.WaveCOMWaveSupplyBonusMax);
	}

	SupplyReward += BonusReward;

	ItemTemplate = ItemTemplateManager.FindItemTemplate('Supplies');
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	ItemState.Quantity = Round(SupplyReward);
	OldSupply = XComHQ.GetSupplies(); // This is kinda hacky but due to the way item states are accessed, there's not much I can do
	XComHQ.PutItemInInventory(NewGameState, ItemState, false);

	IntelReward = WaveCOMIntelBonusBase;
	IntelReward += Round(FloatingIntel);

	ItemTemplate = ItemTemplateManager.FindItemTemplate('Intel');
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	ItemState.Quantity = IntelReward;
	XComHQ.PutItemInInventory(NewGameState, ItemState, false);

	// Bond the Soldiers
	class'XComGameStateContext_StrategyGameRule'.static.AdjustSoldierBonds(BondingSoldiers);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Reset Unit Abilities
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom && UnitState.IsSoldier() )
		{
			FullRefreshSoldier(UnitState.GetReference());
			UnitToSyncVis.AddItem(UnitState);
		}
	}

	class'WaveCOM_UIArmory_FieldLoadout'.static.SyncVisualizers(UnitToSyncVis);
}

static function FullRefreshSoldier(StateObjectReference UnitRef)
{
	local XComGameState NewGameState;
	local WaveCOMGameStateContext_UpdateUnit EffectContext;
	local XGUnit Visualizer;
	local XComPerkContentShared hPawnPerk;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	EffectContext = class'WaveCOMGameStateContext_UpdateUnit'.static.CreateChangeStateUU("Clean Unit State", UnitState);
	NewGameState = EffectContext.GetGameState();
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	`log("~~~Cleaning and readding Abilities for" @ UnitRef.ObjectID @ UnitState.GetFullName(),, 'WaveCOM');
	class'WaveCOM_UIArmory_FieldLoadout'.static.ClearAbilities(UnitState, NewGameState);
	Visualizer = XGUnit(UnitState.FindOrCreateVisualizer());
	foreach Visualizer.GetPawn().arrTargetingPerkContent(hPawnPerk)
	{
		hPawnPerk.RemovePerkTarget( XGUnit(Visualizer.GetPawn().m_kGameUnit) );
	}
	Visualizer.GetPawn().StopPersistentPawnPerkFX(); // Remove all abilities visualizers

	class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState);
	class'WaveCOM_UIArmory_FieldLoadout'.static.RefillInventory(NewGameState, UnitState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("~Cleanup complete, commencing refresh for" @ UnitRef.ObjectID @ UnitState.GetFullName(),, 'WaveCOM');
	UnitRef = UnitState.GetReference();
	if (UnitState.IsAlive() && XComHQ.Squad.Find('ObjectID', UnitRef.ObjectID) != INDEX_NONE && !UnitState.bRemovedFromPlay)
	{
		class'WaveCOM_UIArmory_FieldLoadout'.static.UpdateUnit(UnitRef.ObjectID, false);
	}
	`log("~~~Refersh complete for" @ UnitRef.ObjectID @ UnitState.GetFullName(),, 'WaveCOM');
}

function BeginPreparationRound()
{
	local XComGameState NewGameState;
	local WaveCOM_MissionLogic_WaveCOM NewMissionState;
	local XComGameState_BlackMarket BlackMarket;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech InspiredTechState, BreakthroughTechState;
	local XComGameState_BattleData BattleData;

	CollectLootToHQ();
	`log("BeginPreparationRound :: Loot Collected",, 'WaveCOM');

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Collect Wave Loot during Preparation");
	NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', ObjectID));
	NewMissionState.CombatStartCountdown = 3;
	NewMissionState.WaveStatus = eWaveStatus_Preparation;

	BlackMarket = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	BlackMarket = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarket.ObjectID));
	BlackMarket.ResetBlackMarketGoods(NewGameState);
	`log("BeginPreparationRound :: Black Market Reseted",, 'WaveCOM');

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));


	// Remove Inspire Techs
	if (XComHQ.CurrentInspiredTech.ObjectID != 0)
	{
		InspiredTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', XComHQ.CurrentInspiredTech.ObjectID));
		InspiredTechState.bInspired = false;
		XComHQ.CurrentInspiredTech.ObjectID = 0;
	}
	XComHQ.InspiredTechTimer = XComHQ.GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddTime(XComHQ.BreakthroughTechTimer, 99999);

	// Reset Breakthroughs by generating a new one
	if (XComHQ.CurrentBreakthroughTech.ObjectID != 0)
	{
		BreakthroughTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', XComHQ.CurrentBreakthroughTech.ObjectID));
		BreakthroughTechState.bBreakthrough = false;
		`log("BeginPreparationRound :: Deleted Breakthrough",, 'WaveCOM');
		XComHQ.CurrentBreakthroughTech.ObjectID = 0;
	}
	
	XComHQ.BreakthroughTechTimer = XComHQ.GetCurrentTime(); // FORCE BREAKTHROUGH!
	class'X2StrategyGameRulesetDataStructures'.static.AddTime(XComHQ.BreakthroughTechTimer, -10);
	XComHQ.IgnoredBreakthroughTechs.Length = 0;
	XComHQ.CheckForBreakthroughTechs(NewGameState);
	`log("BeginPreparationRound :: Added Breakthrough" @ XComHQ.CurrentBreakthroughTech.ObjectID,, 'WaveCOM');

	// Clear sitreps and roll for new ones.
	RollForSitReps(NewGameState);

	`XEVENTMGR.TriggerEvent('WaveCOM_WaveEnd',,, NewGameState);

	UpdateChosenLevel(NewGameState, GetForceLevel(NewMissionState.WaveNumber + 1));

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BattleData.SetGlobalAbilityEnabled( 'PlaceEvacZone', false);

	//`XCOMHISTORY.ArchiveHistory("Wave" @ NewMissionState.WaveNumber, true);

	UpdateCombatCountdown();
}

static function RollForSitReps(XComGameState NewGameState, optional bool bForceTrigger=false, optional name SitRepName='')
{
	local XComGameState_HeadquartersXCom XComHQ;
	local WaveCOM_MissionLogic_WaveCOM NewMissionState;
	local XComGameState_BattleData BattleData;
	local X2SitRepTemplateManager SitRepManager;
	local RollForSitRep SitRepInfo;
	local X2SitRepTemplate SitRepTemplate;
	local array<RollForSitRep> ValidSitReps;
	local int MaxWeighting, idx, Weighting, GameStateID;
	local name TacticalTag;
	local bool bShouldSubmitState;

	if (NewGameState == none)
	{
		bShouldSubmitState = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rolling for sitreps");
	}
	else
	{
		bShouldSubmitState = false;
	}

	NewMissionState = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'WaveCOM_MissionLogic_WaveCOM'));
	if (NewMissionState == none)
	{
		// Call from wrong context, KILL
		if (bShouldSubmitState)
		{
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
		return;
	}
	else
	{
		GameStateID = NewMissionState.ObjectID;
		NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.GetGameStateForObjectID(GameStateID));
	}
	if (NewMissionState == none)
	{
		NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', GameStateID));
	}

	if (NewMissionState.WaveStatus != eWaveStatus_Preparation)
	{
		// Bad Wave status to call this
		if (bShouldSubmitState)
		{
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
		return;
	}

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	GameStateID = XComHQ.ObjectID;
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(GameStateID));
	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', GameStateID));
	}

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	GameStateID = BattleData.ObjectID;
	BattleData = XComGameState_BattleData(NewGameState.GetGameStateForObjectID(GameStateID));
	if (BattleData == none)
	{
		BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', GameStateID));
	}

	SitRepManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();
	XComHQ.TacticalGameplayTags.Length = 0;
	while (NewMissionState.ActiveSitReps.Length > 0)
	{
		if (BattleData.ActiveSitReps.Find(NewMissionState.ActiveSitReps[0]) != INDEX_NONE)
		{
			BattleData.ActiveSitReps.RemoveItem(NewMissionState.ActiveSitReps[0]);
		}
		NewMissionState.ActiveSitReps.Remove(0, 1);
	}

	foreach default.SitRepGenerateData(SitRepInfo)
	{
		SitRepTemplate = SitRepManager.FindSitRepTemplate(SitRepInfo.SitRepTemplateName);
		if ( SitRepTemplate != none && 
			(SitRepTemplate.MinimumForceLevel == 0 || SitRepTemplate.MinimumForceLevel <= GetForceLevel(NewMissionState.WaveNumber + 1)) &&
			(SitRepTemplate.MaximumForceLevel == 0 || SitRepTemplate.MaximumForceLevel >= GetForceLevel(NewMissionState.WaveNumber + 1)) &&
			(SitRepName == '' || SitRepInfo.SitRepTemplateName == SitRepName) )
		{
			ValidSitReps.AddItem(SitRepInfo);
			MaxWeighting += SitRepInfo.Weight;
			`log("SitRep" @ SitRepInfo.SitRepTemplateName @ "is valid",, 'WaveCOM');
		}
	}

	if ( (ValidSitReps.Length > 0) && ( (Rand(100) < GetSitRepChance(NewMissionState.WaveNumber + 1)) || bForceTrigger ) )
	{
		idx = -1;
		Weighting = Rand(MaxWeighting);
		while (Weighting >= 0 && ValidSitReps.Length > idx + 1)
		{
			Weighting -= ValidSitReps[++idx].Weight;
		}
		SitRepTemplate = SitRepManager.FindSitRepTemplate(ValidSitReps[idx].SitRepTemplateName);
		foreach SitRepTemplate.TacticalGameplayTags(TacticalTag)
		{
			XComHQ.TacticalGameplayTags.AddItem(TacticalTag);
		}
		NewMissionState.ActiveSitReps.AddItem(ValidSitReps[idx].SitRepTemplateName);
		BattleData.ActiveSitReps.AddItem(ValidSitReps[idx].SitRepTemplateName);
	}

	if (bShouldSubmitState)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function UpdateChosenLevel(XComGameState NewGameState, int ForceLevel)
{
	local XComGameState_AdventChosen ChosenState;
	local int idx;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		for(idx = 0; idx < class'X2StrategyElement_XpackChosenActions'.default.ChosenLevelUpForceLevels.Length; idx++)
		{
			if(ChosenState.Level == idx && ForceLevel >= class'X2StrategyElement_XpackChosenActions'.default.ChosenLevelUpForceLevels[idx])
			{
				ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenState.ObjectID));
				ChosenState.Level++;
				ChosenState.GainNewStrengths(NewGameState, class'XComGameState_AdventChosen'.default.NumStrengthsPerLevel);
				break; // 1 level up per wave end
			}
		}
	}
}

defaultproperties
{
	WaveStatus = eWaveStatus_Preparation
	CombatStartCountdown = 3
	WaveNumber = 0
}
