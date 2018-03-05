//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo.uc
//  AUTHOR:  Ryan McFall
//           
//	Mods and DLC derive from this class to define their behavior with respect to 
//  certain in-game activities like loading a saved game. Should the DLC be installed
//  to a campaign that was already started?
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTCWaveCOM extends X2DownloadableContentInfo dependson(X2EventManager, WaveCOM_UIChooseResearch);

var const config(WaveCOM) float WaveCOMResearchSupplyCostRatio;
var const config(WaveCOM) float WaveCOMBreakthroughMultiplier;
var config(WaveCOM) int InspireResearchCostDiscount;
var config(WaveCOM) array<name> NonUpgradeSchematics;
var config(WaveCOM) array<name> ObsoleteOTSUpgrades;
var config(WaveCOM) array<name> ObsoleteBreakthroughs;
var config(WaveCOM) array<name> CantSellResource;

var config(WaveCOM) array<DynamicUpgradeData> RepeatableUpgradeCosts;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	local XComMissionLogic_Listener MissionListener;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Loading Save Game Mission Logic Loader");
	MissionListener = XComMissionLogic_Listener(NewGameState.CreateNewStateObject(class'XComMissionLogic_Listener'));
	MissionListener.RegisterToListen();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("XComMissionLogic :: OnLoadedSavedGame");
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	local XComMissionLogic_Listener MissionListener;
	MissionListener = XComMissionLogic_Listener(StartState.CreateNewStateObject(class'XComMissionLogic_Listener'));
	MissionListener.RegisterToListen();

	`log("XComMissionLogic :: InstallNewCampaign",, 'WaveCOM');

	MakeAllTechInstant(StartState);
}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// Allows dlcs/mods to modify the start state before launching into the mission
/// </summary>
static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{

}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{

}

/// <summary>
/// Called when the player is doing a direct tactical->tactical mission transfer. Allows mods to modify the
/// start state of the new transfer mission if needed
/// </summary>
static event ModifyTacticalTransferStartState(XComGameState TransferStartState)
{
	local WaveCOM_MissionLogic_WaveCOM WaveLogic, MissionLogic;
	local XComGameState_BaseObject RemoveState;
	local XComGameState_LootDrop LootState;
	local int WaveID;
	`log("=*=*=*=*=*=*= Tactical Transfer code executed successfully! =*=*=*=*=*=*=",, 'WaveCOM');
	`log("Start state size" @ TransferStartState.GetNumGameStateObjects(),, 'WaveCOM');

	WaveLogic = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'WaveCOM_MissionLogic_WaveCOM'));
	if (WaveLogic != none)
	{
		WaveID = WaveLogic.ObjectID;
		MissionLogic = WaveCOM_MissionLogic_WaveCOM(TransferStartState.GetGameStateForObjectID(WaveLogic.ObjectID));
		if (MissionLogic == none)
		{
			`log("Mission Logic not transferred, forcing one",, 'WaveCOM');
			MissionLogic = WaveCOM_MissionLogic_WaveCOM(TransferStartState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', WaveID));
		}
		MissionLogic.bIsBeingTransferred = true;
		// Reset to pre wave start
		MissionLogic.WaveStatus = eWaveStatus_Preparation;
		MissionLogic.CombatStartCountdown = 3;
		MissionLogic.UnregisterAllObservers();
	}
	else
	{
		foreach TransferStartState.IterateByClassType(class'WaveCOM_MissionLogic_WaveCOM', WaveLogic)
		{
			`log("Found transfering mission logic, turning on Being transferred flag",, 'WaveCOM');
			MissionLogic.bIsBeingTransferred = true;
			// Reset to pre wave start
			MissionLogic.WaveStatus = eWaveStatus_Preparation;
			MissionLogic.CombatStartCountdown = 3;
			MissionLogic.UnregisterAllObservers();
		}
	}
	RemoveState = `XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true);
	if (RemoveState != none)
	{
		// We will make a new UI Timer next round
		TransferStartState.RemoveStateObject(RemoveState.ObjectID);
	}
	foreach TransferStartState.IterateByClassType(class'XComGameState_LootDrop', LootState)
	{
		// We don't carry loot drops over
		TransferStartState.RemoveStateObject(LootState.ObjectID);
	}
}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{

}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	`log("WaveCOM :: Present And Correct",, 'WaveCOM');
	PatchOutUselessOTS();
	PatchOutUselessBreakthroughs();
	MakeEleriumAlloyUnsellable();
	AddContinentsToOTS();
	PatchBlackMarketSoldierReward();
	UpdateSchematicTemplates();
	UpdateResearchTemplates();
}

static function MakeEleriumAlloyUnsellable()
{
	local X2ItemTemplate ItemTemplate;
	local X2DataTemplate Template;
	local array<X2DataTemplate> ItemTemplates;
	local name ResName;
	
	foreach default.CantSellResource(ResName)
	{
		class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindDataTemplateAllDifficulties(ResName, ItemTemplates);
		foreach ItemTemplates(Template)
		{
			ItemTemplate = X2ItemTemplate(Template);
			if (ItemTemplate != none)
			{
				ItemTemplate.TradingPostValue = 0;
			}
		}
	}
}

static function PatchOutUselessOTS()
{
	local X2FacilityTemplate FacilityTemplate;
	local X2DataTemplate Template;
	local array<X2DataTemplate> FacilityTemplates;
	local name OTSName;

	class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindDataTemplateAllDifficulties('OfficerTrainingSchool', FacilityTemplates);
	foreach FacilityTemplates(Template)
	{
		FacilityTemplate = X2FacilityTemplate(Template);
		if (FacilityTemplate != none)
		{
			foreach default.ObsoleteOTSUpgrades(OTSName)
			{
				FacilityTemplate.SoldierUnlockTemplates.RemoveItem(OTSName);
			}
		}
	}
}

static function PatchOutUselessBreakthroughs()
{
	local X2StrategyElementTemplateManager Manager;
	local X2TechTemplate Tech;
	local array<X2DataTemplate> AllTemplates;
	local X2DataTemplate Template;
	local name TempalateName;

	Manager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	foreach default.ObsoleteBreakthroughs(TempalateName)
	{
		Manager.FindDataTemplateAllDifficulties(TempalateName, AllTemplates);
		foreach AllTemplates(Template)
		{
			Tech = X2TechTemplate(Template);
			if (Tech != none)
			{
				Tech.Requirements.SpecialRequirementsFn = BreakthroughDisabled;
			}
		}
	}
}


static function bool BreakthroughDisabled()
{
	return false;
}

static function AddContinentsToOTS()
{
	local X2FacilityTemplate FacilityTemplate;
	local X2DataTemplate Template;
	local array<X2DataTemplate> FacilityTemplates;

	class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindDataTemplateAllDifficulties('OfficerTrainingSchool', FacilityTemplates);
	foreach FacilityTemplates(Template)
	{
		FacilityTemplate = X2FacilityTemplate(Template);
		if (FacilityTemplate != none)
		{
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_QuidUnlock');
			// Re-add old GTS upgrades that were turned into resistance cards, since in WaveCOM you jsut buy those
			FacilityTemplate.SoldierUnlockTemplates.AddItem('VultureUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('StayWithMeUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('VengeanceUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('IntegratedWarfareUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_LiveFireUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_BetweenTheEyesUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_WeakPointsUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_InsiderKnowledgeUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_InformationWarUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_TrialByFireUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_ArtOfWarUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_MentalFortitudeUnlock');
			FacilityTemplate.SoldierUnlockTemplates.AddItem('WaveCOM_FeedbackUnlock');
		}
	}
}

static function PatchBlackMarketSoldierReward()
{
	local X2RewardTemplate RewardTemplate;
	RewardTemplate = X2RewardTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('Reward_Soldier'));
	RewardTemplate.GiveRewardFn = GivePersonnelReward;
}

static function GivePersonnelReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;	
	local XComGameState_Unit UnitState;

	local TDialogueBoxData  kDialogData;

	History = `XCOMHISTORY;	

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	if(UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RewardState.RewardObjectReference.ObjectID));
	}
		
	`assert(UnitState != none);

	if(UnitState.GetMyTemplate().bIsSoldier)
	{
		UnitState.ApplyBestGearLoadout(NewGameState);
	}

	XComHQ.AddToCrew(NewGameState, UnitState);

	XComHQ.Squad.AddItem(UnitState.GetReference());

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = "Purchased black market unit";
	kDialogData.strText = "Click the deploy soldier button to spawn the purchased unit";

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

	`PRES.UIRaiseDialog(kDialogData);

	`XEVENTMGR.TriggerEvent('UpdateDeployCost');
}

static function MakeAllTechInstant(XComGameState StartState)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		TechState = XComGameState_Tech(StartState.ModifyStateObject(class'XComGameState_Tech', TechState.ObjectID));
		TechState.bForceInstant = true;
		TechState.bSeenInstantPopup = true;
	}
}

static function AddSupplyCost(out array<ArtifactCost> Resources, int SupplyDiff)
{
	local ArtifactCost Resource, NewResource;

	NewResource.ItemTemplateName = 'Supplies';

	foreach Resources(Resource)
	{
		if (Resource.ItemTemplateName == 'Supplies')
		{
			NewResource.Quantity = Resource.Quantity;
			Resources.RemoveItem(Resource);
			break;
		}
	}

	NewResource.Quantity += SupplyDiff;
	Resources.AddItem(NewResource);
}

static function UpdateResearchTemplates()
{
	local X2StrategyElementTemplateManager Manager;
	local array<X2StrategyElementTemplate> Techs;
	local X2StrategyElementTemplate TechTemplate;
	local X2TechTemplate Tech;
	local X2DataTemplate Template;
	local array<X2DataTemplate> Templates;

	Manager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	Techs = Manager.GetAllTemplatesOfClass(class'X2TechTemplate');

	foreach Techs(TechTemplate)
	{
		Manager.FindDataTemplateAllDifficulties(TechTemplate.DataName, Templates);

		foreach Templates(Template)
		{
			Tech = X2TechTemplate(Template);
			if (Tech != none)
			{
				if (Tech.bBreakthrough)
				{
					Tech.Requirements.bVisibleIfItemsNotMet = true;
				}
				Tech.bJumpToLabs = false;
			}
		}
	}
}

static function UpdateSchematicTemplates()
{
	local X2ItemTemplateManager Manager;
	local array<X2SchematicTemplate> Schematics;
	local X2SchematicTemplate Schematic;

	Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	Schematics = Manager.GetAllSchematicTemplates();
	foreach Schematics(Schematic)
	{
		if (default.NonUpgradeSchematics.Find(Schematic.DataName) == INDEX_NONE)
		{
			`log("Updating: " @Schematic.DataName,, 'WaveCOM');
			Schematic.OnBuiltFn = UpgradeItems;

			Manager.AddItemTemplate(Schematic, true);
		}
		else
		{
			`log("Skipping schematic: " @Schematic.DataName,, 'WaveCOM');
		}
	}
}

static function UpgradeItems(XComGameState NewGameState, XComGameState_Item ItemState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate BaseItemTemplate, UpgradeItemTemplate;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local XComGameState_Item InventoryItemState, BaseItemState, UpgradedItemState;
	local XComGameState_Unit CosmeticUnit, SoldierState;
	local array<X2ItemTemplate> CreatedItems, ItemsToUpgrade;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local array<XComGameState_Item> InventoryItems;
	local array<XComGameState_Unit> Soldiers;
	local EInventorySlot InventorySlot;
	local XGItem ItemVisualizer;
	local int idx, iSoldier, iItems;
	local name CreatorTemplateName;

	CreatorTemplateName = ItemState.GetMyTemplateName();

	History = `XCOMHISTORY;
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	CreatedItems = ItemTemplateManager.GetAllItemsCreatedByTemplate(CreatorTemplateName);

	for (idx = 0; idx < CreatedItems.Length; idx++)
	{
		UpgradeItemTemplate = CreatedItems[idx];

		ItemsToUpgrade.Length = 0; // Reset ItemsToUpgrade for this upgrade item iteration
		GetItemsToUpgrade(UpgradeItemTemplate, ItemsToUpgrade);

		// If the new item is infinite, just add it directly to the inventory
		if (UpgradeItemTemplate.bInfiniteItem)
		{
			// But only add the infinite item if it isn't already in the inventory
			if (!XComHQ.HasItem(UpgradeItemTemplate))
			{
				UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
				XComHQ.AddItemToHQInventory(UpgradedItemState);
			}
		}
		else
		{
			// Otherwise cycle through each of the base item templates
			foreach ItemsToUpgrade(BaseItemTemplate)
			{
				// Check if the base item is in the XComHQ inventory
				BaseItemState = XComHQ.GetItemByName(BaseItemTemplate.DataName);

				// If it is not, we have nothing to replace, so move on
				if (BaseItemState != none)
				{
					// Otherwise match the base items quantity
					UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
					UpgradedItemState.Quantity = BaseItemState.Quantity;

					// Then add the upgrade item and remove all of the base items from the inventory
					XComHQ.PutItemInInventory(NewGameState, UpgradedItemState);
					XComHQ.RemoveItemFromInventory(NewGameState, BaseItemState.GetReference(), BaseItemState.Quantity);
					
					NewGameState.RemoveStateObject(BaseItemState.GetReference().ObjectID);
				}
			}
		}

		// Check the inventory for any unequipped items with weapon upgrades attached, make sure they get updated
		for (iItems = 0; iItems < XComHQ.Inventory.Length; iItems++)
		{
			InventoryItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[iItems].ObjectID));
			foreach ItemsToUpgrade(BaseItemTemplate)
			{
				if (InventoryItemState.GetMyTemplateName() == BaseItemTemplate.DataName && InventoryItemState.GetMyWeaponUpgradeTemplates().Length > 0)
				{
					UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
					UpgradedItemState.WeaponAppearance = InventoryItemState.WeaponAppearance;
					UpgradedItemState.Nickname = InventoryItemState.Nickname;

					// Transfer over all weapon upgrades to the new item
					WeaponUpgrades = InventoryItemState.GetMyWeaponUpgradeTemplates();
					foreach WeaponUpgrades(WeaponUpgradeTemplate)
					{
						UpgradedItemState.ApplyWeaponUpgradeTemplate(WeaponUpgradeTemplate);
					}

					// Delete the old item, and add the new item to the inventory
					NewGameState.RemoveStateObject(InventoryItemState.GetReference().ObjectID);
					XComHQ.Inventory.RemoveItem(InventoryItemState.GetReference());
					XComHQ.PutItemInInventory(NewGameState, UpgradedItemState);
				}
			}
		}

		// Then check every soldier's inventory and replace the old item with a new one
		Soldiers = XComHQ.GetSoldiers();
		for (iSoldier = 0; iSoldier < Soldiers.Length; iSoldier++)
		{
			InventoryItems = Soldiers[iSoldier].GetAllInventoryItems(NewGameState, false);

			foreach InventoryItems(InventoryItemState)
			{
				foreach ItemsToUpgrade(BaseItemTemplate)
				{
					if (InventoryItemState.GetMyTemplateName() == BaseItemTemplate.DataName)
					{
						UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
						UpgradedItemState.WeaponAppearance = InventoryItemState.WeaponAppearance;
						UpgradedItemState.Nickname = InventoryItemState.Nickname;
						InventorySlot = InventoryItemState.InventorySlot; // save the slot location for the new item

						// Remove the old item from the soldier and transfer over all weapon upgrades to the new item
						SoldierState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[iSoldier].ObjectID));
						SoldierState.RemoveItemFromInventory(InventoryItemState, NewGameState);
						ItemVisualizer = XGItem(`XCOMHISTORY.GetVisualizer(InventoryItemState.GetReference().ObjectID));
						if (ItemVisualizer != none)
						{
							ItemVisualizer.Destroy();
							`XCOMHISTORY.SetVisualizer(InventoryItemState.GetReference().ObjectID, none);
						}
						WeaponUpgrades = InventoryItemState.GetMyWeaponUpgradeTemplates();
						foreach WeaponUpgrades(WeaponUpgradeTemplate)
						{
							UpgradedItemState.ApplyWeaponUpgradeTemplate(WeaponUpgradeTemplate);
						}
						
						if( InventoryItemState.CosmeticUnitRef.ObjectID > 0 )
						{
							CosmeticUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InventoryItemState.CosmeticUnitRef.ObjectID));;
							CosmeticUnit.RemoveUnitFromPlay();
							class'WaveCOM_UIArmory_FieldLoadout'.static.UnRegisterForCosmeticUnitEvents(InventoryItemState, InventoryItemState.CosmeticUnitRef);
						}

						// Delete the old item
						NewGameState.RemoveStateObject(InventoryItemState.GetReference().ObjectID);

						// Then add the new item to the soldier in the same slot
						SoldierState.AddItemToInventory(UpgradedItemState, InventorySlot, NewGameState);
					}
				}
			}
		}

		// Remove narratives to prevent problems
		
		`XEVENTMGR.TriggerEvent('RequestRefreshAllUnits', , , NewGameState);
	}
}

// Recursively calculates the list of items to upgrade based on the final upgraded item template
private static function GetItemsToUpgrade(X2ItemTemplate UpgradeItemTemplate, out array<X2ItemTemplate> ItemsToUpgrade)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate BaseItemTemplate, AdditionalBaseItemTemplate;
	local array<X2ItemTemplate> BaseItems;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Search for any base items which specify this item as their upgrade. This accounts for the old version of schematics, mainly for Day 0 DLC
	BaseItems = ItemTemplateManager.GetAllBaseItemTemplatesFromUpgrade(UpgradeItemTemplate.DataName);
	foreach BaseItems(AdditionalBaseItemTemplate)
	{
		if (ItemsToUpgrade.Find(AdditionalBaseItemTemplate) == INDEX_NONE)
		{
			ItemsToUpgrade.AddItem(AdditionalBaseItemTemplate);
		}
	}
	
	// If the base item was also the result of an upgrade, we need to save that base item as well to ensure the entire chain is upgraded
	BaseItemTemplate = ItemTemplateManager.FindItemTemplate(UpgradeItemTemplate.BaseItem);
	if (BaseItemTemplate != none)
	{
		ItemsToUpgrade.AddItem(BaseItemTemplate);
		GetItemsToUpgrade(BaseItemTemplate, ItemsToUpgrade);
	}
}

/// <summary>
/// Called when the difficulty changes and this DLC is active
/// </summary>
static event OnDifficultyChanged()
{

}

/// <summary>
/// Called by the Geoscape tick
/// </summary>
static event UpdateDLC()
{

}

/// <summary>
/// Called after HeadquartersAlien builds a Facility
/// </summary>
static event OnPostAlienFacilityCreated(XComGameState NewGameState, StateObjectReference MissionRef)
{

}

/// <summary>
/// Called after a new Alien Facility's doom generation display is completed
/// </summary>
static event OnPostFacilityDoomVisualization()
{

}

/// <summary>
/// Called when viewing mission blades with the Shadow Chamber panel, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool UpdateShadowChamberMissionInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// A dialogue popup used for players to confirm or deny whether new gameplay content should be installed for this DLC / Mod.
/// </summary>
static function EnableDLCContentPopup()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = default.EnableContentLabel;
	kDialogData.strText = default.EnableContentSummary;
	kDialogData.strAccept = default.EnableContentAcceptLabel;
	kDialogData.strCancel = default.EnableContentCancelLabel;

	kDialogData.fnCallback = EnableDLCContentPopupCallback_Ex;
	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated function EnableDLCContentPopupCallback(eUIAction eAction)
{
}

simulated function EnableDLCContentPopupCallback_Ex(Name eAction)
{	
	switch (eAction)
	{
	case 'eUIAction_Accept':
		EnableDLCContentPopupCallback(eUIAction_Accept);
		break;
	case 'eUIAction_Cancel':
		EnableDLCContentPopupCallback(eUIAction_Cancel);
		break;
	case 'eUIAction_Closed':
		EnableDLCContentPopupCallback(eUIAction_Closed);
		break;
	}
}

/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool ShouldUpdateMissionSpawningInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool UpdateMissionSpawningInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// Called when viewing mission blades, used to add any additional text to the mission description
/// </summary>
static function string GetAdditionalMissionDesc(StateObjectReference MissionRef)
{
	return "";
}

/// <summary>
/// Called from X2AbilityTag:ExpandHandler after processing the base game tags. Return true (and fill OutString correctly)
/// to indicate the tag has been expanded properly and no further processing is needed.
/// </summary>
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	switch (InString)
	{
		case "WEAKPOINTSHRED":
			OutString = string(`ScaleStrategyArrayInt(class'X2StrategyElement_XpackResistanceActions'.default.WeakPointsShred));
			return true;
		case "INFORMATIONWARFAREHACK":
			OutString = string(`ScaleStrategyArrayInt(class'X2StrategyElement_XpackResistanceActions'.default.InformationWarReduction));
			return true;
		case "ARTOFWARPERCENT":
			OutString = string(`ScaleStrategyArrayInt(class'X2StrategyElement_XpackResistanceActions'.default.ArtOfWarBonus));
			return true;
		default:
			break;
	}
	return false;
}

