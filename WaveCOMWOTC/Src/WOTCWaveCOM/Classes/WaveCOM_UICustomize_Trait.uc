// This is an Unreal Script

class WaveCOM_UICustomize_Trait extends UICustomize_Trait;

var delegate<OnItemSelectedCallback> OnSelectionChangedCallback;

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
	local bool bShouldSetAppearance;

	GetUnit();

	Items = Unit.GetAllInventoryItems();
	if (Items.Length > 0)
	{
		for (Index = 0; Index < Items.Length; ++Index)
		{
			WeaponVis = XGWeapon(Items[Index].GetVisualizer());
			if (WeaponVis != none)
			{
				bShouldSetAppearance = true;
				switch (Items[Index].InventorySlot)
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
				Items[Index].WeaponAppearance = WeaponAppearance;
				if (bShouldSetAppearance)
				{
					WeaponVis.SetAppearance(WeaponAppearance);
				}
			}
		}
	}
}

simulated function UpdateTrait( string _Title, 
							  string _Subtitle, 
							  array<string> _Data, 
							  delegate<OnItemSelectedCallback> _onSelectionChanged,
							  delegate<OnItemSelectedCallback> _onItemClicked,
							  optional delegate<IsSoldierEligible> _checkSoldierEligibility,
							  optional int _startingIndex = -1, 
							  optional string _ConfirmButtonLabel,
							  optional delegate<OnItemSelectedCallback> _onConfirmButtonClicked )
{
	super.UpdateTrait(_Title, 
						_Subtitle, 
						_Data, 
						_onSelectionChanged,
						_onItemClicked,
						_checkSoldierEligibility,
						_startingIndex, 
						_ConfirmButtonLabel,
						_onConfirmButtonClicked);
	List.OnSelectionChanged = OnPreviewAny;
	OnSelectionChangedCallback = _onSelectionChanged;
}

simulated function OnPreviewAny(UIList _list, int itemIndex)
{
	OnSelectionChangedCallback(_list, itemIndex);
	UpdatePawn();
}

simulated function OnCancel()
{
	super.OnCancel();
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
	UpdatePawn();

	WaveCOM_UIMouseGuard_RotateCustomization(`SCREENSTACK.GetFirstInstanceOf(class'WaveCOM_UIMouseGuard_RotateCustomization'))
		.SetCamera(WaveCOM_UICustomize_Menu(Movie.Pres.ScreenStack.GetScreen(class'WaveCOM_UICustomize_Menu')).LookatCharacter, Visualizer.GetPawn());
}

defaultproperties
{
	MouseGuardClass = class'WaveCOM_UIMouseGuard_RotateCustomization';
}
