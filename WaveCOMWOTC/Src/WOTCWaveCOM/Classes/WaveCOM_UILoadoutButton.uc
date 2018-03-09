class WaveCOM_UILoadoutButton extends UIPanel config(WaveCOM);
// This event is triggered after a screen is initialized. This is called after  // the visuals (if any) are loaded in Flash.
var UIButton Button1, Button2, Button3, Button4, Button5, Button6, Button7, Button8;
var UIPanel ActionsPanel;
var UITacticalHUD TacHUDScreen;
var WaveCOM_UIArmory_FieldLoadout UIArmory_FieldLoad;
var WaveCOM_UIAvengerHUD AvengerHUD;

var const config array<int> WaveCOMDeployCosts;
var const config array<int> WaveCOMHeroDeployExtraCosts;
var const config array<int> WaveCOMHeroIntelCosts;
var int CurrentDeployCost;

var bool PendingResearchScreen;
var bool WaitForInspireBreakthroughPopup;

simulated function InitScreen(UIScreen ScreenParent)
{
	local Object ThisObj;
	local WaveCOM_MissionLogic_WaveCOM WaveLogic;

	super.InitPanel('WaveCOMUI');

	CurrentDeployCost = 50;

	class'X2DownloadableContentInfo_WOTCWaveCOM'.static.UpdateResearchTemplates();

	TacHUDScreen = UITacticalHUD(ScreenParent);
	`log("Loading my button thing.");

	ActionsPanel = TacHUDScreen.Spawn(class'UIPanel', TacHUDScreen);
	ActionsPanel.InitPanel('WaveCOMActionsPanel');
	ActionsPanel.SetSize(450, 100);
	ActionsPanel.AnchorTopCenter();

	Button1 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button1.InitButton('LoadoutButton', "Loadout", OpenLoadout);
	Button1.SetY(ActionsPanel.Y);
	Button1.SetX(0);
	Button1.SetWidth(170);

	Button6 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button6.InitButton('DeploySoldier', "Deploy Soldier - " @CurrentDeployCost, OpenDeployMenu);
	Button6.SetY(ActionsPanel.Y + 30);
	Button6.SetX(0);
	Button6.SetWidth(170);

	Button2 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button2.InitButton('BuyButton', "Buy Equipment", OpenBuyMenu);
	Button2.SetY(ActionsPanel.Y);
	Button2.SetX(Button1.X + Button1.Width + 30);
	Button2.SetWidth(120);

	Button4 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button4.InitButton('ResearchButton', "Research", OpenResearchMenu);
	Button4.SetY(ActionsPanel.Y + 30);
	Button4.SetX(Button1.X + Button1.Width + 30);
	Button4.SetWidth(120);

	Button3 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button3.InitButton('Proving Grounds', "Proving Grounds", OpenProjectMenu);
	Button3.SetY(ActionsPanel.Y);
	Button3.SetX(Button4.X + Button4.Width + 30);
	Button3.SetWidth(120);

	Button5 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button5.InitButton('ViewInventory', "View Inventory", OpenStorage);
	Button5.SetY(ActionsPanel.Y + 30);
	Button5.SetX(Button4.X + Button4.Width + 30);
	Button5.SetWidth(120);

	Button7 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button7.InitButton('OTS', "Training School", OpenOTSMenu);
	Button7.SetY(ActionsPanel.Y);
	Button7.SetX(Button5.X + Button5.Width + 30);
	Button7.SetWidth(120);

	Button8 = ActionsPanel.Spawn(class'UIButton', ActionsPanel);
	Button8.InitButton('BlackMarket', "Black Market", OpenBlackMarket);
	Button8.SetY(ActionsPanel.Y + 30);
	Button8.SetX(Button5.X + Button5.Width + 30);
	Button8.SetWidth(120);

	ActionsPanel.SetWidth(Button7.X + Button7.Width - ActionsPanel.X + 50);
	ActionsPanel.SetX(ActionsPanel.Width * -0.5);
	ActionsPanel.AnchorTopCenter();

	AvengerHUD = TacHUDScreen.Movie.Pres.Spawn(class'WaveCOM_UIAvengerHUD', TacHUDScreen.Movie.Pres);
	TacHUDScreen.Movie.Stack.Push(AvengerHUD, TacHUDScreen.Movie);
	AvengerHUD.HideResources();
	UpdateDeployCost();
	UpdateResources();

	WaveLogic = WaveCOM_MissionLogic_WaveCOM(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'WaveCOM_MissionLogic_WaveCOM'));
	if (WaveLogic != none && WaveLogic.WaveStatus != eWaveStatus_Preparation)
	{
		// When we load the game, check if we are still in combat phase, if so, don't show the panel.
		AvengerHUD.HideResources();
		ActionsPanel.Hide();
	}

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'WaveCOM_WaveStart', OnWaveStart, ELD_Immediate);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'WaveCOM_WaveEnd', OnWaveEnd, ELD_OnVisualizationBlockCompleted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'UnitDied', OnDeath, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'UpdateDeployCost', OnDeath, ELD_Immediate);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'UpdateDeployCostDelayed', OnDeath, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'ResearchCompleted', ResearchComplete, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'UpdateResearchCost', UpdateTechCost, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'ItemConstructionCompleted', UpdateResourceHUD, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'PsiTrainingUpdate', UpdateResourceHUD, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'BlackMarketGoodsSold', UpdateResourceHUD, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'BlackMarketPurchase', UpdateResourceHUD, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'RequestRefreshAllUnits', RefreshAllUnits, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'BondCreated', RefreshOneUnit, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'BondLevelUpComplete', RefreshOneUnit, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'RefreshTacHUD', RefreshTacHUD, ELD_OnVisualizationBlockCompleted);
}

public function XComGameState_Unit GetNonDeployedSoldier()
{
	local XComGameState_HeadquartersXCom XComHQ;	
	local StateObjectReference UnitRef;
	local XComGameState_Unit UnitState;
			
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ != none)
	{
		foreach XComHQ.Squad(UnitRef)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState != none && UnitState.IsAlive() && (UnitState.Abilities.Length == 0 || UnitState.bRemovedFromPlay)) // Uninitialized
			{
				return UnitState;
			}
		}
	}
	return none;
}

private function int UpdateDeployCost()
{
	local int XComCount;
	local XComGameState_HeadquartersXCom XComHQ;

	`log("Updating deploy cost",, 'WaveCOM');

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComCount = XComHQ.Squad.Length;
	`log("Count: " @XComCount,, 'WaveCOM');

	
	if (XComCount > WaveCOMDeployCosts.Length - 1)
	{
		CurrentDeployCost = WaveCOMDeployCosts[WaveCOMDeployCosts.Length - 1];
	}
	else
	{
		CurrentDeployCost = WaveCOMDeployCosts[XComCount];
	}

	if (GetNonDeployedSoldier() != none)
	{
		Button6.SetText("Deploy pending soldier");
	}
	else
	{
		Button6.SetText("Deploy Soldier - " @CurrentDeployCost);
	}

	return XComCount;

}

private function EventListenerReturn RefreshTacHUD(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	TacHUDScreen.ForceUpdate(-1);
	TacHUDScreen.m_kPerks.UpdatePerks();
	TacHUDScreen.m_kStatsContainer.LastVisibleActiveUnitID = -1; // Force refresh
	TacHUDScreen.m_kStatsContainer.UpdateStats();

	return ELR_NoInterrupt;
}

private function EventListenerReturn OnDeath(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	UpdateDeployCost();
	return ELR_NoInterrupt;
}

private function EventListenerReturn OnWaveStart(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	AvengerHUD.HideResources();
	ActionsPanel.Hide();
	return ELR_NoInterrupt;
}

private function EventListenerReturn OnWaveEnd(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	UpdateResources();
	ActionsPanel.Show();
	RefreshRewardDecks();
	RefreshCanRankUp();
	TacHUDScreen.RefreshSitRep(); // Update sit rep at bottom left
	return ELR_NoInterrupt;
}

private function EventListenerReturn UpdateResourceHUD(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	UpdateResources();
	return ELR_NoInterrupt;
}

static function StateObjectReference InspireATech(XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ, int ThisTechID)
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechRefs;
	local X2TechTemplate TechTemplate;
	local XComGameState_Tech AvailableTechState;
	local int TechIndex;
	local bool bTechFound;
	local StrategyCost NoCost;
	local array<StrategyCostScalar> NoCostScalars;

	History = `XCOMHISTORY;
	AvailableTechRefs = XComHQ.GetAvailableTechsForResearch();
	`log(AvailableTechRefs.Length @ "possible inspirations. Completed research=" $ ThisTechID,, 'WaveCOM');
	while (AvailableTechRefs.Length > 0 && !bTechFound)
	{
		TechIndex = class'Engine'.static.GetEngine().SyncRand(AvailableTechRefs.Length, "InspireTechRoll");
		AvailableTechState = XComGameState_Tech(History.GetGameStateForObjectID(AvailableTechRefs[TechIndex].ObjectID));
		TechTemplate = AvailableTechState.GetMyTemplate();

		// Prevent any techs which could be made instant (autopsies), or which have already been reduced by purchasing tech reductions from the black market
		// and only inspire techs which the player can afford
		if (!XComHQ.HasPausedProject(AvailableTechRefs[TechIndex]) &&
			AvailableTechRefs[TechIndex].ObjectID != ThisTechID &&
			XComHQ.MeetsRequirmentsAndCanAffordCost(TechTemplate.Requirements, NoCost, NoCostScalars, , TechTemplate.AlternateRequirements))
		{
			AvailableTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', AvailableTechState.ObjectID));
			AvailableTechState.bInspired = true;
				
			// Save the current inspired tech into XComHQ so it can be easily accessed after the next tech is started
			XComHQ.CurrentInspiredTech = AvailableTechState.GetReference();

			`log("Inspiring" @ TechTemplate.DisplayName @ "(" $ AvailableTechRefs[TechIndex].ObjectID $ ")",, 'WaveCOM');
				
			bTechFound = true;
		}
		else
		{
			`log("Tech not elligible for inspiration:" @ TechTemplate.DisplayName @ "(" $ AvailableTechRefs[TechIndex].ObjectID $ ")",, 'WaveCOM');
			AvailableTechRefs.Remove(TechIndex, 1);
		}
	}

	if (!bTechFound)
		XComHQ.CurrentInspiredTech.ObjectID = -1;

	return XComHQ.CurrentInspiredTech;
}

// Research is completed
private function EventListenerReturn ResearchComplete(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	local UISimpleCommodityScreen ProjectScreen;
	local XComGameState_Tech TechState;
	local DynamicPropertySet PropertySet, SecondSet;
	local X2TechTemplate TechTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState AddToGameState;
	local StateObjectReference InspiredID;
	local bool bShouldShowPopup;

	`log("Event Heard :: ResearchComplete",, 'WaveCOM');
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Refresh foreground
	ProjectScreen = UISimpleCommodityScreen(TacHUDScreen.Movie.Stack.GetFirstInstanceOf(class'WaveCOM_UIChooseProvingGrounds'));
	if (ProjectScreen == none)
		ProjectScreen = UISimpleCommodityScreen(TacHUDScreen.Movie.Stack.GetFirstInstanceOf(class'WaveCOM_UIChooseResearch'));
	if (ProjectScreen != none)
	{
		ProjectScreen.GetItems();
		ProjectScreen.PopulateData();
	}

	TechState = XComGameState_Tech(EventData);
	if (TechState != none && TechState.ItemRewards.Length > 0)
	{
		`PRES.BuildUIAlert(PropertySet, 'eAlert_ItemReceivedProvingGround', None, '', "Geoscape_ItemComplete");
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', TechState.ItemRewards[0].DataName);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechState.GetReference().ObjectID);
		bShouldShowPopup = true;
	}
	else if (TechState != none && TechState.GetMyTemplate().bProvingGround)
	{
		`PRES.BuildUIAlert(PropertySet, 'eAlert_ProvingGroundProjectComplete', PGCompletedCB, '', "Geoscape_ProjectComplete", true);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechState.GetReference().ObjectID);
		bShouldShowPopup = true;
	}
	else if (TechState != none)
	{		
		`PRES.BuildUIAlert(PropertySet, 'eAlert_ResearchComplete', ResearchCB, '', "Geoscape_ResearchComplete", true);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechState.GetReference().ObjectID);
		bShouldShowPopup = true;
	}

	TechTemplate = TechState.GetMyTemplate(); // Get the template for the completed tech
	if (!TechTemplate.bShadowProject && !TechTemplate.bProvingGround)
	{
		if (TechTemplate.bBreakthrough)
		{
			// Roll a new breakthrough
			`log("Trying to roll a new breakthrough",, 'WaveCOM');
			AddToGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Forcing breakthorugh");
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.BreakthroughTechTimer = XComHQ.GetCurrentTime(); // FORCE BREAKTHROUGH!
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(XComHQ.BreakthroughTechTimer, -10);
			XComHQ.CurrentBreakthroughTech.ObjectID = 0;
			XComHQ.CheckForBreakthroughTechs(AddToGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(AddToGameState);

			if (XComHQ.CurrentBreakthroughTech.ObjectID > 0)
			{
				`PRES.BuildUIAlert(SecondSet, 'eAlert_BreakthroughResearchAvailable', DismissInspireBreakthroughPopup, 'OnInspiredTech', "ResearchBreakthrough", true);
				class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(SecondSet, 'TechRef', XComHQ.CurrentBreakthroughTech.ObjectID);
				`PRES.QueueDynamicPopup(SecondSet);
				WaitForInspireBreakthroughPopup = true;
			}
		}
		else if (XComHQ.CurrentInspiredTech.ObjectID <= 0 || XComHQ.CurrentInspiredTech.ObjectID == TechState.ObjectID)
		{
			`log("Trying to roll a new inspiration",, 'WaveCOM');
			// Inspire a random tech if it is not a breakthrough and nothing else is inspired
			AddToGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Forcing breakthorugh");
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			InspiredID = InspireATech(AddToGameState, XComHQ, TechState.ObjectID);
			`XCOMGAME.GameRuleset.SubmitGameState(AddToGameState);
	
			if (InspiredID.ObjectID > 0)
			{
				`PRES.BuildUIAlert(SecondSet, 'eAlert_InspiredResearchAvailable', DismissInspireBreakthroughPopup, '', "ResearchInspiration", true);
				class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(SecondSet, 'TechRef', InspiredID.ObjectID);
				`PRES.QueueDynamicPopup(SecondSet);
				WaitForInspireBreakthroughPopup = true;
			}
		}
	}


	if (bShouldShowPopup)
	{
		`PRES.QueueDynamicPopup(PropertySet);
	}

	return UpdateTechCost(EventData, EventSource, NewGameState, InEventID, CallbackData);
}

private function EventListenerReturn UpdateTechCost(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	UpdateDeployCost();

	UpdateResourceHUD(EventData, EventSource, NewGameState, InEventID, none);

	return ELR_NoInterrupt;
}

simulated function ResearchCB(name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	if (eAction == 'eUIAction_Accept')
	{
		if (WaitForInspireBreakthroughPopup)
		{
			PendingResearchScreen = true;
		}
		else
		{
			OpenResearchMenu(Button4);
		}
	}
}

simulated function DismissInspireBreakthroughPopup(name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	WaitForInspireBreakthroughPopup = false;
	if (PendingResearchScreen)
	{
		OpenResearchMenu(Button4);
	}
}

simulated function PGCompletedCB(name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local WaveCOM_UIChooseProvingGrounds LoadedScreen;
	LoadedScreen = WaveCOM_UIChooseProvingGrounds(TacHUDScreen.Movie.Stack.GetFirstInstanceOf(class'WaveCOM_UIChooseProvingGrounds'));
	if (LoadedScreen != none)
	{
		if (eAction != 'eUIAction_Accept')
		{
			LoadedScreen.OnCancel();
		}
		else
		{
			LoadedScreen.RegenerateList();
		}
	}
}

private function EventListenerReturn RefreshOneUnit(Object EventData, Object EventSource, XComGameState TriggeringGameState, Name InEventID, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local StateObjectReference AbilityReference;
	local WaveCOMGameStateContext_UpdateUnit EffectContext;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	UnitState = XComGameState_Unit(EventSource);

	if( UnitState.GetTeam() == eTeam_XCom && UnitState.IsAlive() && XComHQ.Squad.Find('ObjectID', UnitState.GetReference().ObjectID) != INDEX_NONE && !UnitState.bRemovedFromPlay)
	{
		EffectContext = class'WaveCOMGameStateContext_UpdateUnit'.static.CreateChangeStateUU("Clean Unit State", UnitState);
		NewGameState = EffectContext.GetGameState();
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		`log("Cleaning and readding Abilities");
		foreach UnitState.Abilities(AbilityReference)
		{
			NewGameState.RemoveStateObject(AbilityReference.ObjectID);
		}

		class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			
		class'WaveCOM_UIArmory_FieldLoadout'.static.UpdateUnit(UnitState.GetReference().ObjectID);
	}

	UpdateResources();

	return ELR_NoInterrupt;
}

