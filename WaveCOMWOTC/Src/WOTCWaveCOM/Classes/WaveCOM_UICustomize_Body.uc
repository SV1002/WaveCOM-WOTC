class WaveCOM_UICustomize_Body extends UICustomize_Body;

simulated function UpdatePawn()
{
	local XGUnit Visualizer;

	Visualizer = XGUnit(GetUnit().FindOrCreateVisualizer());
	if (Visualizer != none && XComHumanPawn(Visualizer.GetPawn()) != none)
	{
		XComHumanPawn(Visualizer.GetPawn()).SetAppearance(GetUnit().kAppearance);
		UpdateWeaponAppearances();
	}
}

function UpdateWeaponAppearances(optional XComGameState NewGameState)
{
	local array<XComGameState_Item> Items;
	local int Index;
	local TWeaponAppearance WeaponAppearance;
	local XGWeapon WeaponVis;

	GetUnit();

	Items = Unit.GetAllInventoryItems(NewGameState);
	if (Items.Length > 0)
	{
		for (Index = 0; Index < Items.Length; ++Index)
		{
			WeaponVis = XGWeapon(Items[Index].GetVisualizer());
			if (WeaponVis != none)
			{
				switch (Items[Index].InventorySlot)
				{
					case eInvSlot_SecondaryWeapon:
						WeaponAppearance = CustomizeManager.SecondaryWeapon.WeaponAppearance;
						Items[Index].WeaponAppearance = WeaponAppearance;
						WeaponVis.SetAppearance(WeaponAppearance);
						break;
					case eInvSlot_TertiaryWeapon:
						WeaponAppearance = CustomizeManager.TertiaryWeapon.WeaponAppearance;
						Items[Index].WeaponAppearance = WeaponAppearance;
						WeaponVis.SetAppearance(WeaponAppearance);
						break;
					case eInvSlot_PrimaryWeapon:
					case eInvSlot_QuaternaryWeapon:
					case eInvSlot_QuinaryWeapon:
					case eInvSlot_SenaryWeapon:
					case eInvSlot_SeptenaryWeapon:
						WeaponAppearance = CustomizeManager.PrimaryWeapon.WeaponAppearance;
						Items[Index].WeaponAppearance = WeaponAppearance;
						WeaponVis.SetAppearance(WeaponAppearance);
						break;
				}
			}
		}
	}
}

simulated function CustomizeArmorPattern()
{
	UICustomize_Trait(m_strArmorPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_ArmorPatterns),
		ChangeArmorPattern, ChangeArmorPattern, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_ArmorPatterns));
}

simulated function CustomizeTorso()
{
	UICustomize_Trait(m_strTorso, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Torso),
		ChangeTorso, ChangeTorso, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Torso));
}

simulated function CustomizeTorsoDeco()
{
	UICustomize_Trait(m_strTorsoDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_TorsoDeco),
		ChangeTorsoDeco, ChangeTorsoDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_TorsoDeco));
}

simulated function CustomizeThighs()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Thighs);
	UICustomize_Trait(m_strThighs, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Thighs),
		ChangeThighs, ChangeThighs, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Thighs));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeLegs";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeLegs';
}

simulated function CustomizeLegs()
{
	UICustomize_Trait(m_strLegs, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Legs),
		ChangeLegs, ChangeLegs, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Legs)); 
}

simulated function CustomizeShins()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Shins);
	UICustomize_Trait(m_strShins, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Shins),
		ChangeShins, ChangeShins, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Shins));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeLegs";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeLegs';
}

simulated function CustomizeArms()
{
	UICustomize_Trait(m_strArms, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Arms),
		ChangeArms, ChangeArms, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Arms));
}

simulated function CustomizeLeftArm()
{
	UICustomize_Trait(m_strLeftArm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArm),
		ChangeLeftArm, ChangeLeftArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArm));
}

simulated function CustomizeRightArm()
{
	UICustomize_Trait(m_strRightArm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArm),
								 ChangeRightArm, ChangeRightArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArm));
}

