class WaveCOM_UIShellDifficulty extends UIScreenListener;// UIShellDifficulty;

event OnInit(UIScreen Screen)
{
	local UIShellDifficulty DiffScreen;
	local UIChooseIronMan IronScreen;

	DiffScreen = UIShellDifficulty(Screen);
	IronScreen = UIChooseIronMan(Screen);
	if (DiffScreen != none && !DiffScreen.m_bIsPlayingGame)
	{
		DiffScreen.m_TutorialMechaItem.SetDisabled(true);
		DiffScreen.m_TutorialMechaItem.Checkbox.SetChecked(false, false);
		DiffScreen.m_StartButton.OnClickedDelegate = ShowIronman;
		//DiffScreen.m_StartButton.SetText("Start Game");
	}
	else if (IronScreen != none && !IronScreen.m_bIsPlayingGame)
	{
		IronScreen.m_StartButton.OnClickedDelegate = JustStartTheGame;
		IronScreen.m_StartWithoutIronmanButton.OnClickedDelegate = JustStartTheGame;
	}
}

function StartNoMovie()
{
	local XComEngine Engine;
	
	Engine = `XENGINE;

	Engine.PlayLoadMapMovie(-1);
}

function ShowIronman(UIButton ButtonControl)
{
	ButtonControl.Screen.Movie.Pres.UIIronMan();
}

simulated function UIShellDifficulty GetShellDifficulty(UIScreenStack ScreenStack)
{
	local int Index;
	for( Index = 0; Index < ScreenStack.Screens.Length;  ++Index)
	{
		if( UIShellDifficulty(ScreenStack.Screens[Index]) != none )
			return UIShellDifficulty(ScreenStack.Screens[Index]);
	}
	return none; 
}

function JustStartTheGame(UIButton ButtonControl)
{
	local UIShellDifficulty DiffScreen;

	DiffScreen = GetShellDifficulty(ButtonControl.Screen.Movie.Stack);

	DiffScreen.UpdateIronman(ButtonControl.MCName == 'ironmanToggle');
	ButtonControl.Screen.Movie.Stack.Pop(ButtonControl.Screen);

	DiffScreen.EnabledOptionalNarrativeDLC.Length = 0;
	OnDifficultyConfirm(DiffScreen);
}

simulated public function OnDifficultyConfirm(UIShellDifficulty DiffScreen)
{
	local XComGameStateHistory History;
	local XComGameState StrategyStartState;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local array<name> SWOptions;
	local float TacticalPercent, StrategyPercent, GameLengthPercent; 
	local bool ShouldGiveFactionSoldier;

	//BAIL if the save is in progress. 
	if(DiffScreen.m_bSaveInProgress && DiffScreen.Movie.Pres.m_kProgressDialogStatus == eProgressDialog_None)
	{
		DiffScreen.WaitingForSaveToCompletepProgressDialog();
		return;
	}

	History = `XCOMHISTORY;

	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	
	DiffScreen.Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	TacticalPercent = DiffScreen.DifficultyConfigurations[DiffScreen.m_iSelectedDifficulty].TacticalDifficulty;
	StrategyPercent = DiffScreen.DifficultyConfigurations[DiffScreen.m_iSelectedDifficulty].StrategyDifficulty;
	GameLengthPercent = DiffScreen.DifficultyConfigurations[DiffScreen.m_iSelectedDifficulty].GameLength;

	//If we are NOT going to do the tutorial, we setup our campaign starting state here. If the tutorial has been selected, we wait until it is done
	//to create the strategy start state.
	SWOptions = DiffScreen.GetSelectedSecondWaveOptionNames( );

	ShouldGiveFactionSoldier = SWOptions.Find('ReaperStart') != INDEX_NONE ||
								SWOptions.Find('SkirmisherStart') != INDEX_NONE ||
								SWOptions.Find('TemplarStart') != INDEX_NONE;

	//We're starting a new campaign, set it up
	StrategyStartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, 
																									, 
																									, 
																									!ShouldGiveFactionSoldier,
																									true,
																									DiffScreen.m_iSelectedDifficulty, 
																									TacticalPercent,
																									StrategyPercent, 
																									GameLengthPercent, 
																									DiffScreen.m_bSuppressFirstTimeNarrative,
																									DiffScreen.EnabledOptionalNarrativeDLC, 
																									, 
																									DiffScreen.m_bIronmanFromShell,
																									, 
																									, 
																									SWOptions);

	// The CampaignSettings are initialized in CreateStrategyGameStart, so we can pull it from the history here
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	//Since we just created the start state above, the settings object is still writable so just update it with the settings from the new campaign dialog
	CampaignSettingsStateObject.SetStartTime(StrategyStartState.TimeStamp);

	CampaignSettingsStateObject.SetDifficulty(DiffScreen.m_iSelectedDifficulty, TacticalPercent, StrategyPercent, GameLengthPercent);
	CampaignSettingsStateObject.SetIronmanEnabled(DiffScreen.m_bIronmanFromShell);

	//Let the screen fade into the intro
	DiffScreen.SetTimer(0.6f, false, nameof(StartNoMovie));
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, DiffScreen.MakeColor(0, 0, 0), vect2d(0, 1), 0.5);

	DiffScreen.SetTimer(1.0f, false, nameof(DiffScreen.DeferredConsoleCommand));
}