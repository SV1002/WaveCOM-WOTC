class WaveCOM_UIPsiTraining extends UIArmory_PromotionHero config(WaveCOM);

var config array<int> InitialPsiCost;

var config array<int> PsiAbilityCost;
var config array<int> PsiAbilityRankCostIncrease;
var config int PsiAbilityCostIncreasePerTotalAbility;

simulated function InitPromotion(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	local UIArmory_PromotionHeroColumn Column;
	local XComGameState_Unit Unit; // bsg-nlong (1.25.17): Used to determine which column we should start highlighting

	// If the AfterAction screen is running, let it position the camera
	AfterActionScreen = UIAfterAction(Movie.Stack.GetScreen(class'UIAfterAction'));
	if (AfterActionScreen != none)
	{
		bAfterActionPromotion = true;
		PawnLocationTag = AfterActionScreen.GetPawnLocationTag(UnitRef, "Blueprint_AfterAction_HeroPromote");
		CameraTag = AfterActionScreen.GetPromotionBlueprintTag(UnitRef);
		DisplayTag = name(AfterActionScreen.GetPromotionBlueprintTag(UnitRef));
	}
	else
	{
		CameraTag = string(default.DisplayTag);
		DisplayTag = default.DisplayTag;
	}

	// Don't show nav help during tutorial, or during the After Action sequence.
	bUseNavHelp = class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory') || Movie.Pres.ScreenStack.IsInStack(class'UIAfterAction');

	super(UIArmory_Promotion).InitArmory(UnitRef, , , , , , bInstantTransition);
	
	Column = Spawn(class'WaveCOM_UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn0';
	Column.InitPromotionHeroColumn(0);
	Columns.AddItem(Column);

	Column = Spawn(class'WaveCOM_UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn1';
	Column.InitPromotionHeroColumn(1);
	Columns.AddItem(Column);

	Column = Spawn(class'WaveCOM_UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn2';
	Column.InitPromotionHeroColumn(2);
	Columns.AddItem(Column);

	Column = Spawn(class'WaveCOM_UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn3';
	Column.InitPromotionHeroColumn(3);
	Columns.AddItem(Column);

	Column = Spawn(class'WaveCOM_UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn4';
	Column.InitPromotionHeroColumn(4);
	Columns.AddItem(Column);

	Column = Spawn(class'WaveCOM_UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn5';
	Column.InitPromotionHeroColumn(5);
	Columns.AddItem(Column);

	Column = Spawn(class'WaveCOM_UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn6';
	Column.InitPromotionHeroColumn(6);
	Columns.AddItem(Column);

	PopulateData();

	DisableNavigation(); // bsg-nlong (1.25.17): This and the column panel will have to use manual naviation, so we'll disable the navigation here

	MC.FunctionVoid("AnimateIn");

	// bsg-nlong (1.25.17): Focus a column so the screen loads with an ability highlighted
	if( `ISCONTROLLERACTIVE )
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
		if( Unit != none )
		{
			m_iCurrentlySelectedColumn = m_iCurrentlySelectedColumn;
		}
		else
		{
			m_iCurrentlySelectedColumn = 0;
		}

		Columns[m_iCurrentlySelectedColumn].OnReceiveFocus();
	}
	// bsg-nlong (1.25.17): end
}

static function int GetNewPsiCost()
{
	local XComGameState_HeadquartersXCom XComHQ;	
	local StateObjectReference UnitRef;
	local XComGameState_Unit UnitState;
	local int NumPsi;
			
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ != none)
	{
		foreach XComHQ.Squad(UnitRef)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState != none && UnitState.IsAlive() && UnitState.IsPsionic())
			{
				NumPsi++;
			}
		}
	}

	NumPsi = min(NumPsi, default.InitialPsiCost.Length - 1);
	return default.InitialPsiCost[NumPsi];
}

simulated function PopulateData()
{
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate ClassTemplate;
	local UIArmory_PromotionHeroColumn Column;
	local string HeaderString, rankIcon, classIcon;
	local int iRank, maxRank;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_HeadquartersXCom XComHQ;
	
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

	AS_SetRank(rankIcon);
	AS_SetClass(classIcon);
	AS_SetFaction(FactionState.GetFactionIcon());

	AS_SetHeaderData(Caps(FactionState.GetFactionTitle()), Caps(Unit.GetName(eNameType_FullNick)), HeaderString, "", Caps(class'UIUtilities_Strategy'.static.GetResourceDisplayName('Supplies', 2)));
	AS_SetAPData(0, XComHQ.GetSupplies()); // Replace with Supplies
	AS_SetCombatIntelData(Caps(class'X2ExperienceConfig'.static.GetRankName(Unit.GetRank(), ClassTemplate.DataName))); // Replace with unit rank
	AS_SetPathLabels(m_strBranchesLabel, ClassTemplate.AbilityTreeTitles[0], ClassTemplate.AbilityTreeTitles[1], ClassTemplate.AbilityTreeTitles[2], ClassTemplate.AbilityTreeTitles[3]);

	maxRank = class'X2ExperienceConfig'.static.GetMaxRank();

	for (iRank = 0; iRank < (maxRank - 1); ++iRank)
	{
		Column = Columns[iRank];
		UpdateAbilityIcons(Column);

		Column.AS_SetData(false, m_strNewRank, class'UIUtilities_Image'.static.GetRankIcon(iRank+1, ClassTemplate.DataName), Caps(class'X2ExperienceConfig'.static.GetRankName(iRank+1, ClassTemplate.DataName)));
	}

	HidePreview();
}

function bool UpdateAbilityIcons(out UIArmory_PromotionHeroColumn Column)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate, NextAbilityTemplate;
	local array<SoldierClassAbilityType> AbilityTree, NextRankTree;
	local XComGameState_Unit Unit;
	local UIPromotionButtonState ButtonState;
	local int iAbility;
	local bool bHasColumnAbility, bConnectToNextAbility;
	local string AbilityName, AbilityIcon, BGColor, FGColor;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Unit = GetUnit();
	AbilityTree = Unit.GetRankAbilities(Column.Rank);

	for (iAbility = 0; iAbility < NUM_ABILITIES_PER_COLUMN; iAbility++)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[iAbility].AbilityName);
		if (AbilityTemplate != none)
		{
			if (Column.AbilityNames.Find(AbilityTemplate.DataName) == INDEX_NONE)
			{
				Column.AbilityNames.AddItem(AbilityTemplate.DataName);
			}

			AbilityName = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(AbilityTemplate.LocFriendlyName);
			AbilityIcon = AbilityTemplate.IconImage;

			if (Unit.HasSoldierAbility(AbilityTemplate.DataName))
			{
				// The ability has been purchased
				ButtonState = eUIPromotionState_Equipped;
				FGColor = class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;
				BGColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
				bHasColumnAbility = true;
			}
			else if(CanPurchaseAbility(Column.Rank, iAbility, AbilityTemplate.DataName))
			{
				// The ability is unlocked and unpurchased, and can be afforded
				ButtonState = eUIPromotionState_Normal;
				FGColor = class'UIUtilities_Colors'.const.PERK_HTML_COLOR;
				BGColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
			}
			else
			{
				// The ability is unlocked and unpurchased, but cannot be afforded
				ButtonState = eUIPromotionState_Normal;
				FGColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
				BGColor = class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;
			}
				
			// Look ahead to the next rank and check to see if the current ability is a prereq for the next one
			// If so, turn on the connection arrow between them
			if (Column.Rank < (class'X2ExperienceConfig'.static.GetMaxRank() - 2))
			{
				bConnectToNextAbility = false;
				NextRankTree = Unit.GetRankAbilities(Column.Rank + 1);
				NextAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(NextRankTree[iAbility].AbilityName);
				if (NextAbilityTemplate.PrerequisiteAbilities.Length > 0 && NextAbilityTemplate.PrerequisiteAbilities.Find(AbilityTemplate.DataName) != INDEX_NONE)
				{
					bConnectToNextAbility = true;
				}
			}

			Column.SetAvailable(true);

			Column.AS_SetIconState(iAbility, false, AbilityIcon, AbilityName, ButtonState, FGColor, BGColor, bConnectToNextAbility);
		}
		else
		{
			Column.AbilityNames.AddItem(''); // Make sure we add empty spots to the name array for getting ability info
		}
	}

	// bsg-nlong (1.25.17): Select the first available/visible ability in the column
	while(`ISCONTROLLERACTIVE && !Column.AbilityIcons[Column.m_iPanelIndex].bIsVisible)
	{
		Column.m_iPanelIndex +=1;
		if( Column.m_iPanelIndex >= Column.AbilityIcons.Length )
		{
			Column.m_iPanelIndex = 0;
		}
	}
	// bsg-nlong (1.25.17): end

	return bHasColumnAbility;
}

function PreviewAbility(int Rank, int Branch)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate, PreviousAbilityTemplate;
	local XComGameState_Unit Unit;
	local array<SoldierClassAbilityType> AbilityTree;
	local string AbilityIcon, AbilityName, AbilityDesc, AbilityHint, AbilityCost, CostLabel, APLabel, PrereqAbilityNames;
	local name PrereqAbilityName;

	Unit = GetUnit();
	
	// Ability cost is always displayed, even if the rank hasn't been unlocked yet
	CostLabel = m_strCostLabel;
	AbilityCost = string(GetAbilityPrice(Rank));
	APLabel = class'UIUtilities_Strategy'.static.GetResourceDisplayName('Supplies', GetAbilityPrice(Rank));
	if (!CanAffordAbility(Rank, Branch))
	{
		AbilityCost = class'UIUtilities_Text'.static.GetColoredText(AbilityCost, eUIState_Bad);
	}
	
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTree = Unit.GetRankAbilities(Rank);
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[Branch].AbilityName);

	if (AbilityTemplate != none)
	{
		AbilityIcon = AbilityTemplate.IconImage;
		AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for " $ AbilityTemplate.DataName);
		AbilityDesc = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, Unit) : ("Missing 'LocLongDescription' for " $ AbilityTemplate.DataName);
		AbilityHint = "";

		// Don't display cost information if the ability has already been purchased
		if (Unit.HasSoldierAbility(AbilityTemplate.DataName))
		{
			CostLabel = "";
			AbilityCost = "";
			APLabel = "";
		}
		else if (AbilityTemplate.PrerequisiteAbilities.Length > 0)
		{
			// Look back to the previous rank and check to see if that ability is a prereq for this one
			// If so, display a message warning the player that there is a prereq
			foreach AbilityTemplate.PrerequisiteAbilities(PrereqAbilityName)
			{
				PreviousAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(PrereqAbilityName);
				if (PreviousAbilityTemplate != none && !Unit.HasSoldierAbility(PrereqAbilityName))
				{
					if (PrereqAbilityNames != "")
					{
						PrereqAbilityNames $= ", ";
					}
					PrereqAbilityNames $= PreviousAbilityTemplate.LocFriendlyName;
				}
			}
			PrereqAbilityNames = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(PrereqAbilityNames);

			if (PrereqAbilityNames != "")
			{
				AbilityDesc = class'UIUtilities_Text'.static.GetColoredText(m_strPrereqAbility @ PrereqAbilityNames, eUIState_Warning) $ "\n" $ AbilityDesc;
			}
		}
	}
	else
	{
		AbilityIcon = "";
		AbilityName = string(AbilityTree[Branch].AbilityName);
		AbilityDesc = "Missing template for ability '" $ AbilityTree[Branch].AbilityName $ "'";
		AbilityHint = "";
	}
	
	AS_SetDescriptionData(AbilityIcon, AbilityName, AbilityDesc, AbilityHint, CostLabel, AbilityCost, APLabel);
}

function bool CanAffordAbility(int Rank, int Branch)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int AbilityCost;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	AbilityCost = GetAbilityPrice(Rank);
	if (AbilityCost <= XComHQ.GetSupplies())
	{
		return true;
	}

	return false;
}

function bool CanPurchaseAbility(int Rank, int Branch, name AbilityName)
{
	local XComGameState_Unit UnitState;

	UnitState = GetUnit();		
	return (CanAffordAbility(Rank, Branch) && UnitState.MeetsAbilityPrerequisites(AbilityName));
}

simulated function ConfirmAbilitySelection(int Rank, int Branch)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> AbilityTree;
	local int SupplyCost;
	local XComGameState_HeadquartersXCom XComHQ;

	PendingRank = Rank;
	PendingBranch = Branch;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	DialogData.eType = eDialog_Alert;
	DialogData.bMuteAcceptSound = true;
	DialogData.strTitle = m_strConfirmAbilityTitle;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNO;
	DialogData.fnCallback = ComfirmAbilityCallback;

	AbilityTree = GetUnit().GetRankAbilities(Rank);
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[Branch].AbilityName);
	SupplyCost = GetAbilityPrice(Rank);

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = AbilityTemplate.LocFriendlyName;
	LocTag.IntValue0 = SupplyCost;

	if (XComHQ != none && XComHQ.GetSupplies() < SupplyCost)
	{
		DialogData.strCancel = "";
		DialogData.fnCallback = "";
		DialogData.strText = "Not enough supplies to learn this ability (Need" @ SupplyCost $ ")";
	}
	else
	{
		DialogData.strText = Repl(`XEXPAND.ExpandString(m_strConfirmAbilityText), m_strAPLabel, class'UIX2SimpleScreen'.default.m_strSupplies);
	}

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function int GetAbilityPrice(int Rank)
{
	local int self_ability_count, other_ability_count;
	local XComGameState_HeadquartersXCom XComHQ;	
	local StateObjectReference UnitRef;
	local XComGameState_Unit UnitState;
			
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ != none)
	{
		foreach XComHQ.Squad(UnitRef)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState != none && UnitState.IsAlive() && UnitState.IsPsionic()) // Unit is on board
			{
				other_ability_count += UnitState.m_SoldierProgressionAbilties.Length;
			}
		}
	}
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
	
	self_ability_count = UnitState.m_SoldierProgressionAbilties.Length;

	return PsiAbilityCost[min(self_ability_count, PsiAbilityCost.Length - 1)] + (other_ability_count * PsiAbilityCostIncreasePerTotalAbility) + PsiAbilityRankCostIncrease[min(Rank, PsiAbilityRankCostIncrease.Length - 1)];
}

simulated function ComfirmAbilityCallback(name Action)
{
	local XComGameStateHistory History;
	local bool bSuccess;
	local XComGameState UpdateState;
	local XComGameState_Unit UpdatedUnit;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_HeadquartersXCom XComHQ;
	local ArtifactCost Resources;
	local StrategyCost DeployCost;
	local array<StrategyCostScalar> EmptyScalars;

	if(Action == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Soldier Promotion");
		UpdateState = History.CreateNewGameState(true, ChangeContainer);
		
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		UpdatedUnit = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', GetUnit().ObjectID));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		bSuccess = UpdatedUnit.BuySoldierProgressionAbility(UpdateState, PendingRank, PendingBranch);

		if(bSuccess)
		{
			UpdatedUnit.RankUpSoldier(UpdateState, 'PsiOperative');
			Resources.ItemTemplateName = 'Supplies';
			Resources.Quantity = GetAbilityPrice(PendingRank);
			DeployCost.ResourceCosts.AddItem(Resources);
			XComHQ.PayStrategyCost(UpdateState, DeployCost, EmptyScalars);
			`XEVENTMGR.TriggerEvent('PsiTrainingUpdate',,, UpdateState);

			`GAMERULES.SubmitGameState(UpdateState);

			Header.PopulateData();
			PopulateData();
		}
		else
			History.CleanupPendingGameState(UpdateState);

		Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
	}
	else 	// if we got here it means we were going to upgrade an ability, but then we decided to cancel
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
	}
}

simulated function AS_SetAPData(int TeamAPValue, int SoldierAPValue)
{
	MC.BeginFunctionOp("SetAPData");
	MC.QueueString("");
	MC.QueueString(string(SoldierAPValue));
	MC.EndOp();
}

simulated function AS_SetCombatIntelData( string Value )
{
	MC.BeginFunctionOp("SetCombatIntelData");
	MC.QueueString(class'UIAlert'.default.m_strPsiTrainingCompleteRank);
	MC.QueueString(Value);
	MC.EndOp();
}

function bool IsAbilityLocked(int Rank)
{
	return false;
}

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
