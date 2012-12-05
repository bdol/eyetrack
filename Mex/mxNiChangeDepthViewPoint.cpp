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
xn::DepthGenerator g_DepthGenerator;
// JD: START
xn::ImageGenerator g_Image;
// JD: STOP

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    //unsigned short *Iout;
    XnUInt64 *MXadress;
    
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
    // JD: START
	if(MXadress[1]>0){ 
		 g_Image = ((xn::ImageGenerator*) 
			 MXadress[1])[0]; 
	}
	else
	{
		mexErrMsgTxt("No Image Node in Kinect Context"); 
	}
    xn::ImageMetaData imageMD;
    // JD: STOP
    
    XnStatus nRetVal = XN_STATUS_OK;

	xn::DepthMetaData depthMD;
    
    // JD: START
    g_DepthGenerator.GetAlternativeViewPointCap().SetViewPoint(g_Image);
    // JD: STOP
    
	// Process the data
	g_DepthGenerator.GetMetaData(depthMD);
}
