class WaveCOM_UICustomize_Weapon extends UICustomize_Weapon;

simulated function CustomizeWeaponPattern()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strWeaponPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_WeaponPatterns),
		ChangeWeaponPattern, ChangeWeaponPattern, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_WeaponPatterns));
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