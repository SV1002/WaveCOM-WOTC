class WaveCOM_UIChooseProvingGrounds extends UIChooseProject;

simulated function array<Commodity> ConvertTechsToCommodities()
{
	local XComGameState_Tech TechState;
	local int iProject;
	local bool bPausedProject;
	local array<Commodity> arrCommodoties;
	local Commodity TechComm;
	local StrategyCost EmptyCost;
	local StrategyRequirement EmptyReqs;

	m_arrRefs.Remove(0, m_arrRefs.Length);
	m_arrRefs = GetProjects();
	m_arrRefs.Sort(SortProjectsTime);
	m_arrRefs.Sort(SortProjectsTier);
	m_arrRefs.Sort(SortProjectsPriority);
	m_arrRefs.Sort(SortProjectsCanResearch);

	for (iProject = 0; iProject < m_arrRefs.Length; iProject++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iProject].ObjectID));
		bPausedProject = XComHQ.HasPausedProject(m_arrRefs[iProject]);
		
		TechComm.Title = TechState.GetDisplayName();

		if (bPausedProject)
		{
			TechComm.Title = TechComm.Title @ m_strPaused;
		}
		TechComm.Image = TechState.GetImage();
		TechComm.Desc = TechState.GetSummary();
		TechComm.OrderHours = XComHQ.GetResearchHours(m_arrRefs[iProject]);
		TechComm.bTech = true;

		if (bPausedProject)
		{
			TechComm.Cost = EmptyCost;
			TechComm.Requirements = EmptyReqs;
		}
		else
		{
			TechComm.Cost = class'WaveCOM_UIChooseResearch'.static.PatchProjectCostByLength(TechState, XComHQ.ProvingGroundPercentDiscount);
			TechComm.Requirements = GetBestStrategyRequirementsForUI(TechState.GetMyTemplate());
			TechComm.CostScalars = XComHQ.ProvingGroundCostScalars;
			TechComm.DiscountPercent = XComHQ.ProvingGroundPercentDiscount;
		}

		arrCommodoties.AddItem(TechComm);
	}

	return arrCommodoties;
}

function bool OnTechTableOption(int iOption)
{		
	if (!XComHQ.HasPausedProject(m_arrRefs[iOption]) && 
		!XComHQ.MeetsRequirmentsAndCanAffordCost(arrItems[iOption].Requirements, arrItems[iOption].Cost, arrItems[iOption].CostScalars, arrItems[iOption].DiscountPercent))
	{
		//SOUND().PlaySFX(SNDLIB().SFX_UI_No);
		return false;
	}
	
	StartNewProvingGroundProjectX(iOption);
	
	return true;
}

function StartNewProvingGroundProjectX(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local StateObjectReference TechRef;

	TechRef = m_arrRefs[iOption];

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Proving Ground Project");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			
	FacilityState = XComHQ.GetFacilityByName('ProvingGround');
	FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));

	ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectProvingGround'));
	ProvingGroundProject.SetProjectFocus(TechRef, NewGameState, FacilityState.GetReference());
	ProvingGroundProject.SavedDiscountPercent = XComHQ.ProvingGroundPercentDiscount; // Save the current discount in case the project needs a refund
	XComHQ.Projects.AddItem(ProvingGroundProject.GetReference());
	
	XComHQ.PayStrategyCost(NewGameState, arrItems[iOption].Cost, arrItems[iOption].CostScalars, arrItems[iOption].DiscountPercent);

	//Add proving ground project to the build queue
	FacilityState.BuildQueue.AddItem(ProvingGroundProject.GetReference());
			
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	ProvingGroundProject.OnProjectCompleted();
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();
}

simulated function RegenerateList()
{
	GetItems();
	PopulateData();
}