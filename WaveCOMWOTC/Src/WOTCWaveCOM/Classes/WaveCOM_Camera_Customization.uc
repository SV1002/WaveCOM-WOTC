class WaveCOM_Camera_Customization extends X2Camera_Fixed;

var public TPOV CameraViewX;

function SetCameraView(const out TPOV InCameraView)
{		
	CameraViewX = InCameraView;
}

function TPOV GetCameraLocationAndOrientation()
{
	return CameraViewX;
}