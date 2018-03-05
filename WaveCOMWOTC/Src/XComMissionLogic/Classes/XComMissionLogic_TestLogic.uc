// This is an Unreal Script

class XComMissionLogic_TestLogic extends XComGameState_MissionLogic;

delegate EventListenerReturn OnEventDelegate(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData);

function SetupMissionStartState(XComGameState StartState)
{
	`log("XComMissionLogic_TestLogic (WOTC) :: SetupMissionStartState",, 'WaveCOM');
}

function RegisterEventHandlers()
{	
	OnAlienTurnBegin(TestOnAlienTurnBegin);
	`log("XComMissionLogic_TestLogic (WOTC) :: RegisterEventHandlers",, 'WaveCOM');
}

function EventListenerReturn TestOnAlienTurnBegin(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	`log("XComMissionLogic_TestLogic (WOTC) :: OnAlienTurnBegin",, 'WaveCOM');
	return ELR_NoInterrupt;
}