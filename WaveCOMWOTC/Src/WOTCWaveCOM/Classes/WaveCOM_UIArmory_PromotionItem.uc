class WaveCOM_UIArmory_PromotionItem extends UIArmory_PromotionItem;

static function UIAbilityPopup(XComPresentationLayerBase PresLayer, X2AbilityTemplate AbilityTemplate, StateObjectReference UnitRef)
{
	local UIAbilityPopup AbilityPopup;

	if (PresLayer.ScreenStack.IsNotInStack(class'UIAbilityPopup'))
	{
		AbilityPopup = PresLayer.Spawn(class'UIAbilityPopup', PresLayer);
		AbilityPopup.UnitRef = UnitRef;
		PresLayer.ScreenStack.Push(AbilityPopup);
		AbilityPopup.InitAbilityPopup(AbilityTemplate);
	}
}

simulated function OnAbilityInfoClicked(UIButton Button)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local UIArmory_Promotion PromotionScreen;
	
	PromotionScreen = UIArmory_Promotion(Screen);
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	if(Button == InfoButton1)
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName1);
	else if(Button == InfoButton2)
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName2);

	if(AbilityTemplate != none)
		UIAbilityPopup(`PRES, AbilityTemplate, PromotionScreen.UnitReference);
	AbilityIcon1.OnLoseFocus();
	AbilityIcon2.OnLoseFocus();
	RealizeHighlight();
}