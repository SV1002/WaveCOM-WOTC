class WaveCOM_UISoldierBondConfirm extends UISoldierBondConfirmScreen;

simulated function OnInit()
{
	local string classIcon1, rankIcon1, classIcon2, rankIcon2;
	local int iRank1, iRank2, i;
	local X2SoldierClassTemplate SoldierClass1, SoldierClass2;
	local SoldierBond BondData;
	local X2DataTemplate BondedAbilityTemplate;
	local UISummary_Ability Data;
	local StateObjectReference unitRef;
	local X2AbilityTemplateManager AbilityTemplateMan;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition TestCondition;
	local X2Condition_Bondmate BondmateCondition;

	super(UIScreen).OnInit();

	ConfirmButton = Spawn(class'UIButton', self);
	ConfirmButton.InitButton('confirmButtonMC', , ConfirmClicked);
	if( `ISCONTROLLERACTIVE )
		ConfirmButton.Hide(); //Using the bottom nav help instead.

	iRank1 = Soldier1State.GetRank();

	SoldierClass1 = Soldier1State.GetSoldierClassTemplate();

	rankIcon1 = class'UIUtilities_Image'.static.GetRankIcon(iRank1, SoldierClass1.DataName);
	classIcon1 = SoldierClass1.IconImage;

	Soldier1State.HasSoldierBond(unitRef, BondData);


	iRank2 = Soldier2State.GetRank();

	SoldierClass2 = Soldier2State.GetSoldierClassTemplate();

	rankIcon2 = class'UIUtilities_Image'.static.GetRankIcon(iRank2, SoldierClass2.DataName);
	classIcon2 = SoldierClass2.IconImage;

	SetBondData(BondData.BondLevel + 1, rankIcon1, classIcon1, SoldierClass1.DisplayName, Caps(Soldier1State.GetName(eNameType_Full)),
		rankIcon2, classIcon2, SoldierClass2.DisplayName, Caps(Soldier2State.GetName(eNameType_Full)), m_strBenefits);

	i = 0;
	AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach AbilityTemplateMan.IterateTemplates(BondedAbilityTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(BondedAbilityTemplate);

		BondmateCondition = none;
		foreach AbilityTemplate.AbilityTargetConditions(TestCondition)
		{
			BondmateCondition = X2Condition_Bondmate(TestCondition);

			if( BondmateCondition != none )
			{
				break;
			}
		}

		if( BondmateCondition == none )
		{
			foreach AbilityTemplate.AbilityShooterConditions(TestCondition)
			{
				BondmateCondition = X2Condition_Bondmate(TestCondition);

				if( BondmateCondition != none )
				{
					break;
				}
			}
		}

		if( BondmateCondition != none && 
			(BondmateCondition.MinBondLevel == BondData.BondLevel + 1) && 
		   BondmateCondition.RequiresAdjacency == EAR_AnyAdjacency )
		{
			Data = AbilityTemplate.GetUISummary_Ability();

			SetBenefitRow(i, Data.Name, Data.Description);
			++i;
		}
	}

	MC.BeginFunctionOp("SetConfirmButton");
	MC.QueueString(m_strConfirm);
	MC.EndOp();

	AnimateIn();
	RealizeNavHelp();
}

simulated function KickOffAutoGen()
{
	// NO PHOTOS ALLOWED
}

simulated function MakePosterCallback(Name Action)
{
	// REALLY
}

function ConfirmClicked(UIButton Button)
{
	local XComGameState NewGameState;
	local SoldierBond BondData;
	local XComGameState_HeadquartersXCom XComHQ;
	local ArtifactCost Resources;
	local array<StrategyCostScalar> EmptyScalars;
	local StrategyCost DeployCost;
		
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Confirm Soldier Bond Project");
	Soldier1State = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldier1State.ObjectID));
	Soldier2State = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldier2State.ObjectID));

	Soldier1State.GetBondData(Soldier2State.GetReference(), BondData);
	if (BondData.BondLevel == 0) // If there is no bond between these units yet, give them one without doing the project
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("SoldierBond1_Confirm");

		class'X2StrategyGameRulesetDataStructures'.static.SetBondLevel(Soldier1State, Soldier2State, 1);

		// Reset the cohesion of the new bondmates with all other soldiers to 0
		class'X2StrategyGameRulesetDataStructures'.static.ResetNotBondedSoldierCohesion(NewGameState, Soldier1State, Soldier2State);

		`XEVENTMGR.TriggerEvent( 'BondCreated', Soldier1State, Soldier2State, NewGameState );
	}
	else // Consume supplies and improve bond
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("SoldierBond2_Confirm");

		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		Resources.ItemTemplateName = 'Supplies';
		Resources.Quantity = class'WaveCOM_UISoldierBonds'.default.BondCost[BondData.BondLevel];
		DeployCost.ResourceCosts.AddItem(Resources);
		XComHQ.PayStrategyCost(NewGameState, DeployCost, EmptyScalars);

		class'X2StrategyGameRulesetDataStructures'.static.SetBondLevel(Soldier1State, Soldier2State, BondData.BondLevel + 1);

		`XEVENTMGR.TriggerEvent('BondLevelUpComplete', Soldier1State, Soldier2State, NewGameState);
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	CloseScreen();
}