//---------------------------------------------------------------------------------------
//  FILE:    X2MissionLogic.uc
//  AUTHOR:  James Rakich
//  PURPOSE: Interface for adding new mission logicto X-Com 2. Extend this class and then
//           implement CreateTemplates to produce one or more mission logic templates.
//           
//---------------------------------------------------------------------------------------


class XComGameState_MissionLogic extends XComGameState_BaseObject
	dependson(X2TacticalGameRulesetDataStructures);

const UNIT_REMOVED_EVENTPRIORITY = 44; // Lowered priority below that of the Andromedon SwitchToRobot ability trigger (45).

// these events to be removed as the relevant functions are worked with
var private array<SeqEvent_UnitTouchedVolume> UnitTouchedVolumeEvents;
var private array<SeqEvent_UnitTouchedExit> UnitTouchedExitEvents;
var private array<SeqEvent_UnitAcquiredItem> UnitAcquiredItemEvents;


var private array<delegate<OnNoPlayableUnitsRemainingDelegate> > NoPlayableUnitsRemainingEvents;
var private bool bHasRegisteredEventObservers;

var bool bIsBeingTransferred;

var int LatestCheckForNoUnitIndex;

delegate OnNoPlayableUnitsRemainingDelegate(array<XGPlayer> TeamOutOfUnits, array<XGPlayer> AllTeams);

function SetupMissionStartState(XComGameState StartState);
function RegisterEventHandlers();

function OnAlienTurnBegin(delegate<X2EventManager.OnEventDelegate> NewDelegate)
{
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState_Player PlayerState;
	EventManager = `XEVENTMGR;
	ThisObj = self;
	PlayerState = `BATTLE.GetAIPlayerState();
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', NewDelegate, ELD_OnStateSubmitted, , PlayerState);
}

function OnAbilityActivated(delegate<X2EventManager.OnEventDelegate> NewDelegate)
{
	local X2EventManager EventManager;
	local Object ThisObj;
	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', NewDelegate, ELD_OnStateSubmitted);
}

function OnNoPlayableUnitsRemaining (delegate<OnNoPlayableUnitsRemainingDelegate> Listener)
{
	RegisterRulesetObserver();
	NoPlayableUnitsRemainingEvents.AddItem(Listener);
}

