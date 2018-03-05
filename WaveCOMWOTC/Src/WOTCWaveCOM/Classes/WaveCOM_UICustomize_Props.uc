// This is an Unreal Script

class WaveCOM_UICustomize_Props extends UICustomize_Props;

simulated function UpdateData()
{
	local XGUnit Visualizer;

	super.UpdateData();

	Visualizer = XGUnit(Unit.FindOrCreateVisualizer());
	XComHumanPawn(Visualizer.GetPawn()).SetAppearance(Unit.kAppearance);
}

simulated function CustomizeHelmet()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strHelmet, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Helmet),
		ChangeHelmet, ChangeHelmet, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Helmet));
}

simulated function CustomizeFacePaint()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strFacePaint, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacePaint),
								 ChangeFacePaint, ChangeFacePaint, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacePaint));
}

simulated function CustomizeScars()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strScars, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Scars),
		ChangeScars, ChangeScars, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Scars));
}

simulated function CustomizeUpperFaceProps()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strUpperFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationUpper),
		ChangeFaceUpperProps, ChangeFaceUpperProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationUpper));
}

simulated function CustomizeLowerFaceProps()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strLowerFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationLower),
		ChangeFaceLowerProps, ChangeFaceLowerProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationLower));
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