private function EventListenerReturn RefreshAllUnits(Object EventData, Object EventSource, XComGameState TriggeringGameState, Name InEventID, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local StateObjectReference AbilityReference;
	local WaveCOMGameStateContext_UpdateUnit EffectContext;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> UnitToSyncVis;
			
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom && UnitState.IsAlive() && XComHQ.Squad.Find('ObjectID', UnitState.GetReference().ObjectID) != INDEX_NONE && !UnitState.bRemovedFromPlay)
		{
			EffectContext = class'WaveCOMGameStateContext_UpdateUnit'.static.CreateChangeStateUU("Clean Unit State", UnitState);
			NewGameState = EffectContext.GetGameState();
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			`log("Cleaning and readding Abilities");
			foreach UnitState.Abilities(AbilityReference)
			{
				NewGameState.RemoveStateObject(AbilityReference.ObjectID);
			}

			class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			
			class'WaveCOM_UIArmory_FieldLoadout'.static.UpdateUnit(UnitState.GetReference().ObjectID, false);
			UnitToSyncVis.AddItem(UnitState);
		}
	}
	
	class'WaveCOM_UIArmory_FieldLoadout'.static.SyncVisualizers(UnitToSyncVis);

	return ELR_NoInterrupt;
}

public function UpdateResources()
{
	AvengerHUD.ClearResources();
	AvengerHUD.ShowResources();
	AvengerHUD.UpdateSupplies();
	AvengerHUD.UpdateIntel();
	AvengerHUD.UpdateEleriumCores();
}

public function OpenLoadout(UIButton Button)
{
	local StateObjectReference ActiveUnitRef;

	ActiveUnitRef = XComTacticalController(TacHUDScreen.PC).GetActiveUnitStateRef();
	UIArmory_FieldLoad = TacHUDScreen.Movie.Pres.Spawn(class'WaveCOM_UIArmory_FieldLoadout', TacHUDScreen.Movie.Pres);
	TacHUDScreen.Movie.Stack.Push(UIArmory_FieldLoad); 
	UIArmory_FieldLoad.SetTacHUDScreen(TacHUDScreen);
	UIArmory_FieldLoad.InitArmory(ActiveUnitRef);
}

public function OpenBuyMenu(UIButton Button)
{
	local UIInventory_BuildItems LoadedScreen;
	UpdateResources();
	LoadedScreen = TacHUDScreen.Movie.Pres.Spawn(class'UIInventory_BuildItems', TacHUDScreen.Movie.Pres);
	LoadedScreen.bConsumeMouseEvents = true;
	TacHUDScreen.Movie.Stack.Push(LoadedScreen, TacHUDScreen.Movie); 
}

public function OpenStorage(UIButton Button)
{
	local UIInventory_Storage LoadedScreen;
	UpdateResources();
	LoadedScreen = TacHUDScreen.Movie.Pres.Spawn(class'UIInventory_Storage', TacHUDScreen.Movie.Pres);
	LoadedScreen.bConsumeMouseEvents = true;
	TacHUDScreen.Movie.Stack.Push(LoadedScreen, TacHUDScreen.Movie); 
}

public function OpenBlackMarket(UIButton Button)
{
	local WaveCOM_UIBlackMarket LoadedScreen;
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarket;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Black Market Prices");
	BlackMarket = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	BlackMarket = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarket.ObjectID));
	BlackMarket.UpdateBuyPrices();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	UpdateResources();
	LoadedScreen = TacHUDScreen.Movie.Pres.Spawn(class'WaveCOM_UIBlackMarket', TacHUDScreen.Movie.Pres);
	TacHUDScreen.Movie.Stack.Push(LoadedScreen, TacHUDScreen.Movie); 
}

public function OpenResearchMenu(UIButton Button)
{
	local WaveCOM_UIChooseResearch LoadedScreen;
	PendingResearchScreen = false;
	UpdateResources();
	LoadedScreen = TacHUDScreen.Movie.Pres.Spawn(class'WaveCOM_UIChooseResearch', TacHUDScreen.Movie.Pres);
	TacHUDScreen.Movie.Stack.Push(LoadedScreen, TacHUDScreen.Movie);
}

public function OpenProjectMenu(UIButton Button)
{
	local WaveCOM_UIChooseProvingGrounds LoadedScreen;
	UpdateResources();
	LoadedScreen = TacHUDScreen.Movie.Pres.Spawn(class'WaveCOM_UIChooseProvingGrounds', TacHUDScreen.Movie.Pres);
	TacHUDScreen.Movie.Stack.Push(LoadedScreen, TacHUDScreen.Movie);
}

public function OpenOTSMenu(UIButton Button)
{
	local WaveCOM_UIOfficerTrainingSchool LoadedScreen;
	local XComGameState_FacilityXCom FacilityState;
	local X2FacilityTemplate FacilityTemplate;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local TDialogueBoxData  kDialogData;

	UpdateResources();

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if (FacilityState.GetMyTemplateName() == 'OfficerTrainingSchool')
		{
			break;
		}
		else
		{
			FacilityState = none;
		}
	}

	if (FacilityState == none)
	{
		// Create new OTS Facility
		FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('OfficerTrainingSchool'));
		if (FacilityTemplate != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding missing OTS");
			FacilityState = FacilityTemplate.CreateInstanceFromTemplate(NewGameState);
			
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Facilities.AddItem(FacilityState.GetReference());
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			FacilityTemplate.OnFacilityBuiltFn(FacilityState.GetReference());
		}
	}
	
	if (FacilityState != none)
	{
		LoadedScreen = TacHUDScreen.Movie.Pres.Spawn(class'WaveCOM_UIOfficerTrainingSchool', TacHUDScreen.Movie.Pres);
		LoadedScreen.FacilityRef = FacilityState.GetReference();
		TacHUDScreen.Movie.Stack.Push(LoadedScreen, TacHUDScreen.Movie);
	}
	else
	{
		kDialogData.eType = eDialog_Alert;
		kDialogData.strTitle = "Failed to spawn OTS Facility";
		kDialogData.strText = "Unable to spawn OTS facility, there may be a bug or you are using an older version.";

		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

		`PRES.UIRaiseDialog(kDialogData);
	}
}

