class WaveCOMSoldierContinentBonusUnlockTemplate extends X2SoldierUnlockTemplate;

// WOTC Update: Now applies strategy cards instead

var name StrategyBonus;
var name ActivateSitRep;

function OnSoldierUnlockPurchased(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local X2StrategyCardTemplate MutatorTemplate;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_StrategyCard PolicyState;
	local XComGameState_BattleData BattleData;

	History = `XCOMHISTORY;

	if (ActivateSitRep != '')
	{
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		`assert( BattleData != none );

		BattleData.ActiveSitReps.AddItem( ActivateSitRep );
	}

	if (StrategyBonus != '')
	{
		MutatorTemplate = X2StrategyCardTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(StrategyBonus));
	}
	if (MutatorTemplate != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject( class'XComGameState_HeadquartersResistance', ResHQ.ObjectID ) );

		PolicyState = MutatorTemplate.CreateInstanceFromTemplate( NewGameState );

		ResHQ.WildCardSlots.AddItem( PolicyState.GetReference() );

		PolicyState.bDrawn = true;

		if (MutatorTemplate.OnActivatedFn != none)
		{
			MutatorTemplate.OnActivatedFn(NewGameState, XComHQ.GetReference(), false);
		}
	}
}

DefaultProperties
{
	bAllClasses = true
}