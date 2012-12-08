#include "mex.h"
#include "math.h"
#include <XnOpenNI.h>
#include <XnCodecIDs.h>
#include <XnCppWrapper.h>

#define CHECK_RC(nRetVal, what)										\
	if (nRetVal != XN_STATUS_OK)									\
	{																\
		printf("%s failed: %s\n", what, xnGetStatusString(nRetVal));\
        mexErrMsgTxt("Kinect Error"); 							    \
	}
    
//---------------------------------------------------------------------------
// Globals
//---------------------------------------------------------------------------
xn::Context g_Context;
xn::UserGenerator g_UserGenerator;
xn::DepthGenerator g_DepthGenerator;

XnBool g_bNeedPose = FALSE;
XnChar g_strPose[20] = "";


// Callback: New user was detected
void XN_CALLBACK_TYPE User_NewUser(xn::UserGenerator& generator, XnUserID nId, void* pCookie)
{
	printf("New User %d\n", nId);
	// New user found
	if (g_bNeedPose)
	{
		g_UserGenerator.GetPoseDetectionCap().StartPoseDetection(g_strPose, nId);
	}
	else
	{
		g_UserGenerator.GetSkeletonCap().RequestCalibration(nId, TRUE);
	}
}
// Callback: An existing user was lost
void XN_CALLBACK_TYPE User_LostUser(xn::UserGenerator& generator, XnUserID nId, void* pCookie)
{
	printf("Lost user %d\n", nId);
}
// Callback: Detected a pose
void XN_CALLBACK_TYPE UserPose_PoseDetected(xn::PoseDetectionCapability& capability, const XnChar* strPose, XnUserID nId, void* pCookie)
{
	printf("Pose %s detected for user %d\n", strPose, nId);
	g_UserGenerator.GetPoseDetectionCap().StopPoseDetection(nId);
	g_UserGenerator.GetSkeletonCap().RequestCalibration(nId, TRUE);
}
// Callback: Started calibration
void XN_CALLBACK_TYPE UserCalibration_CalibrationStart(xn::SkeletonCapability& capability, XnUserID nId, void* pCookie)
{
	printf("Calibration started for user %d\n", nId);
}
// Callback: Finished calibration
void XN_CALLBACK_TYPE UserCalibration_CalibrationEnd(xn::SkeletonCapability& capability, XnUserID nId, XnBool bSuccess, void* pCookie)
{
	if (bSuccess)
	{
		// Calibration succeeded
		printf("Calibration complete, start tracking user %d\n", nId);
		g_UserGenerator.GetSkeletonCap().StartTracking(nId);
	}
	else
	{
		// Calibration failed
		printf("Calibration failed for user %d\n", nId);
		if (g_bNeedPose)
		{
			g_UserGenerator.GetPoseDetectionCap().StartPoseDetection(g_strPose, nId);
		}
		else
		{
			g_UserGenerator.GetSkeletonCap().RequestCalibration(nId, TRUE);
		}
	}
}

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    XnUInt64 *MXadress;
    double *Pos;
    
    int Jdimsc[2];
    Jdimsc[0]=225; Jdimsc[1]=7;
    plhs[0] = mxCreateNumericArray(2, Jdimsc, mxDOUBLE_CLASS, mxREAL);
    Pos = mxGetPr(plhs[0]);
     
    if(nrhs==0)
    {
       printf("Open failed: Give Pointer to Kinect as input\n");
       mexErrMsgTxt("Kinect Error"); 
    }
        
    MXadress = (XnUInt64*)mxGetData(prhs[0]);
    if(MXadress[0]>0){ g_Context = ((xn::Context*) MXadress[0])[0]; }
    if(MXadress[2]>0)
	{ 
		g_DepthGenerator = ((xn::DepthGenerator*) MXadress[2])[0]; 
	}
	else
	{
		mexErrMsgTxt("No Depth Node in Kinect Context"); 
	}
    if(MXadress[4]>0)
	{ 
		g_UserGenerator = ((xn::UserGenerator*) MXadress[4])[0]; 
	}
    else
	{
		mexErrMsgTxt("No User Node in Kinect Context"); 
	}

    XnStatus nRetVal = XN_STATUS_OK;

    XnCallbackHandle hUserCallbacks, hCalibrationCallbacks, hPoseCallbacks;
    if (!g_UserGenerator.IsCapabilitySupported(XN_CAPABILITY_SKELETON))
    {
        printf("Supplied user generator doesn't support skeleton\n");
        return;
    }
    g_UserGenerator.RegisterUserCallbacks(User_NewUser, User_LostUser, NULL, hUserCallbacks);
    g_UserGenerator.GetSkeletonCap().RegisterCalibrationCallbacks(UserCalibration_CalibrationStart, UserCalibration_CalibrationEnd, NULL, hCalibrationCallbacks);

    if (g_UserGenerator.GetSkeletonCap().NeedPoseForCalibration())
    {
        g_bNeedPose = TRUE;
        if (!g_UserGenerator.IsCapabilitySupported(XN_CAPABILITY_POSE_DETECTION))
        {
            printf("Pose required, but not supported\n");
            return;
        }
        g_UserGenerator.GetPoseDetectionCap().RegisterToPoseCallbacks(UserPose_PoseDetected, NULL, NULL, hPoseCallbacks);
        g_UserGenerator.GetSkeletonCap().GetCalibrationPose(g_strPose);
    }

    g_UserGenerator.GetSkeletonCap().SetSkeletonProfile(XN_SKEL_PROFILE_ALL);
 
    char strLabel[50] = "";
    XnUserID aUsers[15];
    XnUInt16 nUsers = 15;
    int r=0;
    xn::SceneMetaData sceneMD;
	xn::DepthMetaData depthMD;
	
    // Process the data
    g_DepthGenerator.GetMetaData(depthMD);
    g_UserGenerator.GetUserPixels(0, sceneMD);
    g_UserGenerator.GetUsers(aUsers, nUsers);
 	for (int i = 0; i < nUsers; ++i)
 	{
        if (g_UserGenerator.GetSkeletonCap().IsTracking(aUsers[i]))
		{
            //printf(strLabel, "%d - Looking for pose", aUsers[i]);
   
            XnSkeletonJointPosition joint[15];
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_HEAD, joint[0]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_NECK, joint[1]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_LEFT_SHOULDER, joint[2]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_LEFT_ELBOW, joint[3]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_LEFT_HAND, joint[4]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_RIGHT_SHOULDER, joint[5]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_RIGHT_ELBOW, joint[6]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_RIGHT_HAND, joint[7]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_TORSO, joint[8]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_LEFT_HIP, joint[9]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_LEFT_KNEE, joint[10]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_LEFT_FOOT, joint[11]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_RIGHT_HIP, joint[12]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_RIGHT_KNEE, joint[13]);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJointPosition(aUsers[i],XN_SKEL_RIGHT_FOOT, joint[14]);

            XnPoint3D pt[1];
            for(int j=0; j<15; j++)
            {
                Pos[j            +r]=aUsers[i];
                Pos[j+Jdimsc[0]  +r]=joint[j].fConfidence;
                Pos[j+Jdimsc[0]*2+r]=joint[j].position.X;
                Pos[j+Jdimsc[0]*3+r]=joint[j].position.Y;
                Pos[j+Jdimsc[0]*4+r]=joint[j].position.Z;
                pt[0] = joint[j].position;
                g_DepthGenerator.ConvertRealWorldToProjective(1, pt, pt);
                Pos[j+Jdimsc[0]*5+r]=pt[0].X;
                Pos[j+Jdimsc[0]*6+r]=pt[0].Y;
            }        
            r+=15;
        }
     }
            
}
