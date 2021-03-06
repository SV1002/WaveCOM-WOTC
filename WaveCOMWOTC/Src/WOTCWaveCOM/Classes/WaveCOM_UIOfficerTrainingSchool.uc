class WaveCOM_UIOfficerTrainingSchool extends UIOfficerTrainingSchool;

function bool OnUnlockOption(int iOption)
{
	local bool result;
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local StateObjectReference AbilityReference;
	local XComGameState_Player XComPlayer;
	local XComGameState_BattleData BattleData;
	local WaveCOMGameStateContext_UpdateUnit EffectContext;
	local array<XComGameState_Unit> UnitToSyncVis;

	result = super.OnUnlockOption(iOption);

	if (result)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update OTS Entries");

		BattleData = XComGameState_BattleData( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
		XComPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(BattleData.PlayerTurnOrder[0].ObjectID));
		XComPlayer = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', XComPlayer.ObjectID));
		XComPlayer.SoldierUnlockTemplates = XComHQ.SoldierUnlockTemplates;

		`XEVENTMGR.TriggerEvent('ItemConstructionCompleted',,, NewGameState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.GetTeam() == eTeam_XCom && UnitState.IsAlive() && XComHQ.Squad.Find('ObjectID', UnitState.GetReference().ObjectID) != INDEX_NONE && !UnitState.bRemovedFromPlay)
			{
				EffectContext = class'WaveCOMGameStateContext_UpdateUnit'.static.CreateChangeStateUU("Clean Unit State", UnitState);
				NewGameState = EffectContext.GetGameState();
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				`log("Cleaning and readding Abilities",, 'WaveCOM');
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
	}

	return result;
}

defaultproperties
{
	bConsumeMouseEvents = true;
}