simulated function CustomizeLeftArmDeco()
{
	UICustomize_Trait(m_strLeftArmDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArmDeco),
								 ChangeLeftArmDeco, ChangeLeftArmDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArmDeco));
}

simulated function CustomizeRightArmDeco()
{
	UICustomize_Trait(m_strRightArmDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArmDeco),
								 ChangeRightArmDeco, ChangeRightArmDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArmDeco));
}

simulated function CustomizeLeftForearm()
{
	UICustomize_Trait(m_strLeftForearm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftForearm),
		ChangeLeftForearm, ChangeLeftForearm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftForearm));
}

simulated function CustomizeRightForearm()
{
	UICustomize_Trait(m_strRightForearm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightForearm),
		ChangeRightForearm, ChangeRightForearm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightForearm));
}

simulated function CustomizeLeftArmTattoos()
{
	UICustomize_Trait(m_strTattoosLeft, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArmTattoos),
		ChangeTattoosLeftArm, ChangeTattoosLeftArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArmTattoos));
}

simulated function CustomizeRightArmTattoos()
{
	UICustomize_Trait(m_strTattoosRight, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArmTattoos),
		ChangeTattoosRightArm, ChangeTattoosRightArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArmTattoos));
}

function UICustomize_Trait( string _Title, 
							string _Subtitle, 
							array<string> _Data, 
							delegate<UICustomize_Trait.OnItemSelectedCallback> _onSelectionChanged,
							delegate<UICustomize_Trait.OnItemSelectedCallback> _onItemClicked,
							optional delegate<UICustomize.IsSoldierEligible> _eligibilityCheck,
							optional int startingIndex = -1,
							optional string _ConfirmButtonLabel,
							optional delegate<UICustomize_Trait.OnItemSelectedCallback> _onConfirmButtonClicked )
{
	Movie.Stack.Push(Spawn(class'WaveCOM_UICustomize_Trait', Movie.Pres), Movie);
	WaveCOM_UICustomize_Trait(Movie.Stack.GetCurrentScreen()).UpdateTrait( _Title, _Subtitle, _Data, _onSelectionChanged, _onItemClicked, _eligibilityCheck, startingIndex, _ConfirmButtonLabel, _onConfirmButtonClicked );
}

function PreviewPrimaryArmorColor(int iColorIndex)
{
	super.PreviewPrimaryArmorColor(iColorIndex);
	UpdatePawn();
}

function SetPrimaryArmorColor(int iColorIndex)
{
	super.SetPrimaryArmorColor(iColorIndex);
	UpdatePawn();
}

function PreviewSecondaryArmorColor(int iColorIndex)
{
	super.PreviewSecondaryArmorColor(iColorIndex);
	UpdatePawn();
}

function SetSecondaryArmorColor(int iColorIndex)
{
	super.SetSecondaryArmorColor(iColorIndex);
	UpdatePawn();
}

function PreviewTattooColor(int iColorIndex)
{
	super.PreviewTattooColor(iColorIndex);
	UpdatePawn();
}

function SetTattooColor(int iColorIndex)
{
	super.SetTattooColor(iColorIndex);
	UpdatePawn();
}

simulated function PrevSoldier()
{
	// Don't
}

simulated function NextSoldier()
{
	// Don't
}

simulated function UpdateNavHelp()
{
	// NO NavHelp
}

simulated function UpdateData()
{
	local XGUnit Visualizer;
	super.UpdateData();

	Visualizer = XGUnit(GetUnit().FindOrCreateVisualizer());

	WaveCOM_UIMouseGuard_RotateCustomization(`SCREENSTACK.GetFirstInstanceOf(class'WaveCOM_UIMouseGuard_RotateCustomization'))
		.SetCamera(WaveCOM_UICustomize_Menu(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UICustomize_Menu')).LookatCharacter, Visualizer.GetPawn());
}

defaultproperties
{
	MouseGuardClass = class'WaveCOM_UIMouseGuard_RotateCustomization';
}