/// <summary>
/// Called from XComGameState_Unit:GatherUnitAbilitiesForInit after the game has built what it believes is the full list of
/// abilities for the unit based on character, class, equipment, et cetera. You can add or remove abilities in SetupData.
/// </summary>
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{

}

/// <summary>
/// Calls DLC specific popup handlers to route messages to correct display functions
/// </summary>
static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{

}



exec function AddItemWaveCom(string strItemTemplate, optional int Quantity = 1, optional bool bLoot = false)
{
	local X2ItemTemplateManager ItemManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersXCom HQState;
	local XComGameStateHistory History;

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemManager.FindItemTemplate(name(strItemTemplate));
	if (ItemTemplate == none)
	{
		`log("No item template named" @ strItemTemplate @ "was found.");
		return;
	}
	History = `XCOMHISTORY;
	HQState = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	`assert(HQState != none);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Item Cheat: Create Item");
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	if (Quantity > 0)
		ItemState.Quantity = Quantity;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Item Cheat: Complete");
	HQState = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQState.ObjectID));
	HQState.PutItemInInventory(NewGameState, ItemState, bLoot);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("Added item" @ strItemTemplate @ "object id" @ ItemState.ObjectID);
}

exec function RefreshOTS()
{
	local XComGameState_Player XComPlayer;
	local XComGameState_BattleData BattleData;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update OTS Entries");
	
	BattleData = XComGameState_BattleData( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	XComPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(BattleData.PlayerTurnOrder[0].ObjectID));
	XComPlayer = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', XComPlayer.ObjectID));
	XComPlayer.SoldierUnlockTemplates = `XCOMHQ.SoldierUnlockTemplates;
	NewGameState.AddStateObject(XComPlayer);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function StaticWaveCOMMissionTransfer(optional int MapIndex=-1)
{
	local XComPlayerController PlayerController;
	local string MissionType;
	local MissionDefinition MissionDef;
	local array<string> MissionTypes;
	local WaveCOM_MissionLogic_WaveCOM MissionLogic;
	local XComGameState NewGameState;
	local XComMissionLogic_Listener MissionListener;
	local array<StateObjectReference> EmptyList;

	EmptyList.Length = 0;

	MissionLogic = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'WaveCOM_MissionLogic_WaveCOM'));
	if (MissionLogic != none)
	{
		`log("=-=-=-=-=-=-= Preparing to transfer MissionLogic =-=-=-=-=-=-=",, 'WaveCOM');
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Preparing Mission Logic for transfer");
		MissionLogic = WaveCOM_MissionLogic_WaveCOM(NewGameState.ModifyStateObject(class'WaveCOM_MissionLogic_WaveCOM', MissionLogic.ObjectID));
		MissionLogic.bIsBeingTransferred = true;
		// Reset to pre wave start
		MissionLogic.WaveStatus = eWaveStatus_Preparation;
		MissionLogic.CombatStartCountdown = 3;
		MissionLogic.UnregisterAllObservers();
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	foreach class'XComTacticalMissionManager'.default.arrMissions(MissionDef)
	{
		if (MissionDef.MissionFamily == "WaveCOM")
			MissionTypes.AddItem(MissionDef.sType);
	}
	
	if (MapIndex < 0 || MapIndex >= MissionTypes.Length)
	{
		MapIndex = class'Engine'.static.GetEngine().SyncRand(MissionTypes.Length, "WaveCOMTransferMissionRoll");
	}

	MissionType = MissionTypes[MapIndex];

	`log("Transfering to new mission...",, 'WaveCOM');
	PlayerController = XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	`XEVENTMGR.Clear(); // TEST: Clear ALL EVENTS

	`log("XComMissionLogic :: RegisterMissionLogicListener");

	// Re-register MissionLogicListener
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Loading Save Game Mission Logic Loader");
	MissionListener = XComMissionLogic_Listener(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComMissionLogic_Listener'));
	if (MissionListener == none)
		MissionListener = XComMissionLogic_Listener(NewGameState.CreateNewStateObject(class'XComMissionLogic_Listener'));
	else
		MissionListener = XComMissionLogic_Listener(NewGameState.ModifyStateObject(class'XComMissionLogic_Listener', MissionListener.ObjectID));
	MissionListener.RegisterToListen();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	PlayerController.TransferToNewMission(MissionType, EmptyList, EmptyList);
}

exec function WaveCOMTransferToNewMission(optional int MapIndex = -1)
{
	StaticWaveCOMMissionTransfer(MapIndex);
}

exec function DebugMissionLogic()
{
	local WaveCOM_MissionLogic_WaveCOM WaveLogic;
	local TDialogueBoxData  kDialogData;
	local eWaveStatus DebugResult;

	WaveLogic = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'WaveCOM_MissionLogic_WaveCOM'));
	if (WaveLogic != none)
	{
		kDialogData.eType = eDialog_Alert;
		kDialogData.strTitle = "Mission Logic status";
		DebugResult = eWaveStatus(WaveLogic.WaveStatus);
		kDialogData.strText = "Wave:" @ WaveLogic.WaveNumber $ ", status:" @ DebugResult $ ", countdown:" @ WaveLogic.CombatStartCountdown;
		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

		`PRES.UIRaiseDialog(kDialogData);
	}
	else
	{
		kDialogData.eType = eDialog_Alert;
		kDialogData.strTitle = "No mission logic found";
		kDialogData.strText = "Unable to find MissionLogic.";

		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

		`PRES.UIRaiseDialog(kDialogData);
	}
}