function UnregisterAllObservers()
{
	local Object ThisObj;
	ThisObj = self;
	`XEVENTMGR.UnRegisterFromAllEvents(ThisObj);
	NoPlayableUnitsRemainingEvents.Length = 0;
	bHasRegisteredEventObservers = false;
}

function RegisterRulesetObserver ()
{
	local X2EventManager EventManager;
	local Object ThisObj;
	if (bHasRegisteredEventObservers) return;
	ThisObj = self;

	EventManager = `XEVENTMGR;
	EventManager.RegisterForEvent(ThisObj, 'UnitUnconscious', CheckForUnconsciousUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitDied', CheckForDeadUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitBleedingOut', CheckForBleedingOutUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', CheckForTeamHavingNoPlayableUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitChangedTeam', CheckForTeamHavingNoPlayableUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	`log("Registered Rulset Observers");
	bHasRegisteredEventObservers = true;
}

function bool EventAbilityIs(string AbilityTemplateFilter, Object EventData, XComGameState GameState)
{
	local XComGameState_Ability Ability;
	local string AbilityTemplate;
	
	Ability = XComGameState_Ability(EventData);
	if(Ability != none && GameState != none && 
	   XComGameStateContext_Ability(GameState.GetContext()).ResultContext.InterruptionStep <= 0) //Only trigger this on the first interrupt step
	{
		AbilityTemplate = string(Ability.GetMyTemplate().DataName);

		if(AbilityTemplateFilter == "" || AbilityTemplateFilter == AbilityTemplate)
		{
			return true;
		}
	}
	return false;
}

function ModifyMissionTimerInState(bool Show, int NumTurns = 0, string DisplayMsgTitle = "",
							string DisplayMsgSubtitle = "", TimerColors TimerColor = Normal_Blue, optional XComGameState NewGameState)
{
	local int UIState;
	local XComGameState_UITimer UiTimer;

	if (NewGameState == none)
		return;

	switch(TimerColor)
	{
		case Normal_Blue:   UIState = eUIState_Normal;     break;
		case Bad_Red:       UIState = eUIState_Bad;        break;
		case Good_Green:    UIState = eUIState_Good;       break;
		case Disabled_Grey: UIState = eUIState_Disabled;   break;
	}

	UiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
	if (UiTimer == none)
		UiTimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer'));
	else
		UiTimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer', UiTimer.ObjectID));

	UiTimer.UiState = UIState;
	UiTimer.ShouldShow = Show;
	UiTimer.DisplayMsgTitle = DisplayMsgTitle;
	UiTimer.DisplayMsgSubtitle = DisplayMsgSubtitle;
	UiTimer.TimerValue = NumTurns;
	
	NewGameState.AddStateObject(UiTimer);
}

function ModifyMissionTimer(bool Show, int NumTurns = 0, string DisplayMsgTitle = "",
							string DisplayMsgSubtitle = "", TimerColors TimerColor = Normal_Blue)
{
	local XComGameState NewGameState;
	NewGameState = class 'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Objective Timer changes");

	ModifyMissionTimerInState(Show, NumTurns, DisplayMsgTitle, DisplayMsgSubtitle, TimerColor, NewGameState);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}






//Uses the event manager
private function EventListenerReturn CheckForBleedingOutUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;
	local XComGameState_Unit SourceUnit;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(EventSource);
	
	Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(SourceUnit.ObjectID));
	if (Unit != none)
	{
		if(Unit.IsBleedingOut())
		{
			PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID,, NewGameState.HistoryIndex - 1));
			if(PreviousUnit != none && !PreviousUnit.IsBleedingOut())
			{
				//class'SeqEvent_OnUnitBleedingOut'.static.FireEvent(Unit);
			}
		}
	}

	CheckForTeamHavingNoPlayableUnits(EventData, EventSource, NewGameState, '', none);

	return ELR_NoInterrupt;
}

//Uses the event manager
private function EventListenerReturn CheckForUnconsciousUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;
	local XComGameState_Unit SourceUnit;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(EventSource);

	Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(SourceUnit.ObjectID));
	if (Unit != none)
	{
		if(Unit.IsUnconscious())
		{
			PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID,, NewGameState.HistoryIndex - 1));
			if(PreviousUnit != none && !PreviousUnit.IsUnconscious())
			{
				//class'SeqEvent_OnUnitUnconscious'.static.FireEvent(Unit);
			}
		}
	}

	CheckForTeamHavingNoPlayableUnits(EventData, EventSource, NewGameState, '', none);

	return ELR_NoInterrupt;
}

//Uses the event manager
private function EventListenerReturn CheckForDeadUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;
	local XComGameState_Unit SourceUnit;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(EventSource);
	Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(SourceUnit.ObjectID));
	if (Unit != none)
	{
		// Make sure we only trigger the event on the source unit, because CheckForDeadUnits is called for every dead unit.
		if(Unit.IsDead())
		{
			PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID,, NewGameState.HistoryIndex - 1));
			if(PreviousUnit != none && PreviousUnit.IsAlive())
			{
				if (PreviousUnit.GetMyTemplateName() != 'MimicBeacon') // Don't fire off event if its a MimicBeacon dieing so we prevent narrative about losing units from playing.
				{
					//class'SeqEvent_OnUnitKilled'.static.FireEvent(Unit);
				}
			}
		}
	}

	CheckForTeamHavingNoPlayableUnits(EventData, EventSource, NewGameState, '', none);

	return ELR_NoInterrupt;
}

//Uses the event manager, but may also be called manually. If NewGameState is specified as 'none', then the system simply 
//checks whether the specified player has playable units rather than being edge triggered. This is used as a failsafe by
//the tactical game ruleset.
private function bool DidPlayerRunOutOfPlayableUnits(XGPlayer InPlayer)
{	
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;

	History = `XCOMHISTORY;

	// at least one unit was removed from play for this player on this state. If all other units
	// for this player are also out of play on this state, then this must be the state where
	// the last unit was removed.
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.ControllingPlayer.ObjectID == InPlayer.ObjectID && !Unit.GetMyTemplate().bIsCosmetic && !Unit.IsTurret() && !Unit.GetMyTemplate().bNeverSelectable )
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID));
			if( Unit == None || (Unit.IsAlive() && !Unit.bRemovedFromPlay && !Unit.IsIncapacitated()) )
			{
				return false;
			}
		}
	}

	// the alien team has units remaining if they have reinforcements already queued up
	if( (InPlayer.m_eTeam == eTeam_Alien || InPlayer.m_eTeam == eTeam_TheLost) && AnyPendingReinforcements() )
	{
		return false;
	}

	// this player had a unit removed from play and all other units are also out of play.
	return true;
}

