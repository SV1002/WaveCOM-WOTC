class WaveCOM_UIInventory_PCS extends UIInventory_Implants;

simulated function bool CanEquipImplant(StateObjectReference ImplantRef)
{
	local XComGameState_Unit Unit;
	local XComGameState_Item Implant, ImplantToRemove;
	local array<XComGameState_Item> EquippedImplants;
	
	Implant = XComGameState_Item(History.GetGameStateForObjectID(ImplantRef.ObjectID));
	Unit = WaveCOM_UIArmory_FieldLoadout(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).GetUnit();
	
	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	if (EquippedImplants.Length > 0)
	{
		ImplantToRemove = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(EquippedImplants[0].ObjectID));
	
		if(class'UIUtilities_Strategy'.static.GetStatBoost(Implant).StatType == 
			class'UIUtilities_Strategy'.static.GetStatBoost(ImplantToRemove).StatType  && 
			class'UIUtilities_Strategy'.static.GetStatBoost(Implant).Boost <= 
			class'UIUtilities_Strategy'.static.GetStatBoost(ImplantToRemove).Boost)
			return false;
	}
	return class'UIUtilities_Strategy'.static.GetStatBoost(Implant).StatType != eStat_PsiOffense || Unit.IsPsiOperative();
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local int SlotIndex;
	local XComGameState_Unit Unit;
	local UISoldierHeader SoldierHeader;
	local array<XComGameState_Item> EquippedImplants;
	local XComGameState_Item ImplantToAdd, ImplantToRemove;
	local string Will, Aim, Health, Mobility, Tech, Psi;

	super.SelectedItemChanged(ContainerList, ItemIndex);

	Unit = WaveCOM_UIArmory_FieldLoadout(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).GetUnit();
	SoldierHeader = WaveCOM_UIArmory_FieldLoadout(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).Header;
	SlotIndex = 0;
	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);

	ImplantToAdd = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Implants[List.SelectedIndex].ObjectID));
	if(SlotIndex < EquippedImplants.Length)
		ImplantToRemove = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(EquippedImplants[SlotIndex].ObjectID));
	
	Will = string( int(Unit.GetCurrentStat( eStat_Will )) ) $ GetStatBoostString(ImplantToAdd, ImplantToRemove, eStat_Will);
	Aim = string( int(Unit.GetCurrentStat( eStat_Offense )) ) $ GetStatBoostString(ImplantToAdd, ImplantToRemove, eStat_Offense);
	Health = string( int(Unit.GetCurrentStat( eStat_HP )) ) $ GetStatBoostString(ImplantToAdd, ImplantToRemove, eStat_HP);
	Mobility = string( int(Unit.GetCurrentStat( eStat_Mobility )) ) $ GetStatBoostString(ImplantToAdd, ImplantToRemove, eStat_Mobility);
	Tech = string( int(Unit.GetCurrentStat( eStat_Hacking )) ) $ GetStatBoostString(ImplantToAdd, ImplantToRemove, eStat_Hacking);

	if(Unit.IsPsiOperative())
		Psi = string( int(Unit.GetCurrentStat( eStat_PsiOffense )) ) $ GetStatBoostString(ImplantToAdd, ImplantToRemove, eStat_PsiOffense);

	SoldierHeader.SetSoldierStats(Will, Aim, Health, Mobility, Tech, Psi);
}

simulated function OnItemSelected(UIList ContainerList, int ItemIndex)
{
	local int SlotIndex;
	local XComGameState_Unit Unit;
	local array<XComGameState_Item> EquippedImplants;
	local StateObjectReference ImplantRef;

	ImplantRef = UIInventory_ListItem(ContainerList.GetItem(ItemIndex)).ItemRef;
	
	if (CanEquipImplant(ImplantRef))
	{
		Unit = WaveCOM_UIArmory_FieldLoadout(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).GetUnit();
		SlotIndex = 0;

		EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
		
		if (XComHQ.bReusePCS)
		{
			// Skip the popups if the continent bonus for reusing upgrades is active
			if (SlotIndex < EquippedImplants.Length)
				ConfirmImplantRemovalCallback('eUIAction_Accept');
			else
				ConfirmImplantInstallCallback('eUIAction_Accept');
		}
		else
		{
			// Unequip previous implant
			if (SlotIndex < EquippedImplants.Length)
				ConfirmImplantRemoval(EquippedImplants[SlotIndex].GetMyTemplate(), UIInventory_ListItem(List.GetSelectedItem()).ItemTemplate);
			else
				ConfirmImplantInstall(UIInventory_ListItem(List.GetSelectedItem()).ItemTemplate);
		}
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function RemoveImplant()
{
	local int SlotIndex;	
	local XComGameState UpdatedState;
	local StateObjectReference UnitRef;
	local XComGameState_Unit UpdatedUnit;
	local array<XComGameState_Item> EquippedImplants;

	UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Personal Combat Sim");

	UnitRef = WaveCOM_UIArmory_FieldLoadout(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).GetUnit().GetReference();
	UpdatedUnit = XComGameState_Unit(UpdatedState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
	EquippedImplants = UpdatedUnit.GetAllItemsInSlot(eInvSlot_CombatSim);

	SlotIndex = 0;

	if(UpdatedUnit.RemoveItemFromInventory(EquippedImplants[SlotIndex], UpdatedState)) 
	{
				
		if (XComHQ.bReusePCS) // Breakthrough research is letting us reuse PCS, so put it back into the inventory
		{
			XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.PutItemInInventory(UpdatedState, EquippedImplants[SlotIndex]);
		}
		else
		{
			UpdatedState.RemoveStateObject(EquippedImplants[SlotIndex].ObjectID); // Combat sims cannot be reused
		}

		`GAMERULES.SubmitGameState(UpdatedState);
	}
	else
		`XCOMHISTORY.CleanupPendingGameState(UpdatedState);
}

simulated function InstallImplant()
{
	local XComGameState UpdatedState;
	local StateObjectReference UnitRef;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState_Item UpdatedImplant;
	local XComGameState_HeadquartersXCom UpdatedHQ;

	UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Install Personal Combat Sim");

	UnitRef = WaveCOM_UIArmory_FieldLoadout(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).GetUnit().GetReference();
	UpdatedHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	UpdatedUnit = XComGameState_Unit(UpdatedState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));

	UpdatedHQ.GetItemFromInventory(UpdatedState, Implants[List.SelectedIndex].GetReference(), UpdatedImplant);
	
	UpdatedUnit.AddItemToInventory(UpdatedImplant, eInvSlot_CombatSim, UpdatedState);
	
	`XEVENTMGR.TriggerEvent('PCSApplied', UpdatedUnit, UpdatedImplant, UpdatedState);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Strategy_UI_PCS_Equip");

	`GAMERULES.SubmitGameState(UpdatedState);
}