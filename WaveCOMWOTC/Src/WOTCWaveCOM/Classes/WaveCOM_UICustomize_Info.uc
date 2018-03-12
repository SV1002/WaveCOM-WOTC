class WaveCOM_UICustomize_Info extends UICustomize_Info;

simulated function CreateDataListItems()
{
	local EUIState ColorState;
	local int i;

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;

	// FIRST NAME
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataDescription(m_strFirstNameLabel, OpenFirstNameInputBox)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// LAST NAME
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataDescription(m_strLastNameLabel, OpenLastNameInputBox)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// NICKNAME
	//-----------------------------------------------------------------------------------------
	ColorState = (bIsSuperSoldier || (!Unit.IsVeteran() && !InShell())) ? eUIState_Disabled : eUIState_Normal;
	GetListItem(i++)
		.UpdateDataDescription(m_strNickNameLabel, OpenNickNameInputBox)
		.SetDisabled(bIsSuperSoldier || (!Unit.IsVeteran() && !InShell()), bIsSuperSoldier ? m_strIsSuperSoldier : m_strNeedsVeteranStatus); // Don't disable in the shell. 

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;

	// BIO
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataDescription(m_strEditBiography, OpenBiographyInputBox)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// NATIONALITY
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Country)$ m_strNationality, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Country, ColorState, FontSize), CustomizeCountry)
		.SetDisabled(bIsSuperSoldier || bIsXPACSoldier, bIsSuperSoldier?m_strIsSuperSoldier: m_strNoNationality);

	// GENDER
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Gender)$ m_strGender, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Gender, ColorState, FontSize), CustomizeGender)
		.SetDisabled(true, "Cannot change gender in WaveCOM");

	// VOICE
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Voice)$ m_strVoice, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Voice, eUIState_Normal, FontSize), CustomizeVoice);

	if (GetUnit().GetMyTemplate().UICustomizationInfoClass != class'UICustomize_TemplarInfo')
	{
		// DISABLE VETERAN OPTIONS
		ColorState = bDisableVeteranOptions ? eUIState_Disabled : eUIState_Normal;

		// ATTITUDE (VETERAN)
		//-----------------------------------------------------------------------------------------
		GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Personality)$ m_strAttitude,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Personality, ColorState, FontSize), CustomizePersonality);
	}
}

simulated function CustomizeGender()
{
	UICustomize_Trait(m_strGender, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Gender),
		ChangeGender, ChangeGender, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Gender));
}

reliable client function CustomizeCountry()
{
	UICustomize_Trait( 
		class'UICustomize_Props'.default.m_strArmorPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Country),
		ChangeCountry, ChangeCountry, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Country)); 
}

simulated function CustomizeVoice()
{
	CustomizeManager.UpdateCamera();
	if (Movie.IsMouseActive())
	{
		UICustomize_Trait(m_strVoice, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Voice),
			none, ChangeVoice, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Voice), m_strPreviewVoice, ChangeVoice);
	}
	else //IF MOUSELESS, calls custom class with voice-specific controls
	{
		//Below: copied/modified code from Movie.Pres.UICustomize_Trait() - wanted to keep Mouseless changes as minimal as possible, rather than create a new function in a different class - JTA
		Movie.Pres.ScreenStack.Push(Spawn(class'UICustomize_Voice', Movie.Pres), Movie.Pres.Get3DMovie());
		UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).UpdateTrait(m_strVoice, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Voice),
			none, ChangeVoice, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Voice), m_strPreviewVoice, ChangeVoice);
	}
}

reliable client function CustomizePersonality()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strAttitude, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Personality),
		ChangePersonality, ChangePersonality, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Personality));
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