function bool AnyPendingReinforcements()
{
	local XComGameState_NonstackingReinforcements AISpawnerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_NonstackingReinforcements', AISPawnerState)
	{
		break;
	}

	// true if there are any active reinforcement spawners
	return (AISPawnerState != None);
}

//Uses the event manager
private function EventListenerReturn CheckForTeamHavingNoPlayableUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{	
	local delegate<OnNoPlayableUnitsRemainingDelegate> Listener;
	local XComGameStateHistory History;
	local XComGameState_Player PlayerObject;
	local XGPlayer PlayerVisualizer;
	local array<XGPlayer> DefeatedPlayers, AllPlayers;

	if (NoPlayableUnitsRemainingEvents.Length == 0) return ELR_NoInterrupt; // nothing to do
	
	History = `XCOMHISTORY;

	if ( LatestCheckForNoUnitIndex >= History.GetCurrentHistoryIndex())
	{
		return ELR_NoInterrupt; // We already processed this game state, bye.
	}
	LatestCheckForNoUnitIndex = History.GetCurrentHistoryIndex();
	
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerObject)
	{
		PlayerVisualizer = XGPlayer(PlayerObject.GetVisualizer());		
		if( DefeatedPlayers.Find(PlayerVisualizer) == INDEX_NONE ) //See if we have already triggered for this player
		{
			if( DidPlayerRunOutOfPlayableUnits(PlayerVisualizer) )		
			{
				DefeatedPlayers.AddItem(PlayerVisualizer);
			}
		}
		AllPlayers.AddItem(PlayerVisualizer);
	}
	if (DefeatedPlayers.Length > 0)
	{
		foreach NoPlayableUnitsRemainingEvents(Listener)
		{
			Listener(DefeatedPlayers, AllPlayers);
		}
	}

	return ELR_NoInterrupt;
}

//Called by the tactical game rule set as a failsafe, once each time the unit actions phase ends
function CheckForTeamHavingNoPlayableUnitsExternal()
{
	CheckForTeamHavingNoPlayableUnits(none, none, none, '', none);
}

private function CheckForUnitAcquiredItem(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit PreviousUnitState;
	local StateObjectReference CurrentStateItemReference;
	local XComGameState_Item CurrentStateItem;

	if (UnitAcquiredItemEvents.Length == 0) return; // nothing to do
	
	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		PreviousUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID,, NewGameState.HistoryIndex - 1));
		if(PreviousUnitState == none) continue;

		// check if any items weren't in their state on the previous frame
		foreach UnitState.InventoryItems(CurrentStateItemReference)
		{
			if(PreviousUnitState.InventoryItems.Find('ObjectID', CurrentStateItemReference.ObjectID) == INDEX_NONE)
			{
				// this item is new this frame, so fire all events with it's info
				CurrentStateItem = XComGameState_Item(History.GetGameStateForObjectID(CurrentStateItemReference.ObjectID,, NewGameState.HistoryIndex));
				`assert(CurrentStateItem != none);
				
				//foreach UnitAcquiredItemEvents(Event)
				//{
					//Event.FireEvent(UnitState, CurrentStateItem);
				//}
			}
		}
	}
}

private function CheckForSquadVisiblePoints(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_SquadVisiblePoint SquadVisiblePoint; 

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_SquadVisiblePoint', SquadVisiblePoint)
	{
		SquadVisiblePoint = XComGameState_SquadVisiblePoint(History.GetGameStateForObjectID(SquadVisiblePoint.ObjectID));
		SquadVisiblePoint.CheckForVisibilityChanges(NewGameState);
	}
}

defaultproperties
{
	bHasRegisteredEventObservers = false;
	bIsBeingTransferred = false;
}