class WaveCOM_UIShellDifficulty extends UIShellDifficulty;

function StartIntroMovie()
{
	local XComEngine Engine;
	
	Engine = `XENGINE;

	Engine.PlayLoadMapMovie(-1);
}

simulated function BuildMenu()
{
	super.BuildMenu();
	m_TutorialMechaItem.SetDisabled(true);
	m_TutorialMechaItem.Checkbox.SetChecked(false, false);
	m_StartButton.OnClickedDelegate = JustStartTheGame;
}

function JustStartTheGame(UIButton ButtonControl)
{
	EnabledOptionalNarrativeDLC.Length = 0;
	OnDifficultyConfirm(m_StartButton);
}