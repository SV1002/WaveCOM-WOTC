class WaveCOMFinalShellPatcher extends UIPanel;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	return super.InitPanel(InitName, InitLibID);
}

event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	if (UIFinalShell(Screen).MainMenu.Length > 0 && UIFinalShell(Screen).MainMenu[0].Text != "WaveCOM")
	{
		UIFinalShell(Screen).MainMenu[0].OnClickedDelegate = OpenNewDifficultyScreen;
		UIFinalShell(Screen).MainMenu[0].SetText("WaveCOM");
	}
}

function CreateWaveMenu()
{
	local UIX2MenuButton Button; 

	Button = Screen.Spawn(class'UIX2MenuButton', UIFinalShell(Screen).MainMenuContainer);

	Button.InitMenuButton(false, 'WaveCOM', "WaveCOM", OpenNewDifficultyScreen);
	Button.OnSizeRealized = UIFinalShell(Screen).OnButtonSizeRealized;
	UIFinalShell(Screen).MainMenu.AddItem(Button);
}

simulated function OpenNewDifficultyScreen(UIButton button)
{
	local UIMovie TargetMovie;
	local UIScreen TempScreen;

	//Turning off 3D shell option for now, as the soldier model covers up the second wave options. 
	TargetMovie = XComShellPresentationLayer(button.Screen.Owner) == none ? XComPresentationLayerBase(button.Screen.Owner).Get2DMovie() : XComPresentationLayerBase(button.Screen.Owner).Get3DMovie();
	//TargetMovie = Get2DMovie();

	//TempScreen = button.Screen.Owner.Spawn( class'WaveCOM_UIShellDifficulty', button.Screen.Owner  );
	TempScreen = button.Screen.Owner.Spawn( class'UIShellDifficulty', button.Screen.Owner  );
	//WaveCOM_UIShellDifficulty(TempScreen).m_bIsPlayingGame = false; 
	UIShellDifficulty(TempScreen).m_bIsPlayingGame = false; 

	XComPresentationLayerBase(button.Screen.Owner).ScreenStack.Push( TempScreen, TargetMovie );
}