class XComMissionLogic_Listener extends XComGameState_BaseObject config(MissionLogic);

struct MissionLogicBinding
{
	var string MissionType;
	var string MissionLogicClass;
};

var const config array<MissionLogicBinding> arrMissionLogicBindings;

function RegisterToListen()
{
	local Object ThisObj;
	ThisObj = self;

	`log("XComMissionLogic (WOTC) :: TacticalEventListener Loaded",, 'WaveCOM');
	`XEVENTMGR.RegisterForEvent(ThisObj, 'OnTacticalBeginPlay', LoadRelevantMissionLogic, ELD_Immediate, , , true);
}

function EventListenerReturn LoadRelevantMissionLogic(Object EventData, Object EventSource, XComGameState NewGameState, name EventID, Object CallbackData)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionLogic MissionLogic;
	local MissionLogicBinding LogicBinding;
	local class<XComGameState_MissionLogic> MissionLogicClass;
	local string MissionType;
	`log("XComMissionLogic :: Start Loading Mission Logic");

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	MissionType = BattleData.MapData.ActiveMission.sType;
	foreach arrMissionLogicBindings(LogicBinding)
	{

		if (LogicBinding.MissionType == MissionType || LogicBinding.MissionType == "__all__")
		{
			`log("XComMissionLogic (WOTC) :: Loading" @ LogicBinding.MissionLogicClass @ "for" @ LogicBinding.MissionType,, 'WaveCOM');
			MissionLogicClass = class<XComGameState_MissionLogic>(DynamicLoadObject(LogicBinding.MissionLogicClass, class'Class'));

			if (!X2TacticalGameRuleset(`XCOMGAME.GameRuleset).bLoadingSavedGame)
			{
				MissionLogic = XComGameState_MissionLogic(`XCOMHISTORY.GetSingleGameStateObjectForClass(MissionLogicClass));
				if (MissionLogic != none && !MissionLogic.bIsBeingTransferred)
				{
					// Discard any old mission logics
					`log("XComMissionLogic :: Old Mission Logic found, deleting");
					NewGameState.RemoveStateObject(MissionLogic.ObjectID);
					MissionLogic = none;
				}
				`log("XComMissionLogic (WOTC) :: Created mission logic " @ LogicBinding.MissionLogicClass,, 'WaveCOM');

				if (MissionLogic != none && MissionLogic.bIsBeingTransferred)
				{
					// Clear the flag so it gets transferred properly next time
					`log("XComMissionLogic (WOTC) :: Found transferring MissionLogic of same type, preserving...",, 'WaveCOM');
					MissionLogic = XComGameState_MissionLogic(NewGameState.ModifyStateObject(MissionLogicClass, MissionLogic.ObjectID));
					MissionLogic.bIsBeingTransferred = false;
				}
				else
				{
					MissionLogic = XComGameState_MissionLogic(NewGameState.CreateNewStateObject(MissionLogicClass));
				}
				MissionLogic.SetupMissionStartState(NewGameState);
			}
			else
			{
				`log("XComMissionLogic :: Loaded single mission logic " @ LogicBinding.MissionLogicClass);
				MissionLogic = XComGameState_MissionLogic(`XCOMHISTORY.GetSingleGameStateObjectForClass(MissionLogicClass));
			}
			MissionLogic.RegisterEventHandlers();
		}
	}
	`log("XComMissionLogic (WOTC) :: Loaded Mission Logic",, 'WaveCOM');

	return ELR_NoInterrupt;
}