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

var int OldSupply;

struct WaveEncounter {
	var name EncounterID;
	var int Earliest;
	var int Latest;
	var int Weighting;

	structdefaultproperties
	{
		Earliest = 0
		Latest = 1000
		Weighting = 1
	}
};

var const config int WaveCOMKillSupplyBonusBase;
var const config float WaveCOMKillSupplyBonusMultiplier;
var const config int WaveCOMWaveSupplyBonusBase;
var const config float WaveCOMWaveSupplyBonusMultiplier;
var const config int WaveCOMIntelBonusBase;
var const config float WaveCOMKillIntelBonusBase;
var const config int WaveCOMPassiveXPPerKill;
var const config array<int> WaveCOMPodCount;
var const config array<int> WaveCOMForceLevel;
var const config array<WaveEncounter> WaveEncounters;
var const config array<name> LostWaves;

delegate EventListenerReturn OnEventDelegate(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData);

function EventListenerReturn RemoveExcessUnits(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local StateObjectReference AbilityReference, ItemReference, BlankReference;
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
				foreach UnitState.Abilities(AbilityReference)
				{
					NewGameState.RemoveStateObject(AbilityReference.ObjectID);
				}
				UnitState.Abilities.Length = 0;
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
				class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState, EffectContext);
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
			}
		}
	}

	this = self;

	`XEVENTMGR.UnRegisterFromEvent(this, 'HACK_RemoveExcessSoldiers');

	return ELR_NoInterrupt;
}

function SetupMissionStartState(XComGameState StartState)
{
	local XComGameState_BlackMarket BlackMarket;
	local Object ThisObj;

	`log("WaveCOM :: Setting Up State - Refresh Black Market and Remove extra units");
	
	BlackMarket = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	BlackMarket = XComGameState_BlackMarket(StartState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarket.ObjectID));
	BlackMarket.ResetBlackMarketGoods(StartState);

	UpdateCombatCountdown(StartState);

	class'X2DownloadableContentInfo_WOTCWaveCOM'.static.FixGroupSpawn(); // TEMP FIX FOR TACTICAL TRANSFER CAUSING NO ACTIONS

	ThisObj = self;

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
	if (WaveStatus == eWaveStatus_Preparation)
	{
		if (NewGameState != none)
			ModifyMissionTimerInState(true, CombatStartCountdown, "Prepare", "Next Wave in", Bad_Red, NewGameState);
		else
			ModifyMissionTimer(true, CombatStartCountdown, "Prepare", "Next Wave in", Bad_Red);
	}
	else
	{
		if (NewGameState != none)
			ModifyMissionTimerInState(true, WaveNumber, "Wave Number", "In Progress",, NewGameState); // hide timer
		else
			ModifyMissionTimer(true, WaveNumber, "Wave Number", "In Progress"); // hide timer
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

	if (WaveStatus == eWaveStatus_Preparation)
	{
		CombatStartCountdown = CombatStartCountdown - 1;
		`log("WaveCOM :: Counting Down - " @ CombatStartCountdown);

		History = `XCOMHISTORY;
	
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Collect Wave Loot during Preparation");
		NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', ObjectID));
		NewMissionState.CombatStartCountdown = CombatStartCountdown;
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

		if (CombatStartCountdown == 0)
		{
			InitiateWave();
		}

		class'X2DownloadableContentInfo_WOTCWaveCOM'.static.FixGroupSpawn(); // TEMP FIX FOR TACTICAL TRANSFER CAUSING NO ACTIONS
	}

	UpdateCombatCountdown();
	return ELR_NoInterrupt;
}

