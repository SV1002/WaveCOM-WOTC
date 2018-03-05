class WaveCOMStrategyElement_AcademyUnlocks extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
		
	// ArmedToTheTeeth removed, it is now a breakthrough
	// Spare Parts removed, it is now a breakthrough
	// LockAndLoad removed, it is now a breakthrough
	Templates.AddItem(QuidUnlock());
	Templates.AddItem(LiveFireUnlock());
	Templates.AddItem(BetweenTheEyesUnlock());
	Templates.AddItem(WeakPointsUnlock());
	Templates.AddItem(InsiderKnowledgeUnlock());
	Templates.AddItem(InformationWarUnlock());
	Templates.AddItem(TrialByFireUnlock());
	Templates.AddItem(ArtOfWarUnlock());
	Templates.AddItem(MentalFortitudeUnlock());
	Templates.AddItem(FeedbackUnlock());

	Templates.AddItem(BlackMarketHero());
	Templates.AddItem(BlackMarketEleriumCore());

	return Templates;
}

static function X2DataTemplate BlackMarketEleriumCore()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_EleriumCore');

	// Generic template designed to be overwritten, used by the Black Market
	Template.GenerateRewardFn = class'X2StrategyElement_DefaultRewards'.static.GenerateItemReward;
	Template.SetRewardFn = class'X2StrategyElement_DefaultRewards'.static.SetItemReward;
	Template.GiveRewardFn = class'X2StrategyElement_DefaultRewards'.static.GiveItemReward;
	Template.GetRewardStringFn = class'X2StrategyElement_DefaultRewards'.static.GetItemRewardString;
	Template.GetRewardImageFn = class'X2StrategyElement_DefaultRewards'.static.GetItemRewardImage;
	Template.GetBlackMarketStringFn = class'X2StrategyElement_DefaultRewards'.static.GetItemBlackMarketString;
	Template.GetRewardIconFn = class'X2StrategyElement_DefaultRewards'.static.GetGenericRewardIcon;
	Template.RewardPopupFn = class'X2StrategyElement_DefaultRewards'.static.ItemRewardPopup;
	Template.rewardObjectTemplateName = 'EleriumCore';

	return Template;
}

//==== HERO SOLDIER REWARD HERE ========================

static function X2RewardTemplate BlackMarketHero()
{	
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_WaveCOMHero');

	Template.IsRewardAvailableFn = IsFactionSoldierRewardAvailable;
	Template.GenerateRewardFn = GenerateFactionSoldierReward;
	Template.SetRewardFn = class'X2StrategyElement_DefaultRewards'.static.SetPersonnelReward;
	Template.GiveRewardFn = class'X2DownloadableContentInfo_WOTCWaveCOM'.static.GivePersonnelReward;
	Template.GetRewardStringFn = class'X2StrategyElement_DefaultRewards'.static.GetPersonnelRewardString;
	Template.GetRewardImageFn = class'X2StrategyElement_DefaultRewards'.static.GetPersonnelRewardImage;
	Template.GetBlackMarketStringFn = class'X2StrategyElement_DefaultRewards'.static.GetSoldierBlackMarketString;
	Template.GetRewardIconFn = class'X2StrategyElement_DefaultRewards'.static.GetGenericRewardIcon;
	Template.CleanUpRewardFn = class'X2StrategyElement_DefaultRewards'.static.CleanUpUnitReward;
	Template.RewardPopupFn = FactionSoldierRewardPopup;

	return Template;
}

static function bool IsFactionSoldierRewardAvailable(optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	return true;
}

static function GenerateFactionSoldierReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Unit NewUnitState;
	local name nmCountry, nmCharacterClass;
	local int Idx;

	Idx = class'Engine'.static.GetEngine().SyncRand(class'X2StrategyElement_XpackRewards'.default.FactionSoldierCharacters.Length, "WaveCOMFactionClassRoll");
	nmCharacterClass = class'X2StrategyElement_XpackRewards'.default.FactionSoldierCharacters[Idx]; // RANDOM FACTION
	
	// Grab the region and pick a random country
	nmCountry = '';
	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));
	if (RegionState != none)
	{
		nmCountry = RegionState.GetMyTemplate().GetRandomCountryInRegion();
	}	

	NewUnitState = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(NewGameState, nmCharacterClass, nmCountry);
	RewardState.RewardObjectReference = NewUnitState.GetReference();
}

static function FactionSoldierRewardPopup(XComGameState_Reward RewardState)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_ResistanceFaction FactionState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	FactionState = UnitState.GetResistanceFaction();

	if (FactionState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Faction Soldier Reward");
		`XEVENTMGR.TriggerEvent(FactionState.GetNewFactionSoldierEvent(), , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	class'X2StrategyElement_DefaultRewards'.static.PersonnelRewardPopup(RewardState);
}
//======================================================
static function X2SoldierUnlockTemplate FeedbackUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_FeedbackUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_templar_feedback";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 6;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_Feedback';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 750;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'EleriumCore';
	Resources.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'CorpseSectoid';
	Resources.Quantity = 5;
	Template.Cost.ArtifactCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'CorpseGatekeeper';
	Resources.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'CorpseAdventPriest';
	Resources.Quantity = 3;
	Template.Cost.ArtifactCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate MentalFortitudeUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_MentalFortitudeUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_templar_mentalfortitude";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 6;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.ActivateSitRep = 'MentalFortitude';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 600;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'EleriumCore';
	Resources.Quantity = 1;
	Resources.ItemTemplateName = 'CorpseSectoid';
	Resources.Quantity = 3;
	Template.Cost.ArtifactCosts.AddItem(Resources);
	Template.Cost.ArtifactCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate ArtOfWarUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_ArtOfWarUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_templar_artofwar";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 4;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_ArtOfWar';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 500;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate TrialByFireUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_TrialByFireUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_templar_trialbyfire";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 3;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_TrialByFire';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 600;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate InformationWarUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_InformationWarUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_skirmisher_informationwar";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 4;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_InformationWar';
	Template.ActivateSitRep = 'InformationWar';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 450;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'CorpseAdventMEC';
	Resources.Quantity = 3;
	Template.Cost.ArtifactCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate InsiderKnowledgeUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_InsiderKnowledgeUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_skirmisher_insideknowledge";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 5;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_InsideKnowledge';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 600;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'EleriumCore';
	Resources.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate WeakPointsUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_WeakPointsUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_skirmisher_weakpoints";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 5;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_WeakPoints';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 400;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'EleriumCore';
	Resources.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate BetweenTheEyesUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_BetweenTheEyesUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_reaper_betweentheeyes";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 6;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_BetweenTheEyes';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 1000;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'EleriumCore';
	Resources.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate LiveFireUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_LiveFireUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_reaper_livefiretraining";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 4;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_LiveFireTraining';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 600;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Resources.ItemTemplateName = 'EleriumCore';
	Resources.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate QuidUnlock()
{
	local WaveCOMSoldierContinentBonusUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'WaveCOMSoldierContinentBonusUnlockTemplate', Template, 'WaveCOM_QuidUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_XPACK_StrategyImages.policy_skirmisher_quidproquo";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 3;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	Template.StrategyBonus = 'ResCard_QuidProQuo';

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 400;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}