class WaveCOM_UICustomize_Head extends UICustomize_Head;

simulated function UpdatePawn()
{
	local XGUnit Visualizer;

	Visualizer = XGUnit(GetUnit().FindOrCreateVisualizer());
	if (Visualizer != none && XComHumanPawn(Visualizer.GetPawn()) != none)
	{
		XComHumanPawn(Visualizer.GetPawn()).SetAppearance(GetUnit().kAppearance);
	}
}

simulated function CustomizeFace()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Face);
	UICustomize_Trait(m_strFace, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Face),
		ChangeFace, ChangeFace, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Face));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function CustomizeHair()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Hairstyle);
	UICustomize_Trait(m_strHair, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Hairstyle),
		ChangeHair, ChangeHair, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Hairstyle));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function CustomizeFacialHair()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_FacialHair);
	UICustomize_Trait(m_strFacialHair, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacialHair),
		ChangeFacialHair, ChangeFacialHair, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacialHair));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function CustomizeRace()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Race);
	UICustomize_Trait(m_strRace, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Race),
		ChangeRace, ChangeRace, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Race));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function CustomizeHelmet()
{
	UICustomize_Trait(m_strHelmet, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Helmet),
		ChangeHelmet, ChangeHelmet, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Helmet));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function CustomizeFacePaint()
{
	UICustomize_Trait(m_strFacePaint, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacePaint),
								 ChangeFacePaint, ChangeFacePaint, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacePaint));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function CustomizeScars()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Scars);
	UICustomize_Trait(m_strScars, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Scars),
		ChangeScars, ChangeScars, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Scars));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function CustomizeLowerFaceProps()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_FaceDecorationLower);
	UICustomize_Trait(m_strLowerFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationLower),
		ChangeFaceLowerProps, ChangeFaceLowerProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationLower));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
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

simulated function PreviewEyeColor(int iIndex)
{
	super.PreviewEyeColor(iIndex);
	UpdatePawn();
}

function PreviewHairColor(int iColorIndex)
{
	super.PreviewHairColor(iColorIndex);
	UpdatePawn();
}

function PreviewSkinColor(int iColorIndex)
{
	super.PreviewSkinColor(iColorIndex);
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