exec function RemoveAllUnusedEnemyStateObjects()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local int totalUnitState, totalAliens, removedStates;
	local StateObjectReference AbilityReference, ItemReference;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Spring cleaning");

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		totalUnitState++;
		if (UnitState.GetTeam() == eTeam_Alien)
		{
			totalAliens++;
			if (UnitState.bRemovedFromPlay)
			{
				removedStates++;
				// Remove all abilities
				foreach UnitState.Abilities(AbilityReference)
				{
					if (`XCOMHISTORY.GetGameStateForObjectID(AbilityReference.ObjectID) != none)
					{
						removedStates++;
						NewGameState.RemoveStateObject(AbilityReference.ObjectID);
					}
				}
				// Remove all items
				foreach UnitState.InventoryItems(ItemReference)
				{
					if (XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemReference.ObjectID)) != none &&
						XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemReference.ObjectID)).OwnerStateObject.ObjectID == UnitState.GetReference().ObjectID)
					{
						removedStates++;
						NewGameState.RemoveStateObject(ItemReference.ObjectID);
					}
				}
				NewGameState.RemoveStateObject(UnitState.ObjectID);
			}
		}
	}

	`log(" WaveCOM :: Total unit state:" @ totalUnitState $ ", total aliens:" @ totalAliens $", removed" @ removedStates);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function DebugAllGameStateTypes()
{
	local XComGameState_BaseObject GameState;
	local int totalStates, destructibles, units, items, abilities, effects, loot;
	local TDialogueBoxData  kDialogData;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_BaseObject', GameState)
	{
		totalStates++;
		if (GameState.class == class'XComGameState_Destructible')
			destructibles++;
		if (GameState.class == class'XComGameState_Unit')
			units++;
		if (GameState.class == class'XComGameState_Item')
			items++;
		if (GameState.class == class'XComGameState_Ability')
			abilities++;
		if (GameState.class == class'XComGameState_Effect')
			effects++;
		if (GameState.class == class'XComGameState_LootDrop')
			loot++;
	}

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = "Total number of game states:" @ totalStates;

	kDialogData.strText = "Numbers:\n";
	kDialogData.strText $= "Units:" @ units $ "\n";
	kDialogData.strText $= "Items:" @ items $ "\n";
	kDialogData.strText $= "Abilities:" @ abilities $ "\n";
	kDialogData.strText $= "Effects:" @ effects $ "\n";
	kDialogData.strText $= "Loot drps:" @ loot $ "\n";
	kDialogData.strText $= "Destructibles:" @ destructibles $ "\n";

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

	`PRES.UIRaiseDialog(kDialogData);
}

exec function DebugEvents(optional name EventID='', optional string ObjectName="XComGameState_BaseObject", optional int Mode=0)
{
	local TDialogueBoxData  kDialogData;

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = "Tallying events:";

	if (Mode == 0)
		kDialogData.strText = "Events:" @ `XEVENTMGR.AllEventListenersToString(EventID, ObjectName);
	else
		kDialogData.strText = "Debug:" @ `XEVENTMGR.EventManagerDebugString(EventID, ObjectName);

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

	`PRES.UIRaiseDialog(kDialogData);
}

exec function DumpEvents()
{
	`log(`XEVENTMGR.EventManagerDebugString());
}

exec function PutGameStateInPlay(int ID)
{
	local XComGameState NewGameState;
	local XComGameState_BaseObject IDState;

	IDState = `XCOMHISTORY.GetGameStateForObjectID(ID);
	if (!IDState.IsInPlay())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fixing InPlay status");
		IDState = NewGameState.ModifyStateObject(IDState.class, ID);
		IDState.BeginTacticalPlay(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

exec function GetObjectIDStatus(int ID)
{
	local TDialogueBoxData  kDialogData;
	local XComGameState_BaseObject StateObject;
	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = "Tallying events:";

	StateObject = `XCOMHISTORY.GetGameStateForObjectID(ID);



	if (StateObject == none)
		kDialogData.strText = ID @ "not found.";
	else
	{
		kDialogData.strText = ID @ "found:";
		if (StateObject.bInPlay)
			kDialogData.strText $= "In play. ";
		else
			kDialogData.strText $= "Not in play. ";
		if (StateObject.bRemoved)
			kDialogData.strText $= "Active. ";
		else
			kDialogData.strText $= "Removed. ";
		kDialogData.strText $= "\n" $ StateObject.ToString();
		
	}

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

	`PRES.UIRaiseDialog(kDialogData);

	`log("==========PRINT UNIT INFO==========",, 'WaveCOM');
	`log(kDialogData.strText,, 'WaveCOM');
	`log("==========END UNIT INFO==========",, 'WaveCOM');
}

exec function ReviveAll()
{
	local WaveCOMGameStateContext_UpdateUnit EffectContext;
	local StateObjectReference AbilityReference, UnitRef;
	local XComGameState NewGameState;
	local XGUnit Visualizer;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom)
		{
			EffectContext = class'WaveCOMGameStateContext_UpdateUnit'.static.CreateChangeStateUU("Clean Unit State", UnitState);
			NewGameState = EffectContext.GetGameState();
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			`log("Cleaning and readding Abilities");
			foreach UnitState.Abilities(AbilityReference)
			{
				NewGameState.RemoveStateObject(AbilityReference.ObjectID);
			}
			UnitState.Abilities.Length = 0;
			Visualizer = XGUnit(UnitState.FindOrCreateVisualizer());
			Visualizer.GetPawn().StopPersistentPawnPerkFX(); // Remove all abilities visualizers

			class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState, EffectContext);
			class'WaveCOM_UIArmory_FieldLoadout'.static.RefillInventory(NewGameState, UnitState);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			UnitRef = UnitState.GetReference();
			if (UnitState.IsAlive() && XComHQ.Squad.Find('ObjectID', UnitRef.ObjectID) != INDEX_NONE && !UnitState.bRemovedFromPlay)
			{
				class'WaveCOM_UIArmory_FieldLoadout'.static.UpdateUnit(UnitRef.ObjectID);
			}
		}
	}
}

static function int GetPlayerGroupID(optional XComGameState NewGameState)
{
	local XComGameState_AIGroup GroupState;
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	foreach `XCOMHISTORY.IterateByClassType( class'XComGameState_AIGroup', GroupState )
	{
		if (GroupState.TeamName == eTeam_XCom && BattleData.PlayerTurnOrder.Find('ObjectID', GroupState.ObjectID) != INDEX_NONE)
			return GroupState.ObjectID;
	}

	if (NewGameState != none)
	{
		GroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
		`TACTICALRULES.AddGroupToInitiativeOrder(GroupState, NewGameState);
		return GroupState.ObjectID;
	}

	return -1;
}

static function FixGroupSpawn()
{
	local int idx;
	local XComGameState_Unit Unit;
	local XComGameState_AIGroup NewGroupState;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fixing AIGroups");
	NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GetPlayerGroupID(NewGameState)));

	for (idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', XComHQ.Squad[idx].ObjectID));
		if (Unit.GetGroupMembership(NewGameState) == none || Unit.GetGroupMembership(NewGameState).ObjectID != NewGroupState.ObjectID)
		{
			NewGroupState.AddUnitToGroup(Unit.ObjectID, NewGameState);
		}
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function FixSquadGroupSpawnOwnership()
{
	FixGroupSpawn();
}

exec function TestPanel(int X, int Y, int Width, int Height)
{
	local UIScreen Screen;
	local UIBGBox BGPanel;

	Screen = `SCREENSTACK.GetCurrentScreen();

	BGPanel = UIBGBox(Screen.GetChildByName('TestDebugPanel', false));

	if (BGPanel != none)
	{
		BGPanel.SetPosition(X, Y);
		BGPanel.SetSize(Width, Height);
	}
	else
	{
		BGPanel = Screen.Spawn(class'UIBGBox', Screen);
		BGPanel.InitBG('TestDebugPanel', X, Y, Width, Height);
		BGPanel.SetBGColor("FF0000");
		BGPanel.AnimateIn(0);
	}

	if (Width <= 0 || Height <= 0)
	{
		BGPanel.Hide();
	}
}