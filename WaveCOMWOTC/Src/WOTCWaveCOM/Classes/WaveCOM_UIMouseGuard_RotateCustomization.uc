class WaveCOM_UIMouseGuard_RotateCustomization extends UIMouseGuard_RotatePawn;

var WaveCOM_Camera_Customization CameraToRotate;

simulated function SetActorPawn(Actor NewPawn, optional Rotator NewRotation)
{
	// Do nothing
	if(ActorPawn == none)
		ClearTimer(nameof(OnUpdate));
}

simulated function OnUpdate()
{
	local Vector2D MouseDelta;
	local TPOV CameraView;
	local XComUnitPawn UnitPawn;
	local Vector OffsetVector;

	if( CameraToRotate != none )
	{
		UnitPawn = XComUnitPawn(ActorPawn);
		CameraView = CameraToRotate.GetCameraLocationAndOrientation();
		if(bRotatingPawn && bCanRotate)
		{
			MouseDelta = Movie.Pres.m_kUIMouseCursor.m_v2MouseFrameDelta;
			ActorRotation.Yaw += MouseDelta.X * DragRotationMultiplier;
		}
		
		StartRotation = QuatFromRotator(CameraView.Rotation);
		GoalRotation = QuatFromRotator(ActorRotation);
	
		ResultRotation = QuatSlerp(StartRotation, GoalRotation, 0.1f, true);
		RotatorLerp = QuatToRotator(ResultRotation);
		CameraView.Rotation = RotatorLerp;

		if (UnitPawn != none)
		{
			OffsetVector = Vector(RotatorLerp) * -1.0f;	
			CameraView.Location = UnitPawn.Location + (OffsetVector * 120.0f);
			CameraView.Location.Z += 15.0f;
		}

		CameraToRotate.SetCameraView( CameraView );
	}
}

simulated function OnReceiveFocus()
{
	super(UIMouseGuard).OnReceiveFocus();
	if (CameraToRotate != none)
	{
		ActorRotation = CameraToRotate.GetCameraLocationAndOrientation().Rotation;
	}
}

simulated function RotateInPlace(int Dir)
{
	if( CameraToRotate != none )
	{
		ActorRotation.Yaw += 45.0f * class'Object'.const.DegToUnrRot * WheelRotationMultiplier * Dir;
	}
}

simulated function SetCamera(WaveCOM_Camera_Customization LookatCharacter, Actor FocusPawn, optional Rotator NewRotation)
{
	local Rotator ZeroRotation;

	CameraToRotate = LookatCharacter;
	ActorPawn = FocusPawn;

	`log("Mouseguard intiated",, 'WaveCOM');

	if(NewRotation != ZeroRotation)
		ActorRotation = NewRotation;
	else if(ActorRotation == ZeroRotation && CameraToRotate != none)
		ActorRotation = CameraToRotate.GetCameraLocationAndOrientation().Rotation;

	if(CameraToRotate != none)
		SetTimer(0.01f, true, nameof(OnUpdate));
	else
		ClearTimer(nameof(OnUpdate));
}
