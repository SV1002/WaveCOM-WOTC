class WaveCOM_UIChooseResearch extends UIChooseResearch;

struct DynamicUpgradeData
{
	var name UpgradeName;
	var int SupplyIncrement;
	var int SupplyMax;
	var int FirstIncrease;
	var bool ScaleWithSquadSize;
	var bool IgnoreDiscounts;
};

// Add discounts for inspired techs.
simulated function array<Commodity> ConvertTechsToCommodities()
{
	local X2TechTemplate TechTemplate;
	local XComGameState_Tech TechState;
	local int iTech;
	local bool bPausedProject;
	local bool bCompletedTech;
	local array<Commodity> arrCommodoties;
	local Commodity TechComm;
	local StrategyCost EmptyCost;
	local StrategyRequirement EmptyReqs;
	local string TechSummary;

	m_arrRefs.Remove(0, m_arrRefs.Length);
	m_arrRefs = GetTechs();
	m_arrRefs.Sort(SortTechsTime);
	m_arrRefs.Sort(SortTechsTier);
	m_arrRefs.Sort(SortTechsPriority);
	m_arrRefs.Sort(SortTechsInspired);
	m_arrRefs.Sort(SortTechsBreakthrough);
	m_arrRefs.Sort(SortTechsInstant);
	m_arrRefs.Sort(SortTechsCanResearch);

	for( iTech = 0; iTech < m_arrRefs.Length; iTech++ )
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iTech].ObjectID));
		TechTemplate = TechState.GetMyTemplate();
		bPausedProject = XComHQ.HasPausedProject(m_arrRefs[iTech]);
		bCompletedTech = XComHQ.TechIsResearched(m_arrRefs[iTech]);
		
		TechComm.Title = TechState.GetDisplayName();

		if (TechState.bBreakthrough)
		{
			TechComm.Title = TechComm.Title @ m_strBreakthrough;
		}
		else if (TechState.bInspired)
		{
			TechComm.Title = TechComm.Title @ m_strInspired;
		}

		TechComm.Image = TechState.GetImage();

		TechSummary = TechState.GetSummary();
		if (TechTemplate.GetValueFn != none)
		{
			TechSummary = Repl(TechSummary, "%VALUE", TechTemplate.GetValueFn());
		}

		TechComm.Desc = TechSummary;
		TechComm.OrderHours = XComHQ.GetResearchHours(m_arrRefs[iTech]);
		TechComm.bTech = true;
		
		if (bPausedProject || (bCompletedTech && !TechTemplate.bRepeatable))
		{
			TechComm.Cost = EmptyCost;
			TechComm.Requirements = EmptyReqs;
		}
		else
		{
			TechComm.Cost = PatchProjectCostByLength(TechState);
			TechComm.Requirements = GetBestStrategyRequirementsForUI(TechTemplate);
			TechComm.CostScalars = XComHQ.ResearchCostScalars;
			if (TechState.bInspired)
			{
				TechComm.DiscountPercent += class'X2DownloadableContentInfo_WOTCWaveCOM'.default.InspireResearchCostDiscount;
			}
		}

		arrCommodoties.AddItem(TechComm);
	}

	return arrCommodoties;
}

simulated function RegenerateList()
{
	GetItems();
	PopulateData();
}

static function StrategyCost PatchProjectCostByLength(XComGameState_Tech TechState, optional float ProvingGroundsDiscount=0.00f)
{
	local StrategyCost NewCost;
	local X2TechTemplate Tech;

	Tech = TechState.GetMyTemplate();
	NewCost = Tech.Cost;
	class'X2DownloadableContentInfo_WOTCWaveCOM'.static.AddSupplyCost(NewCost.ResourceCosts, 
		Round(Tech.PointsToComplete * class'X2DownloadableContentInfo_WOTCWaveCOM'.default.WaveCOMResearchSupplyCostRatio * 
		(Tech.bBreakthrough ? class'X2DownloadableContentInfo_WOTCWaveCOM'.default.WaveCOMBreakthroughMultiplier: 1.0)));

	UpdateResearchCostDynamic(TechState, NewCost, ProvingGroundsDiscount);

	return NewCost;
}

