class WaveCOM_UIArmory_PromotionHeroColumn extends UIArmory_PromotionHeroColumn;

function OnAbilityInfoClicked(UIButton Button)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local UIButton InfoButton;
	local UIArmory_PromotionHero PromotionScreen;
	local int idx;

	PromotionScreen = UIArmory_PromotionHero(Screen);

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach InfoButtons(InfoButton, idx)
	{
		if (InfoButton == Button)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityNames[idx]);
			break;
		}
	}
	
	if (AbilityTemplate != none)
		class'WaveCOM_UIArmory_PromotionItem'.static.UIAbilityPopup(`PRES, AbilityTemplate, PromotionScreen.UnitReference);

	if( InfoButton != none )
		InfoButton.Hide();
}