// This is an Unreal Script

class WaveCOM_UICustomize_Menu extends UICustomize_Menu;

var WaveCOM_Camera_Customization LookatCharacter;

simulated function UpdateData()
{
	local XGUnit Visualizer;

	super.UpdateData();

	Visualizer = XGUnit(GetUnit().FindOrCreateVisualizer());

	WaveCOM_UIMouseGuard_RotateCustomization(`SCREENSTACK.GetFirstInstanceOf(class'WaveCOM_UIMouseGuard_RotateCustomization')).SetCamera(LookatCharacter, Visualizer.GetPawn());
	XComHumanPawn(Visualizer.GetPawn()).SetAppearance(Unit.kAppearance);
}

simulated function InitializeCustomizeManager(XComPresentationLayerBase Pres, optional XComGameState_Unit InUnit)
{
	if(Pres.m_kCustomizeManager == None)
	{
		Pres.m_kCustomizeManager = new(Pres) Unit.GetMyTemplate().CustomizationManagerClass;
	}

	Pres.m_kCustomizeManager.Init(InUnit, XGUnit(`XCOMHISTORY.GetVisualizer(UnitRef.ObjectID)));
}

simulated function UpdateCustomizationManager()
{
	if (Movie.Pres.m_kCustomizeManager == none)
	{		
		Unit = WaveCOM_UIArmory_FieldLoadout(Movie.Stack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).GetUnit();
		UnitRef = WaveCOM_UIArmory_FieldLoadout(Movie.Stack.GetScreen(class'WaveCOM_UIArmory_FieldLoadout')).UnitReference;
		InitializeCustomizeManager(Movie.Pres, Unit);
	}
}

simulated function OnCustomizeInfo()
{
	if (Unit.GetMyTemplate().UICustomizationInfoClass == class'UICustomize_Info' || Unit.GetMyTemplate().UICustomizationInfoClass == class'UICustomize_TemplarInfo')
	{
		Movie.Pres.ScreenStack.Push(Spawn(class'WaveCOM_UICustomize_Info', Movie.Pres), Movie);
	}
}
// --------------------------------------------------------------------------
simulated function OnCustomizeProps()
{
	Movie.Pres.ScreenStack.Push(Spawn(class'WaveCOM_UICustomize_Props', Movie.Pres), Movie);
}
// --------------------------------------------------------------------------
simulated function OnCustomizeHead()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Face);
	if (Unit.GetMyTemplate().UICustomizationHeadClass == class'UICustomize_SkirmisherHead')
	{
		Movie.Pres.ScreenStack.Push(Spawn(class'WaveCOM_UICustomize_SkirmisherHead', Movie.Pres), Movie);
	}
	else
	{
		Movie.Pres.ScreenStack.Push(Spawn(class'WaveCOM_UICustomize_Head', Movie.Pres), Movie);
	}
}
// --------------------------------------------------------------------------
simulated function OnCustomizeBody()
{
	Movie.Pres.ScreenStack.Push(Spawn(class'WaveCOM_UICustomize_Body', Movie.Pres), Movie);
}
// --------------------------------------------------------------------------
simulated function OnCustomizeWeapon()
{
	Movie.Pres.ScreenStack.Push(Spawn(class'WaveCOM_UICustomize_Weapon', Movie.Pres), Movie);
}

reliable client function CustomizeViewClass()
{
	UICustomize_Trait(m_strViewClass, "", CustomizeManager.GetCategoryList(eUICustomizeCat_ViewClass),
		none, ViewClass, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_ViewClass));
}

reliable client function CustomizeClass()
{
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

// Camera functions
simulated function CloseScreen()
{
	// Remove all locked camera from stack
	super.CloseScreen();
	if (LookatCharacter != none)
	{
		`CAMERASTACK.RemoveCamera(LookatCharacter);
	}
}

// Lock camera to body
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	local XGUnit UnitVisualizer;
	local XComUnitPawn Pawn;
	local TPOV CameraView;
	local Rotator CameraRotation;
	local Vector OffsetVector;

	super.InitScreen(InitController, InitMovie, InitName);
	UnitVisualizer = XGUnit(`XCOMHISTORY.GetVisualizer(UnitRef.ObjectID));
	if( UnitVisualizer != none )
	{
		LookatCharacter = new class'WaveCOM_Camera_Customization';					

		Pawn = UnitVisualizer.GetPawn();

		CameraRotation = Pawn.Rotation;
		CameraRotation.Pitch = 0;
		CameraRotation.Yaw += DegToUnrRot * 220;
			
		OffsetVector = Vector(CameraRotation) * -1.0f;			
		CameraView.Location = Pawn.Location + (OffsetVector * 120.0f);
		CameraView.Location.Z += 15.0f;
		CameraView.Rotation = CameraRotation;

		LookatCharacter.SetCameraView( CameraView );
		LookatCharacter.Priority = eCameraPriority_Cinematic;
		`CAMERASTACK.AddCamera(LookatCharacter);
	}
}

defaultproperties
{
	MouseGuardClass = class'WaveCOM_UIMouseGuard_RotateCustomization';
}
