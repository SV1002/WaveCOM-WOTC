class WaveCOM_UICustomize_Body extends UICustomize_Body;

simulated function CustomizeArmorPattern()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strArmorPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_ArmorPatterns),
		ChangeArmorPattern, ChangeArmorPattern, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_ArmorPatterns));
}

simulated function CustomizeTorso()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strTorso, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Torso),
		ChangeTorso, ChangeTorso, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Torso));
}

simulated function CustomizeTorsoDeco()
{
	CustomizeManager.UpdateCamera();
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
	CustomizeManager.UpdateCamera();
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
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strArms, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Arms),
		ChangeArms, ChangeArms, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Arms));
}

simulated function CustomizeLeftArm()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strLeftArm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArm),
		ChangeLeftArm, ChangeLeftArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArm));
}

simulated function CustomizeRightArm()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strRightArm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArm),
								 ChangeRightArm, ChangeRightArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArm));
}

simulated function CustomizeLeftArmDeco()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strLeftArmDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArmDeco),
								 ChangeLeftArmDeco, ChangeLeftArmDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArmDeco));
}

simulated function CustomizeRightArmDeco()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strRightArmDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArmDeco),
								 ChangeRightArmDeco, ChangeRightArmDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArmDeco));
}

simulated function CustomizeLeftForearm()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strLeftForearm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftForearm),
		ChangeLeftForearm, ChangeLeftForearm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftForearm));
}

simulated function CustomizeRightForearm()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strRightForearm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightForearm),
		ChangeRightForearm, ChangeRightForearm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightForearm));
}

simulated function CustomizeLeftArmTattoos()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strTattoosLeft, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArmTattoos),
		ChangeTattoosLeftArm, ChangeTattoosLeftArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArmTattoos));
}

simulated function CustomizeRightArmTattoos()
{
	CustomizeManager.UpdateCamera();
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