public function OpenDeployMenu(UIButton Button)
{
	local XComGameStateHistory History;
	local XComGameState_Unit StrategyUnit;
	local XComGameState_HeadquartersXCom XComHQ;
	local ArtifactCost Resources;
	local StrategyCost DeployCost;
	local array<StrategyCostScalar> EmptyScalars;
	local XComGameState NewGameState;

	local TDialogueBoxData  kDialogData;

	History = `XCOMHISTORY;
	// grab the archived strategy state from the history and the headquarters object
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		
	StrategyUnit = GetNonDeployedSoldier();
	if (StrategyUnit != none)
	{
		StrategyUnit = AddStrategyUnitToBoard(StrategyUnit, History);
		if (StrategyUnit == none)
		{
			kDialogData.eType = eDialog_Alert;
			kDialogData.strTitle = "Failed to spawn unit";
			kDialogData.strText = "Unable to spawn the requested unit, there might be no room on the spawn zone.";

			kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

			`PRES.UIRaiseDialog(kDialogData);
		}
		else
		{
			class'WaveCOM_MissionLogic_WaveCOM'.static.FullRefreshSoldier(StrategyUnit.GetReference());
		}
		UpdateDeployCost();
		return;
	}
	else if (XComHQ.GetSupplies() < CurrentDeployCost)
	{
		UpdateDeployCost();
		UpdateResources();
		
		kDialogData.eType = eDialog_Alert;
		kDialogData.strTitle = "Not enough supplies";
		kDialogData.strText = "You need" @ CurrentDeployCost @ "to deploy new soldier.";

		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

		`PRES.UIRaiseDialog(kDialogData);

		return;
	}

	// try to get a unit from the strategy game
	StrategyUnit = ChooseStrategyUnit(History);

	// Avenger runs out of unit???
	if (StrategyUnit == none)
	{
		// Create New Rookie
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Generate new soldier");
		StrategyUnit = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, `XPROFILESETTINGS.Data.m_eCharPoolUsage);
		StrategyUnit.ApplyBestGearLoadout(NewGameState);

		XComHQ.AddToCrew(NewGameState, StrategyUnit);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	// and add it to the board
	if (StrategyUnit != none)
	{
		StrategyUnit.StartingRank = XComHQ.BonusTrainingRanks + 1; // Need +1 because the starting rank is calculated after GTS training

		StrategyUnit = AddStrategyUnitToBoard(StrategyUnit, History);

		if (StrategyUnit != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pay for Soldier");
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

			Resources.ItemTemplateName = 'Supplies';
			Resources.Quantity = CurrentDeployCost;
			DeployCost.ResourceCosts.AddItem(Resources);
			XComHQ.PayStrategyCost(NewGameState, DeployCost, EmptyScalars);
			XComHQ.Squad.AddItem(StrategyUnit.GetReference());
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			class'WaveCOM_MissionLogic_WaveCOM'.static.FullRefreshSoldier(StrategyUnit.GetReference());
			UpdateDeployCost();
			UpdateResources();
		}
		else
		{
			kDialogData.eType = eDialog_Alert;
			kDialogData.strTitle = "Failed to spawn unit";
			kDialogData.strText = "Unable to spawn the requested unit, there might be no room on the spawn zone.";

			kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

			`PRES.UIRaiseDialog(kDialogData);
		}
	}
	else
	{
		kDialogData.eType = eDialog_Alert;
		kDialogData.strTitle = "No more reserves";
		kDialogData.strText = "No more reserves in avenger.\nTODO: Refill avenger reserves (Crew count:" @ XComHQ.Crew.Length @ ", Squad count:" @ XComHQ.Squad.Length @ ")";

		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

		`PRES.UIRaiseDialog(kDialogData);
	}
}

