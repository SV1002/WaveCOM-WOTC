// This is a combination of XComGameStateContext_EffectRemoved and XComGameStateContext_ChangeContainer
// So we can remove effects and do many other stuffs on the same game state context
//
class WaveCOMGameStateContext_UpdateUnit extends XComGameStateContext;

var array<StateObjectReference> RemovedEffects;
var private XComGameState AssociatedGameState;

var private XComGameState NewGameState;
var string ChangeInfo;  //Fill out with info to help with debug display

var Delegate<BuildVisualizationDelegate> BuildVisualizationFn; //Optional visualization function

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

static function WaveCOMGameStateContext_UpdateUnit CreateEmptyChangeContainerUU(optional string ChangeDescription)
{
	local WaveCOMGameStateContext_UpdateUnit container;
	container = WaveCOMGameStateContext_UpdateUnit(CreateXComGameStateContext());
	container.ChangeInfo = ChangeDescription;
	return container;
}

static function WaveCOMGameStateContext_UpdateUnit CreateChangeStateUU(optional string ChangeDescription, optional XComGameState_Unit UnitState, bool bSetVisualizationFence = false, float VisFenceTimeout=20.0f)
{
	local WaveCOMGameStateContext_UpdateUnit container;
	container = CreateEmptyChangeContainerUU(ChangeDescription);
	//container.SetVisualizationFence(bSetVisualizationFence, VisFenceTimeout);
	container.AssociatedGameState = `XCOMHISTORY.CreateNewGameState(true, container);
	return container;
}

function XComGameState GetGameState()
{
	return AssociatedGameState;
}

function AddEffectRemoved(XComGameState_Effect EffectState)
{
	if (RemovedEffects.Find('ObjectID', EffectState.ObjectID) == INDEX_NONE)
	{
		RemovedEffects.AddItem(EffectState.GetReference());
	}
}

protected function ContextBuildVisualization()
{
	local VisualizationActionMetadata SourceMetadata;
	local VisualizationActionMetadata TargetMetadata;
	local XComGameStateHistory History;
	local X2VisualizerInterface VisualizerInterface;
	local XComGameState_Effect EffectState;
	local XComGameState_BaseObject EffectTarget;
	local XComGameState_BaseObject EffectSource;
	local X2Effect_Persistent EffectTemplate;
	local int i;

	History = `XCOMHISTORY;
	
	`log( "WaveCOM UpdateUnit :: ====== Start building Visualization (" $ RemovedEffects.Length $ ") ======");

	if(BuildVisualizationFn != None)
	{
		`log( "WaveCOM UpdateUnit :: Custom visualization found, processing...",, 'WaveCOM');
		BuildVisualizationFn(AssociatedState);
	}
	
	for (i = 0; i < RemovedEffects.Length; ++i)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(RemovedEffects[i].ObjectID));
		if (EffectState != none)
		{
			EffectSource = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID);
			EffectTarget = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);

			if (EffectTarget != none)
			{
				TargetMetadata.VisualizeActor = History.GetVisualizer(EffectTarget.ObjectID);
				VisualizerInterface = X2VisualizerInterface(TargetMetadata.VisualizeActor);
				if (TargetMetadata.VisualizeActor != none)
				{
					History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, TargetMetadata.StateObject_OldState, TargetMetadata.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
					if (TargetMetadata.StateObject_NewState == none)
						TargetMetadata.StateObject_NewState = TargetMetadata.StateObject_OldState;

					if (VisualizerInterface != none)
						VisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, TargetMetadata);

					EffectTemplate = EffectState.GetX2Effect();
					EffectTemplate.AddX2ActionsForVisualization_Removed(AssociatedState, TargetMetadata, 'AA_Success', EffectState);
				}
				
				if (EffectTarget.ObjectID == EffectSource.ObjectID)
				{
					SourceMetadata = TargetMetadata;
				}

				SourceMetadata.VisualizeActor = History.GetVisualizer(EffectSource.ObjectID);
				if (SourceMetadata.VisualizeActor != none)
				{
					History.GetCurrentAndPreviousGameStatesForObjectID(EffectSource.ObjectID, SourceMetadata.StateObject_OldState, SourceMetadata.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
					if (SourceMetadata.StateObject_NewState == none)
						SourceMetadata.StateObject_NewState = SourceMetadata.StateObject_OldState;

					EffectTemplate.AddX2ActionsForVisualization_RemovedSource(AssociatedState, SourceMetadata, 'AA_Success', EffectState);
				}
			}
		}
	}
}

defaultproperties
{
	AssociatedPlayTiming=SPT_AfterSequential
}