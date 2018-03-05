class WaveCOM_XComGameStateContext_HeadquartersOrder extends XComGameStateContext_HeadquartersOrder;

private function CompleteResearch(XComGameState AddToGameState, StateObjectReference TechReference)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local XComGameState_Tech TechState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.TechsResearched.AddItem(TechReference);
		for(idx = 0; idx < XComHQ.Projects.Length; idx++)
		{
			ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
			
			if (ResearchProject != None && ResearchProject.ProjectFocus == TechReference)
			{
				XComHQ.Projects.RemoveItem(ResearchProject.GetReference());
				AddToGameState.RemoveStateObject(ResearchProject.GetReference().ObjectID);

				if (ResearchProject.bProvingGroundProject)
				{
					FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ResearchProject.AuxilaryReference.ObjectID));

					if (FacilityState != none)
					{
						FacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
						FacilityState.BuildQueue.RemoveItem(ResearchProject.GetReference());
					}
				}
				else if (ResearchProject.bShadowProject)
				{
					XComHQ.EmptyShadowChamber(AddToGameState);
				}

				break;
			}
		}
	}

	TechState = XComGameState_Tech(AddToGameState.ModifyStateObject(class'XComGameState_Tech', TechReference.ObjectID));
	TechState.TimesResearched++;
	TechState.TimeReductionScalar = 0;
	TechState.CompletionTime = `GAME.GetGeoscape().m_kDateTime;

	TechState.OnResearchCompleted(AddToGameState);
	
	if (TechState.GetMyTemplate().bProvingGround)
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_ProvingGroundProjectsCompleted');
	else
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_TechsCompleted');

	`XEVENTMGR.TriggerEvent('ResearchCompleted', TechState, ResearchProject, AddToGameState);
}