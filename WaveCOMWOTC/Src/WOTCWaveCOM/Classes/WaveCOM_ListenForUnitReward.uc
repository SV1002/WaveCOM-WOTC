class WaveCOM_ListenForUnitReward extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( AddResearchEvent() );

	return Templates;
}

static function X2EventListenerTemplate AddResearchEvent()
{	
	local X2EventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'WaveCOMResearchComplete');
	Template.RegisterInTactical = true;
	Template.AddEvent('ResearchCompleted', ResearchComplete);

	return Template;
}

function EventListenerReturn ResearchComplete(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Tech TechState;
	local XComGameState_Unit StrategyUnit;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	local TDialogueBoxData  kDialogData;

	TechState = XComGameState_Tech(EventData);

	`log("Research Complete",, 'UnitProject');

	if (TechState != none && TechState.UnitRewardRef.ObjectID > 0)
	{
		`log("Tech contains unit",, 'UnitProject');
		StrategyUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TechState.UnitRewardRef.ObjectID));
		if (StrategyUnit != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add reward unit to squad");
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			if (XComHQ != none)
			{
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.Squad.AddItem(StrategyUnit.GetReference());
				XComHQ.AddToCrew(NewGameState, StrategyUnit);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			StrategyUnit = class'WaveCOM_UILoadoutButton'.static.AddStrategyUnitToBoard(StrategyUnit, `XCOMHISTORY);
			if (StrategyUnit == none)
			{
				kDialogData.eType = eDialog_Alert;
				kDialogData.strTitle = "Failed to spawn unit";
				kDialogData.strText = "Unable to spawn the requested unit, there might be no room on the spawn zone. Move the unit away and Click purchase soldier to fix";

				kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

				`PRES.UIRaiseDialog(kDialogData);
			}
		}
		`XEVENTMGR.TriggerEvent('UpdateDeployCost');
		`XEVENTMGR.TriggerEvent('UpdateResearchCost');
	}

	return ELR_NoInterrupt;
}

defaultproperties
{
}