function InitiateWave()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState NewGameState;
	local WaveCOM_MissionLogic_WaveCOM NewMissionState;
	local array<WaveEncounter> WeightedStack;
	local WaveEncounter Encounter;
	local int Pods, Weighting, ForceLevel;
	local Vector ObjectiveLocation;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Force Level");

	WaveStatus = eWaveStatus_Combat;
	WaveNumber = WaveNumber + 1;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ObjectiveLocation = BattleData.MapData.ObjectiveLocation;
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	if (WaveNumber > WaveCOMForceLevel.Length - 1)
	{
		ForceLevel = WaveCOMForceLevel[WaveCOMForceLevel.Length - 1];
	}
	else
	{
		ForceLevel = WaveCOMForceLevel[WaveNumber];
	}
	ForceLevel = Clamp(ForceLevel, 1, 20);

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	AlienHQ.ForceLevel = ForceLevel;

	BattleData.SetForceLevel(ForceLevel);
	`SPAWNMGR.ForceLevel = ForceLevel;

	NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', ObjectID));
	NewMissionState.WaveStatus = WaveStatus;
	NewMissionState.WaveNumber = WaveNumber;
	
	if (WaveNumber > WaveCOMPodCount.Length - 1)
	{
		Pods = WaveCOMPodCount[WaveCOMPodCount.Length - 1];
	}
	else
	{
		Pods = WaveCOMPodCount[WaveNumber];
	}

	foreach WaveEncounters(Encounter)
	{
		if (Encounter.Earliest <= WaveNumber && Encounter.Latest >= WaveNumber && Encounter.Weighting > 0)
		{
			Weighting = Encounter.Weighting;
			while (Weighting > 0 )
			{
				WeightedStack.AddItem(Encounter);
				--Weighting;
			}
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	while (Pods > 0 )
	{
		Encounter = WeightedStack[Rand(WeightedStack.Length)];
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

function HandleTeamDead(XGPlayer LosingPlayer)
{
	if (LosingPlayer.m_eTeam == eTeam_Alien)
	{
		BeginPreparationRound();
	}
	else if (LosingPlayer.m_eTeam == eTeam_XCom)
	{
		`TACTICALRULES.EndBattle(LosingPlayer, eUICombatLose_UnfailableGeneric, false);
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

	Context = VisualizeGameState.GetContext();

	OldHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	OldHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetGameStateForObjectID(OldHQ.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	XComHQ = XComGameState_HeadquartersXCom(VisualizeGameState.GetGameStateForObjectID(OldHQ.ObjectID));

	ActionMetadata = EmptyMetadata;
	ActionMetadata.StateObject_OldState = OldHQ;
	ActionMetadata.StateObject_NewState = XComHQ;

	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	UIUpdateAction.UpdateType = EUIUT_SetHUDVisibility;
	UIUpdateAction.DesiredHUDVisibility.bMessageBanner = true;

	BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	BannerAction.BannerText = "WAVE" @ WaveNumber @ "COMPLETE!";
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
	local int LootIndex, SupplyReward, IntelReward, KillCount;
	local X2ItemTemplateManager ItemTemplateManager;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> ItemStates;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> BondingSoldiers;

	local LootResults PendingAutoLoot;
	local Name LootTemplateName;
	local array<Name> RolledLoot;

	History = `XCOMHISTORY;
	
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

		if( UnitState.IsAdvent() || UnitState.IsAlien() )
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
						FloatingIntel += WaveCOMKillIntelBonusBase;
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

	SupplyReward = SupplyReward + WaveCOMWaveSupplyBonusBase;
	SupplyReward = SupplyReward + Round(WaveNumber * WaveCOMWaveSupplyBonusMultiplier);

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
		}
	}
}

static function FullRefreshSoldier(StateObjectReference UnitRef)
{
	local XComGameState NewGameState;
	local WaveCOMGameStateContext_UpdateUnit EffectContext;
	local XGUnit Visualizer;
	local XComPerkContentShared hPawnPerk;
	local XComGameState_Unit UnitState;
	local StateObjectReference AbilityReference;
	local XComGameState_HeadquartersXCom XComHQ;
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	EffectContext = class'WaveCOMGameStateContext_UpdateUnit'.static.CreateChangeStateUU("Clean Unit State", UnitState);
	NewGameState = EffectContext.GetGameState();
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	`log("~~~Cleaning and readding Abilities for" @ UnitRef.ObjectID @ UnitState.GetFullName(),, 'WaveCOM');
	foreach UnitState.Abilities(AbilityReference)
	{
		NewGameState.RemoveStateObject(AbilityReference.ObjectID);
	}
	UnitState.Abilities.Length = 0;
	Visualizer = XGUnit(UnitState.FindOrCreateVisualizer());
	foreach Visualizer.GetPawn().arrTargetingPerkContent(hPawnPerk)
	{
		hPawnPerk.RemovePerkTarget( XGUnit(Visualizer.GetPawn().m_kGameUnit) );
	}
	Visualizer.GetPawn().StopPersistentPawnPerkFX(); // Remove all abilities visualizers

	class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState, EffectContext);
	class'WaveCOM_UIArmory_FieldLoadout'.static.RefillInventory(NewGameState, UnitState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("~Cleanup complete, commencing refresh for" @ UnitRef.ObjectID @ UnitState.GetFullName(),, 'WaveCOM');
	UnitRef = UnitState.GetReference();
	if (UnitState.IsAlive() && XComHQ.Squad.Find('ObjectID', UnitRef.ObjectID) != INDEX_NONE && !UnitState.bRemovedFromPlay)
	{
		class'WaveCOM_UIArmory_FieldLoadout'.static.UpdateUnit(UnitRef.ObjectID);
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

	WaveStatus = eWaveStatus_Preparation;
	CombatStartCountdown = 3;
	CollectLootToHQ();
	`log("BeginPreparationRound :: Loot COllected",, 'WaveCOM');

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Collect Wave Loot during Preparation");
	NewMissionState = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', ObjectID));
	NewMissionState.CombatStartCountdown = CombatStartCountdown;
	NewMissionState.WaveStatus = WaveStatus;

	BlackMarket = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	BlackMarket = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarket.ObjectID));
	BlackMarket.ResetBlackMarketGoods(NewGameState);
	`log("BeginPreparationRound :: Black Market Reseted",, 'WaveCOM');
	
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

	`XEVENTMGR.TriggerEvent('WaveCOM_WaveEnd',,, NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	//`XCOMHISTORY.ArchiveHistory("Wave" @ NewMissionState.WaveNumber);

	UpdateCombatCountdown();
}

defaultproperties
{
	WaveStatus = eWaveStatus_Preparation
	CombatStartCountdown = 3
	WaveNumber = 0
}