static function UpdateResearchCostDynamic(XComGameState_Tech TechState, out StrategyCost Costs, optional float ProvingGroundsDiscount=0.00f)
{
	local int UpgradeIndex, StackCount, CostIncrease;
	local DynamicUpgradeData CostData;
	local X2TechTemplate Tech;

	UpgradeIndex = class'X2DownloadableContentInfo_WOTCWaveCOM'.default.RepeatableUpgradeCosts.Find('UpgradeName', TechState.GetMyTemplateName());

	if (UpgradeIndex != INDEX_NONE)
	{
		Tech = TechState.GetMyTemplate();
		CostData = class'X2DownloadableContentInfo_WOTCWaveCOM'.default.RepeatableUpgradeCosts[UpgradeIndex];

		if (CostData.ScaleWithSquadSize)
		{
			StackCount = class'UIUtilities_Strategy'.static.GetXComHQ().Squad.Length;
		}
		else
		{
			StackCount = TechState.TimesResearched;
		}

		if (StackCount > CostData.FirstIncrease)
		{
			StackCount = StackCount - CostData.FirstIncrease;
			CostIncrease = Min(Round(CostData.SupplyIncrement * StackCount), CostData.SupplyMax);
			if (CostData.IgnoreDiscounts && ProvingGroundsDiscount > 0)
			{
				if (Tech.bProvingGround)
				{
					CostIncrease *= (100.0f / (100.0f - ProvingGroundsDiscount));
				}
			}
			class'X2DownloadableContentInfo_WOTCWaveCOM'.static.AddSupplyCost(Costs.ResourceCosts, CostIncrease);
		}
	}
}

function bool OnTechTableOption(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;

	TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iOption].ObjectID));

	if(!XComHQ.HasPausedProject(m_arrRefs[iOption]) && !XComHQ.MeetsRequirmentsAndCanAffordCost(arrItems[iOption].Requirements, arrItems[iOption].Cost, arrItems[iOption].CostScalars, arrItems[iOption].DiscountPercent))
	{
		//SOUND().PlaySFX(SNDLIB().SFX_UI_No);
		return false;
	}

	if(bShadowChamber)
	{
		if(XComHQ.HasActiveShadowProject())
		{
			ConfirmSwitchShadowProjectPopup(m_arrRefs[iOption]);
			return false;
		}
		else
		{
			ConfirmStartShadowProjectPopup(m_arrRefs[iOption]);
			return false;
		}
	}
	else
	{
		if(XComHQ.HasResearchProject())
		{
			ConfirmSwitchResearchPopup(m_arrRefs[iOption]);
			return false;
		}
		else
		{
			if ((!TechState.IsInstant() && !TechState.GetMyTemplate().bAutopsy) || XComHQ.GetObjectiveStatus('T0_M6_WelcomeToLabsPt2') == eObjectiveState_InProgress)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Choose Research Event");
				`XEVENTMGR.TriggerEvent('ChooseResearch', TechState, TechState, NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}

			SetNewResearchProject(iOption);
		}
	}
	
	return true;
}

function SetNewResearchProject(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Research Project");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	
	ResearchProject = XComHQ.GetPausedProject(m_arrRefs[iOption]);

	if(ResearchProject != none)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', ResearchProject.ObjectID));
		ResearchProject.bForcePaused = false;
	}
	else
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectResearch'));
		ResearchProject.SetProjectFocus(m_arrRefs[iOption]);
		XComHQ.Projects.AddItem(ResearchProject.GetReference());
		XComHQ.PayStrategyCost(NewGameState, arrItems[iOption].Cost, arrItems[iOption].CostScalars, arrItems[iOption].DiscountPercent);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	ResearchProject.OnProjectCompleted(); // All researchs are instant
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();
}