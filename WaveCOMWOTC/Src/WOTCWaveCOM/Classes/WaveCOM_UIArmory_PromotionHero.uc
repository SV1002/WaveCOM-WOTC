class WaveCOM_UIArmory_PromotionHero extends UIArmory_PromotionHero;

simulated function RequestPawn(optional Rotator DesiredRotation)
{
}

simulated function PrevSoldier()
{
	// Do not switch soldiers in this screen
}

simulated function NextSoldier()
{
	// Do not switch soldiers in this screen
}

// Modified to not show soldier pawn
simulated function PopulateData()
{
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate ClassTemplate;
	local UIArmory_PromotionHeroColumn Column;
	local string HeaderString, rankIcon, classIcon;
	local int iRank, maxRank;
	local bool bHasColumnAbility, bHighlightColumn;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	
	Unit = GetUnit();
	ClassTemplate = Unit.GetSoldierClassTemplate();

	FactionState = Unit.GetResistanceFaction();
	
	rankIcon = class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), ClassTemplate.DataName);
	classIcon = ClassTemplate.IconImage;

	HeaderString = m_strAbilityHeader;
	if (Unit.GetRank() != 1 && Unit.HasAvailablePerksToAssign())
	{
		HeaderString = m_strSelectAbility;
	}

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (Unit.IsResistanceHero() && !XComHQ.bHasSeenHeroPromotionScreen)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Opened Hero Promotion Screen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenHeroPromotionScreen = true;
		`XEVENTMGR.TriggerEvent('OnHeroPromotionScreen', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	AS_SetRank(rankIcon);
	AS_SetClass(classIcon);
	AS_SetFaction(FactionState.GetFactionIcon());

	AS_SetHeaderData(Caps(FactionState.GetFactionTitle()), Caps(Unit.GetName(eNameType_FullNick)), HeaderString, m_strSharedAPLabel, m_strSoldierAPLabel);
	AS_SetAPData(GetSharedAbilityPoints(), Unit.AbilityPoints);
	AS_SetCombatIntelData(Unit.GetCombatIntelligenceLabel());
	AS_SetPathLabels(m_strBranchesLabel, ClassTemplate.AbilityTreeTitles[0], ClassTemplate.AbilityTreeTitles[1], ClassTemplate.AbilityTreeTitles[2], ClassTemplate.AbilityTreeTitles[3]);

	maxRank = class'X2ExperienceConfig'.static.GetMaxRank();

	for (iRank = 0; iRank < (maxRank - 1); ++iRank)
	{
		Column = Columns[iRank];
		bHasColumnAbility = UpdateAbilityIcons(Column);
		bHighlightColumn = (!bHasColumnAbility && (iRank+1) == Unit.GetRank());

		Column.AS_SetData(bHighlightColumn, m_strNewRank, class'UIUtilities_Image'.static.GetRankIcon(iRank+1, ClassTemplate.DataName), Caps(class'X2ExperienceConfig'.static.GetRankName(iRank+1, ClassTemplate.DataName)));
	}

	HidePreview();
}