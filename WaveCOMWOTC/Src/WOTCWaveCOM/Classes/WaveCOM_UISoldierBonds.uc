class WaveCOM_UISoldierBonds extends UISoldierBondScreen config(WaveCOM);

var config array<int> BondCost;

var UILargeButton UpgradeBond;

simulated function OnConfirmBond(UISoldierBondListItem BondListItem)
{
	local XComGameStateHistory History;
	local XComGameState_Unit SelectedUnitState, BondUnitState;

	History = `XCOMHISTORY;
	
	if (BondListItem != none)
	{
		BondUnitState = XComGameState_Unit(History.GetGameStateForObjectID(BondListItem.ScreenUnitRef.ObjectID));
		SelectedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(BondListItem.UnitRef.ObjectID));

		if(class'X2StrategyGameRulesetDataStructures'.static.CanHaveBondAtLevel(BondUnitState, SelectedUnitState, 1))
		{
			UISoldierBondConfirm(BondUnitState, SelectedUnitState);
		}
	}
}

function UISoldierBondConfirm(XComGameState_Unit UnitRef1, XComGameState_Unit UnitRef2, optional XComGameState_StaffSlot SlotState)
{
	local WaveCOM_UISoldierBondConfirm TempScreen;
	if (Movie.Pres.ScreenStack.IsNotInStack(class'WaveCOM_UISoldierBondConfirm'))
	{
		TempScreen = Screen.Spawn(class'WaveCOM_UISoldierBondConfirm', Screen);
		TempScreen.InitBondConfirm(UnitRef1, UnitRef2, SlotState);
		Movie.Pres.ScreenStack.Push(TempScreen);
	}
}


simulated function OnReceiveFocus()
{
	super(UIScreen).OnReceiveFocus();

	RefreshHeader();
	RefreshData();
}

simulated function OnLoseFocus()
{
	super(UIScreen).OnLoseFocus();
}


simulated function UpdateNavHelp()
{
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_KEY_HOME :
			// Consume input to prevent referencing HQPRES
			break;
		default:
			bHandled = false;
			break;
	}
	
	return bHandled || super.OnUnrealCommand(cmd, arg);
}

function UILargeButton FindOrCreateUpgradeButton()
{
	if (UpgradeBond == none)
	{
		UpgradeBond = Spawn(class'UILargeButton', self);
		UpgradeBond.InitLargeButton('btnImproveBond', "Costs X Supplies", "Improve Bond", OnImproveBondClicked);
		UpgradeBond.SetPosition(1235, 265);
		UpgradeBond.AnimateIn(0);

	}
	return UpgradeBond;
}

function OnImproveBondClicked(UIButton Button)
{
	local XComGameState_Unit Unit, Bondmate;
	local XComGameState_HeadquartersXCom XComHQ;
	local TDialogueBoxData  kDialogData;
	local SoldierBond BondData;
	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));
		
		if (class'X2StrategyGameRulesetDataStructures'.static.CanHaveBondAtLevel(Unit, Bondmate, BondData.BondLevel + 1))
		{
			if (XComHQ.GetSupplies() < BondCost[BondData.BondLevel])
			{
				kDialogData.eType = eDialog_Alert;
				kDialogData.strTitle = "Not enough supplies!";
				kDialogData.strText = "You need" @ BondCost[BondData.BondLevel] - XComHQ.GetSupplies() @ "more supplies to improve this bond.";

				kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

				`PRES.UIRaiseDialog(kDialogData);
			}
			else
			{
				// YAY BONDING
				UISoldierBondConfirm(Unit, Bondmate);
			}
		}
		else
		{
			kDialogData.eType = eDialog_Alert;
			kDialogData.strTitle = "Bond target cohesion not reached!";
			kDialogData.strText = "How do you even click the hidden button?";

			kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

			`PRES.UIRaiseDialog(kDialogData);
		}
	}
	else
	{
		kDialogData.eType = eDialog_Alert;
		kDialogData.strTitle = "No bond target to improve";
		kDialogData.strText = "How do you even click the hidden button?";

		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;

		`PRES.UIRaiseDialog(kDialogData);
	}
}

function RefreshHeader()
{	
	local XComGameState_Unit Unit, Bondmate;
	local string classIcon, rankIcon, flagIcon;
	local int iRank;
	local X2SoldierClassTemplate SoldierClass;
	local SoldierBond BondData;
	local float CohesionPercent, CohesionMax;
	local array<int> CohesionThresholds;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	
	iRank = Unit.GetRank();

	SoldierClass = Unit.GetSoldierClassTemplate();

	flagIcon = Unit.GetCountryTemplate().FlagImage;
	rankIcon = class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
	classIcon = SoldierClass.IconImage;

	SetPlayerInfo(Caps(`GET_RANK_STR(Unit.GetRank(), SoldierClass.DataName)), 
					Caps(Unit.GetName(eNameType_FullNick)),
					classIcon,
					rankIcon, 
					"", 
					0);

	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));

		iRank = Bondmate.GetRank();

		SoldierClass = Bondmate.GetSoldierClassTemplate();

		flagIcon = Bondmate.GetCountryTemplate().FlagImage;
		rankIcon = class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
		classIcon = SoldierClass.IconImage;
		
		CohesionThresholds = class'X2StrategyGameRulesetDataStructures'.default.CohesionThresholds;
		CohesionMax = float(CohesionThresholds[Clamp(BondData.BondLevel + 1, 0, CohesionThresholds.Length - 1)]);
		CohesionPercent = float(BondData.Cohesion) / CohesionMax;

		if (BondData.BondLevel < 3 && class'X2StrategyGameRulesetDataStructures'.static.CanHaveBondAtLevel(Unit, Bondmate, BondData.BondLevel + 1))
		{
			FindOrCreateUpgradeButton().Show();
			FindOrCreateUpgradeButton().SetTitle("Improve Bond To Level" @ BondData.BondLevel + 1);
			FindOrCreateUpgradeButton().SetText("Costs" @ BondCost[BondData.BondLevel] @ "Supplies");
		}
		else
		{
			FindOrCreateUpgradeButton().Hide();
		}

		SetBondMateInfo(BondMateTitle, 
						BondData.BondLevel,
						Caps(Bondmate.GetName(eNameType_Full)),
						Caps(Bondmate.GetName(eNameType_Nick)),
						Caps(`GET_RANK_ABBRV(Bondmate.GetRank(), SoldierClass.DataName)),
						rankIcon,
						Caps(SoldierClass != None ? SoldierClass.DisplayName : ""),
						classIcon,
						flagIcon,
						class'X2StrategyGameRulesetDataStructures'.static.GetSoldierCompatibilityLabel(BondData.Compatibility),
						CohesionPercent,
						false /*todo: is disabled*/ );

	}
	else
	{

		SetBondMateInfo(NoBond,
						-1, //Negative bond level makes this area hide itself.
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						-1,
						false);
	}
}