// Scans the strategy game and chooses a unit to place on the game board
private static function XComGameState_Unit ChooseStrategyUnit(XComGameStateHistory History)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference HQCrew;
	local XComGameState_Unit StrategyUnit;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		`Redscreen("SeqAct_SpawnUnitFromAvenger: Could not find an XComGameState_HeadquartersXCom state in the archive!");
	}

	// and find a unit in the strategy state that is not on the board
	foreach XComHQ.Crew(HQCrew)
	{
		StrategyUnit = XComGameState_Unit(History.GetGameStateForObjectID(HQCrew.ObjectID));

		if (StrategyUnit == none)
		{	
			`log("UnitState not found in avenger",, 'WaveCOM');
			continue;
		}
		// only living soldier units please
		if (StrategyUnit.IsDead() || !StrategyUnit.IsSoldier() || StrategyUnit.IsTraining() || StrategyUnit.Abilities.Length > 0)
		{
			continue;
		}

		// only if not already on the board
		if(XComHQ.Squad.Find('ObjectID', StrategyUnit.ObjectID) != INDEX_NONE || StrategyUnit.bRemovedFromPlay)
		{
			`log("UnitState already part of squad",, 'WaveCOM');
			continue;
		}

		return StrategyUnit;
	}

	return none;
}

// chooses a location for the unit to spawn in the spawn zone
public static function bool ChooseSpawnLocation(out Vector SpawnLocation)
{
	local XComParcelManager ParcelManager;
	local XComGroupSpawn SoldierSpawn;
	local array<Vector> FloorPoints;

	// attempt to find a place in the spawn zone for this unit to spawn in
	ParcelManager = `PARCELMGR;
	SoldierSpawn = ParcelManager.SoldierSpawn;

	if(SoldierSpawn == none) // check for test maps, just grab any spawn
	{
		foreach `XComGRI.AllActors(class'XComGroupSpawn', SoldierSpawn)
		{
			break;
		}
	}

	SoldierSpawn.GetValidFloorLocations(FloorPoints);
	if(FloorPoints.Length == 0)
	{
		return false;
	}
	else
	{
		SpawnLocation = FloorPoints[0];
		return true;
	}
}

// Places the given strategy unit on the game board
static function XComGameState_Unit AddStrategyUnitToBoard(XComGameState_Unit Unit, XComGameStateHistory History)
{
	local X2TacticalGameRuleset Rules;
	local Vector SpawnLocation;
	local XComGameStateContext_TacticalGameRule NewGameStateContext, CheatContext;
	local XComGameState NewGameState;
	local XComGameState_Player PlayerState;
	local StateObjectReference ItemReference;
	local XComGameState_Item ItemState;
	local XComGameState_AIGroup NewGroupState;
	local UIUnitFlag UnitFlags;

	if(Unit == none)
	{
		return none;
	}

	// pick a floor point at random to spawn the unit at
	if(!ChooseSpawnLocation(SpawnLocation))
	{
		return none;
	}

	// create the history frame with the new tactical unit state
	NewGameStateContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	NewGameStateContext.GameRuleType = eGameRule_UnitAdded;
	NewGameStateContext.SetAssociatedPlayTiming(SPT_AfterSequential);
	NewGameState = History.CreateNewGameState(true, NewGameStateContext);
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Unit.bSpawnedFromAvenger = true;
	Unit.ClearRemovedFromPlayFlag();
	Unit.SetVisibilityLocationFromVector(SpawnLocation);
	if (!Unit.IsInPlay())
	{
		Unit.BeginTacticalPlay(NewGameState);
	}
	NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', class'X2DownloadableContentInfo_WOTCWaveCOM'.static.GetPlayerGroupID(NewGameState)));
	NewGroupState.AddUnitToGroup(Unit.ObjectID, NewGameState);

	// assign the new unit to the human team
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(PlayerState.GetTeam() == eTeam_XCom)
		{
			Unit.SetControllingPlayer(PlayerState.GetReference());
			break;
		}
	}

	// add item states. This needs to be done so that the visualizer sync picks up the IDs and
	// creates their visualizers
	foreach Unit.InventoryItems(ItemReference)
	{
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemReference.ObjectID));

		// add the gremlin to Specialists
		if( ItemState.OwnerStateObject.ObjectID == Unit.ObjectID )
		{
			ItemState.CreateCosmeticItemUnit(NewGameState);
		}
	}

	Rules = `TACTICALRULES;

	// submit it
	XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = Unit.GetReference();
	Rules.SubmitGameState(NewGameState);

	// Do Proper teleport to update visualization
	CheatContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	CheatContext.GameRuleType = eGameRule_ReplaySync;
	NewGameState = History.CreateNewGameState(true, CheatContext);
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Unit.SetVisibilityLocationFromVector(SpawnLocation);
	
	// add abilities
	// Must happen after items are added, to do ammo merging properly.
	Rules.InitializeUnitAbilities(NewGameState, Unit);

	// make the unit concealed, if they have Phantom
	// (special-case code, but this is how it works when starting a game normally)
	if (Unit.FindAbility('Phantom').ObjectID > 0)
	{
		Unit.EnterConcealmentNewGameState(NewGameState);
	}

	`TACTICALRULES.SubmitGameState(NewGameState);

	UnitFlags = `PRES.m_kUnitFlagManager.GetFlagForObjectID( Unit.ObjectID );
	UnitFlags.RealizeFaction(Unit);

	return Unit;
}

function RefreshRewardDecks()
{
	local X2StrategyElementTemplateManager StrMgr;
	local array<X2StrategyElementTemplate> StrTemplates;
	local X2StrategyElementTemplate Template;
	local X2TechTemplate TechTemplate;

	StrMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	StrTemplates = StrMgr.GetAllTemplatesOfClass(class'X2TechTemplate');

	foreach StrTemplates(Template)
	{
		TechTemplate = X2TechTemplate(Template);
		if (TechTemplate != none)
		{
			RefreshTechTemplate(TechTemplate.RewardDeck);
		}
	}
}

function RefreshTechTemplate(name DeckName)
{
	local X2CardManager CardStack;
	local X2ItemTemplateManager ItemMgr;
	local X2DataTemplate DataTemplate;
	local X2ItemTemplate Template;
	local array<string> Cards;
	local string Card;

	if (string(DeckName) == "")
		return;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CardStack = class'X2CardManager'.static.GetCardManager();
	//`log("Checking deck" @ DeckName,, 'RewardDecksRefresh');

	CardStack.GetAllCardsInDeck(DeckName, Cards);

	foreach ItemMgr.IterateTemplates(DataTemplate, none)
	{
		Template = X2ItemTemplate(DataTemplate);
		if (Template != none && Template.RewardDecks.Find(DeckName) != INDEX_NONE)
		{
			if (Cards.Find(string(Template.DataName)) != INDEX_NONE)
			{
				Cards.RemoveItem(string(Template.DataName));
			}
			else
			{
				CardStack.AddCardToDeck(DeckName, string(Template.DataName));
				`log(Template.DataName @ "not found in deck, adding to deck",, 'RewardDecksRefresh');
			}
		}
	}

	foreach Cards(Card)
	{
		CardStack.RemoveCardFromDeck(DeckName, Card);
		`log(Card @ "not found in item templates, removing from deck",, 'RewardDecksRefresh');
	}
}

function RefreshCanRankUp()
{
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;
			
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (XComHQ == none)
	{
		Button1.NeedsAttention(false);
		return;
	}

	`log("Refreshing rank up notification",, 'WaveCOM');
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( (UnitState.GetTeam() == eTeam_XCom) && UnitState.IsAlive() && UnitState.IsSoldier() && XComHQ.Squad.Find('ObjectID', UnitState.GetReference().ObjectID) != INDEX_NONE && !UnitState.bRemovedFromPlay)
		{
			if (UnitState.ShowPromoteIcon())
			{
				Button1.NeedsAttention(true);
				return;
			}
		}
	}
	Button1.NeedsAttention(false);
}
