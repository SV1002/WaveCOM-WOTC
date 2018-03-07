class WaveCOM_SyncVisualizerRuleset extends XComGameStateContext;

protected function ContextBuildVisualization()
{	
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_BaseObject VisualizedObject;
	local XComGameStateHistory History;
	local XComGameState_AIPlayerData AIPlayerDataState;
	local XGAIPlayer kAIPlayer;
	local XComGameState_BattleData BattleState;

	History = `XCOMHISTORY;

	`log("===TIMING===SYNC VISUALIZATION START===/TIMING===",, 'WaveCOMVis');

	// Sync the map first so that the tile data is in the proper state for all the individual SyncVisualizer calls
	BattleState = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = BattleState;
	ActionMetadata.StateObject_NewState = BattleState;

	// Jwats: First create all the visualizers so the sync actions have access to them for metadata
	foreach AssociatedState.IterateByClassType(class'XComGameState_BaseObject', VisualizedObject)
	{
		if( X2VisualizedInterface(VisualizedObject) != none )
		{
			X2VisualizedInterface(VisualizedObject).FindOrCreateVisualizer();
		}
	}

	`log("==Visualizer Created/found==",, 'WaveCOMVis');

	foreach AssociatedState.IterateByClassType(class'XComGameState_BaseObject', VisualizedObject)
	{
		if(X2VisualizedInterface(VisualizedObject) != none)
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = VisualizedObject;
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
			ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObject_NewState.ObjectID);
			class'X2Action_SyncVisualizer'.static.AddToVisualizationTree(ActionMetadata, self).ForceImmediateTimeout();
		}
	}
	`log("==First pass sync visualizer==",, 'WaveCOMVis');

	// Jwats: Once all the visualizers are in their default state allow the additional sync actions run to manipulate them
	foreach AssociatedState.IterateByClassType(class'XComGameState_BaseObject', VisualizedObject)
	{
		if( X2VisualizedInterface(VisualizedObject) != none )
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = VisualizedObject;
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
			ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObject_NewState.ObjectID);
			X2VisualizedInterface(VisualizedObject).AppendAdditionalSyncActions(ActionMetadata, self);
		}
	}
	`log("==Second pass sync visualizer==",, 'WaveCOMVis');

	kAIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if (kAIPlayer.m_iDataID == 0)
	{
		foreach AssociatedState.IterateByClassType(class'XComGameState_AIPlayerData', AIPlayerDataState)
		{
			kAIPlayer.m_iDataID = AIPlayerDataState.ObjectID;
			break;
		}
	}
	`log("===TIMING===SYNC VISUALIZATION END===/TIMING===",, 'WaveCOMVis');
}