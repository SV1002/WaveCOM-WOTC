// This is an Unreal Script

class WaveCOM_UICustomize_Props extends UICustomize_Props;

simulated function CustomizeHelmet()
{
	UICustomize_Trait(m_strHelmet, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Helmet),
		ChangeHelmet, ChangeHelmet, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Helmet));
}

simulated function CustomizeFacePaint()
{
	UICustomize_Trait(m_strFacePaint, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacePaint),
								 ChangeFacePaint, ChangeFacePaint, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacePaint));
}

simulated function CustomizeScars()
{
	UICustomize_Trait(m_strScars, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Scars),
		ChangeScars, ChangeScars, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Scars));
}

simulated function CustomizeUpperFaceProps()
{
	UICustomize_Trait(m_strUpperFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationUpper),
		ChangeFaceUpperProps, ChangeFaceUpperProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationUpper));
}

simulated function CustomizeLowerFaceProps()
{
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
	local XComGameState_Item ItemState;
	local bool bShouldSetAppearance;
	local XGUnit Visualizer;

	Visualizer = XGUnit(GetUnit().FindOrCreateVisualizer());

	GetUnit();

	Items = Unit.GetAllInventoryItems(NewGameState);
	if (Items.Length > 0)
	{
		for (Index = 0; Index < Items.Length; ++Index)
		{
			WeaponVis = XGWeapon(Items[Index].GetVisualizer());
			if (WeaponVis != none)
			{
				if (NewGameState != none)
				{
					ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Items[Index].ObjectID));
				}
				else
				{
					ItemState = Items[Index];
				}
				bShouldSetAppearance = true;
				switch (ItemState.InventorySlot)
				{
					case eInvSlot_SecondaryWeapon:
						WeaponAppearance = CustomizeManager.SecondaryWeapon.WeaponAppearance;
						break;
					case eInvSlot_TertiaryWeapon:
						WeaponAppearance = CustomizeManager.TertiaryWeapon.WeaponAppearance;
						break;
					case eInvSlot_PrimaryWeapon:
					case eInvSlot_QuaternaryWeapon:
					case eInvSlot_QuinaryWeapon:
					case eInvSlot_SenaryWeapon:
					case eInvSlot_SeptenaryWeapon:
						WeaponAppearance = CustomizeManager.PrimaryWeapon.WeaponAppearance;
						break;
					default:
						bShouldSetAppearance = false;
						break;
				}
				ItemState.WeaponAppearance = WeaponAppearance;
				if (bShouldSetAppearance)
				{
					WeaponVis.SetAppearance(WeaponAppearance);
				}
				//`log("Weapon" @ Items[Index].ObjectID @ "of" @ EInventorySlot(Items[Index].InventorySlot) @ "changes appearance",, 'WaveCOM');
				//`log("New appearance:" @ WeaponAppearance.iWeaponTint @ WeaponAppearance.nmWeaponPattern,, 'WaveCOM');
				//`log("Will submit gamestate", NewGameState != none, 'WaveCOM');
			}
		}
	}
}

function PreviewWeaponColor(int iColorIndex)
{
	local XComGameState NewGameState;

	super.PreviewWeaponColor(iColorIndex);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update weapon appearance");
	UpdateWeaponAppearances(NewGameState);
	`XCOMHISTORY.CleanupPendingGameState(NewGameState);
}

function SetWeaponColor(int iColorIndex)
{
	local XComGameState NewGameState;

	super.SetWeaponColor(iColorIndex);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update weapon appearance");
	UpdateWeaponAppearances(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
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

	XComHumanPawn(Visualizer.GetPawn()).SetAppearance(Unit.kAppearance);

	WaveCOM_UIMouseGuard_RotateCustomization(`SCREENSTACK.GetFirstInstanceOf(class'WaveCOM_UIMouseGuard_RotateCustomization'))
		.SetCamera(WaveCOM_UICustomize_Menu(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UICustomize_Menu')).LookatCharacter, Visualizer.GetPawn());
}

defaultproperties
{
	MouseGuardClass = class'WaveCOM_UIMouseGuard_RotateCustomization';
}
