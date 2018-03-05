// This is an Unreal Script

class WaveCOM_UICustomize_Menu extends UICustomize_Menu;

simulated function UpdateData()
{
	local XGUnit Visualizer;

	super.UpdateData();

	Visualizer = XGUnit(Unit.FindOrCreateVisualizer());
	XComHumanPawn(Visualizer.GetPawn()).SetAppearance(Unit.kAppearance);
}

simulated function UpdateCustomizationManager()
{
	if (Movie.Pres.m_kCustomizeManager == none)
	{
		Unit = WaveCOM_UICustomize_Menu(Movie.Stack.GetScreen(class'WaveCOM_UICustomize_Menu')).Unit;
		UnitRef = WaveCOM_UICustomize_Menu(Movie.Stack.GetScreen(class'WaveCOM_UICustomize_Menu')).UnitRef;
		Movie.Pres.InitializeCustomizeManager(Unit);
	}
}

simulated function OnCustomizeInfo()
{
	CustomizeManager.UpdateCamera();

	Movie.Stack.Push(Spawn(Unit.GetMyTemplate().UICustomizationInfoClass, Movie.Pres), Movie);
}
// --------------------------------------------------------------------------
simulated function OnCustomizeProps()
{
	CustomizeManager.UpdateCamera();
	Movie.Stack.Push(Spawn(class'WaveCOM_UICustomize_Props', Movie.Pres), Movie);
}
// --------------------------------------------------------------------------
simulated function OnCustomizeHead()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Face);
	if (Unit.GetMyTemplate().UICustomizationHeadClass == class'UICustomize_SkirmisherHead')
	{
		Movie.Stack.Push(Spawn(class'WaveCOM_UICustomize_SkirmisherHead', Movie.Pres), Movie);
	}
	else
	{
		Movie.Stack.Push(Spawn(class'WaveCOM_UICustomize_Head', Movie.Pres), Movie);
	}
}
// --------------------------------------------------------------------------
simulated function OnCustomizeBody()
{
	CustomizeManager.UpdateCamera();
	Movie.Stack.Push(Spawn(class'WaveCOM_UICustomize_Body', Movie.Pres), Movie);
}
// --------------------------------------------------------------------------
simulated function OnCustomizeWeapon()
{
	CustomizeManager.UpdateCamera();
	Movie.Stack.Push(Spawn(class'WaveCOM_UICustomize_Weapon', Movie.Pres), Movie);
}

reliable client function CustomizeViewClass()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strViewClass, "", CustomizeManager.GetCategoryList(eUICustomizeCat_ViewClass),
		none, ViewClass, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_ViewClass));
}

reliable client function CustomizeClass()
{
	CustomizeManager.UpdateCamera();
	UICustomize_Trait(m_strCustomizeClass, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Class), 
		none, ChangeClass, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Class));
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