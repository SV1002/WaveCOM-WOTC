class WaveCOM_UIArmory_Promotion extends UIArmory_Promotion;

simulated function PopulateData()
{
	local int i, maxRank, previewIndex;
	local string AbilityIcon1, AbilityIcon2, AbilityName1, AbilityName2, HeaderString;
	local bool bFirstUnnassignedRank, bHasAbility1, bHasAbility2, bHasRankAbility;
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate ClassTemplate;
	local X2AbilityTemplate AbilityTemplate1, AbilityTemplate2;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> AbilityTree;
	local UIArmory_PromotionItem Item;
	local array<name> AWCAbilityNames;
	local Vector ZeroVec;
	local Rotator UseRot;
	local XComUnitPawn UnitPawn, GremlinPawn;

	// We don't need to clear the list, or recreate the pawn here -sbatista
	//super.PopulateData();
	Unit = GetUnit();
	ClassTemplate = Unit.GetSoldierClassTemplate();

	HeaderString = m_strAbilityHeader;

	if(Unit.GetRank() != 1 && Unit.HasAvailablePerksToAssign())
	{
		HeaderString = m_strSelectAbility;
	}

	AS_SetTitle(ClassTemplate.IconImage, HeaderString, ClassTemplate.LeftAbilityTreeTitle, ClassTemplate.RightAbilityTreeTitle, Caps(ClassTemplate.DisplayName));

	if(ActorPawn == none || (Unit.GetRank() == 1 && bAfterActionPromotion)) //This condition is TRUE when in the after action report, and we need to rank someone up to squaddie
	{
		//Get the current pawn so we can extract its rotation
		UnitPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(AfterActionScreen, UnitReference.ObjectID, ZeroVec, UseRot);
		UseRot = UnitPawn.Rotation;

		//Free the existing pawn, and then create the ranked up pawn. This may not be strictly necessary since most of the differences between the classes are in their equipment. However, it is easy to foresee
		//having class specific soldier content and this covers that possibility
		Movie.Pres.GetUIPawnMgr().ReleasePawn(AfterActionScreen, UnitReference.ObjectID);
		CreateSoldierPawn(UseRot);

		if(bAfterActionPromotion && !Unit.bCaptured)
		{
			//Let the pawn manager know that the after action report is referencing this pawn too			
			UnitPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(AfterActionScreen, UnitReference.ObjectID, ZeroVec, UseRot);
			AfterActionScreen.SetPawn(UnitReference, UnitPawn);
			GremlinPawn = Movie.Pres.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitReference.ObjectID);
			if (GremlinPawn != none)
				GremlinPawn.SetLocation(UnitPawn.Location);
		}
	}

	// Check to see if Unit needs to show a new class popup.
	if(Unit.bNeedsNewClassPopup)
	{
		AwardRankAbilities(ClassTemplate, 0);

		`HQPRES.UIClassEarned(Unit.GetReference());
		Unit.bNeedsNewClassPopup = false;  //Prevent from queueing up more of these popups on toggling soldiers. 

		Unit = GetUnit(); // we've updated the UnitState, update the Unit to reflect the latest changes
	}
	
	// Check for AWC Ability popup
	if(Unit.NeedsAWCAbilityPopup())
	{
		AWCAbilityNames = Unit.GetAWCAbilityNames();
		
		if(AWCAbilityNames.Length > 0)
		{
			ShowAWCDialog(AWCAbilityNames);
		}

		Unit = GetUnit();  // we've updated the UnitState, update the Unit to reflect the latest changes
	}

	previewIndex = -1;
	maxRank = class'X2ExperienceConfig'.static.GetMaxRank();
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	if(ClassRowItem == none)
	{
		ClassRowItem = Spawn(class'WaveCOM_UIArmory_PromotionItem', self);
		ClassRowItem.MCName = 'classRow';
		ClassRowItem.InitPromotionItem(0);
		ClassRowItem.OnMouseEventDelegate = OnClassRowMouseEvent;

		if(Unit.GetRank() == 1)
			ClassRowItem.OnReceiveFocus();
	}

	ClassRowItem.ClassName = ClassTemplate.DataName;
	ClassRowItem.SetRankData(class'UIUtilities_Image'.static.GetRankIcon(1, ClassTemplate.DataName), Caps(class'X2ExperienceConfig'.static.GetRankName(1, ClassTemplate.DataName)));

	AbilityTree = Unit.GetRankAbilities(ClassRowItem.Rank);
	AbilityTemplate2 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);
	if(AbilityTemplate2 != none)
	{
		ClassRowItem.AbilityName2 = AbilityTemplate2.DataName;
		AbilityName2 = Caps(AbilityTemplate2.LocFriendlyName);
		AbilityIcon2 = AbilityTemplate2.IconImage;
	}
	else
	{
		AbilityTemplate1 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[1].AbilityName);
		ClassRowItem.AbilityName2 = AbilityTemplate1.DataName;
		AbilityName2 = Caps(AbilityTemplate1.LocFriendlyName);
		AbilityIcon2 = AbilityTemplate1.IconImage;
	}

	ClassRowItem.SetEquippedAbilities(true, true);
	ClassRowItem.SetAbilityData("", "", AbilityIcon2, AbilityName2);
	ClassRowItem.SetClassData(ClassTemplate.IconImage, Caps(ClassTemplate.DisplayName));

	for(i = 2; i < maxRank; ++i)
	{
		Item = UIArmory_PromotionItem(List.GetItem(i - 2));
		if(Item == none)
			Item = UIArmory_PromotionItem(List.CreateItem(class'WaveCOM_UIArmory_PromotionItem')).InitPromotionItem(i - 1);

		Item.Rank = i - 1;
		Item.ClassName = ClassTemplate.DataName;
		Item.SetRankData(class'UIUtilities_Image'.static.GetRankIcon(i, ClassTemplate.DataName), Caps(class'X2ExperienceConfig'.static.GetRankName(i, ClassTemplate.DataName)));

		AbilityTree = Unit.GetRankAbilities(Item.Rank);

		AbilityTemplate1 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);
		if(AbilityTemplate1 != none)
		{
			Item.AbilityName1 = AbilityTemplate1.DataName;
			AbilityName1 = i > Unit.GetRank() ? class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled) : Caps(AbilityTemplate1.LocFriendlyName);
			AbilityIcon1 = i > Unit.GetRank() ? class'UIUtilities_Image'.const.UnknownAbilityIcon : AbilityTemplate1.IconImage;
		}

		AbilityTemplate2 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[1].AbilityName);
		if(AbilityTemplate2 != none)
		{
			Item.AbilityName2 = AbilityTemplate2.DataName;
			AbilityName2 = i > Unit.GetRank() ? class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled) : Caps(AbilityTemplate2.LocFriendlyName);
			AbilityIcon2 = i > Unit.GetRank() ? class'UIUtilities_Image'.const.UnknownAbilityIcon : AbilityTemplate2.IconImage;
		}

		bHasAbility1 = Unit.HasSoldierAbility(Item.AbilityName1);
		bHasAbility2 = Unit.HasSoldierAbility(Item.AbilityName2);
		bHasRankAbility = bHasAbility1 || bHasAbility2;

		Item.SetAbilityData(AbilityIcon1, AbilityName1, AbilityIcon2, AbilityName2);
		Item.SetEquippedAbilities(bHasAbility1, bHasAbility2);

		if(i == 1 || bHasRankAbility || (i == Unit.GetRank() && !Unit.HasAvailablePerksToAssign()))
		{
			Item.SetDisabled(false);
			Item.SetPromote(false);
		}
		else if(i > Unit.GetRank())
		{
			Item.SetDisabled(true);
			Item.SetPromote(false);
		}
		else // has available perks to assign
		{
			if(!bFirstUnnassignedRank)
			{
				previewIndex = i - 2;
				bFirstUnnassignedRank = true;
				Item.SetDisabled(false);
				Item.SetPromote(true);
				List.SetSelectedIndex(List.GetItemIndex(Item), true);
			}
			else
			{
				Item.SetDisabled(true);
				Item.SetPromote(false);
			}
		}

		Item.RealizeVisuals();
	}

	class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, Unit);
	PreviewRow(List, previewIndex);
	if (previewIndex < 0)
	{
		Navigator.SetSelected(ClassRowItem);
		ClassRowItem.OnReceiveFocus();
	}
	else
	{
		Navigator.SetSelected(List);
		List.SetSelectedIndex(previewIndex);
	}

	UpdateNavHelp();
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