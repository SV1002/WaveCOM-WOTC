class WaveCOM_UIChooseClass extends UIChooseClass;

simulated function array<Commodity> ConvertClassesToCommodities()
{
	local X2SoldierClassTemplate ClassTemplate;
	local int iClass;
	local array<Commodity> arrCommodoties;
	local Commodity ClassComm;
	
	m_arrClasses.Remove(0, m_arrClasses.Length);
	m_arrClasses = GetClasses();
	m_arrClasses.Sort(SortClassesByName);

	for (iClass = 0; iClass < m_arrClasses.Length; iClass++)
	{
		ClassTemplate = m_arrClasses[iClass];
		
		ClassComm.Title = ClassTemplate.DisplayName;
		ClassComm.Image = ClassTemplate.IconImage;
		ClassComm.Desc = ClassTemplate.ClassSummary;
		ClassComm.OrderHours = 0;

		arrCommodoties.AddItem(ClassComm);
	}

	return arrCommodoties;
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_Item InventoryItem;
	local array<XComGameState_Item> InventoryItems;
	local XGItem ItemVisualizer;

	if (m_UnitRef.ObjectID <= 0)
	{
		return false;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Training new rookie");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', m_UnitRef.ObjectID));

	NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	class'WaveCOM_UIArmory_FieldLoadout'.static.CleanUpStats(NewGameState, UnitState);
	UnitState.RankUpSoldier(NewGameState, m_arrClasses[iOption].DataName);
	InventoryItems = UnitState.GetAllInventoryItems(NewGameState);

	foreach InventoryItems(InventoryItem)
	{
		NewXComHQ.PutItemInInventory(NewGameState, InventoryItem);
		UnitState.RemoveItemFromInventory(InventoryItem, NewGameState);
		ItemVisualizer = XGItem(`XCOMHISTORY.GetVisualizer(InventoryItem.GetReference().ObjectID));
		ItemVisualizer.Destroy();
		`XCOMHISTORY.SetVisualizer(InventoryItem.GetReference().ObjectID, none);
	}
	UnitState.ApplySquaddieLoadout(NewGameState, NewXComHQ);
	UnitState.ApplyBestGearLoadout(NewGameState); // Make sure the squaddie has the best gear available

	UnitState.ValidateLoadout(NewGameState);
	if (UnitState.GetSoldierRank() < UnitState.StartingRank)
	{
		UnitState.bRankedUp = false; // Keep leveling up until it catches up to the appropriate rank.
	}
		
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");

	return true;
}

defaultproperties
{
	bConsumeMouseEvents = true;
}
