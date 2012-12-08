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
xn::IRGenerator g_IR;

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    unsigned short *Iout;
    XnUInt64 *MXadress;
    
    if(nrhs==0)
    {
       printf("Open failed: Give Pointer to Kinect as input\n");
       mexErrMsgTxt("Kinect Error"); 
    }
    
    MXadress = (XnUInt64*)mxGetData(prhs[0]);
    if(MXadress[0]>0){ g_Context = ((xn::Context*) MXadress[0])[0]; }
    if(MXadress[3]>0)
	{ 
		g_IR = ((xn::IRGenerator*) MXadress[3])[0]; 
	}
	else
	{
		mexErrMsgTxt("No IR Node in Kinect Context"); 
	}
    
    XnStatus nRetVal = XN_STATUS_OK;
        
    nRetVal = g_Context.FindExistingNode(XN_NODE_TYPE_IR, g_IR);
	CHECK_RC(nRetVal, "Find IR generator");
	
	xn::IRMetaData irMD;
    
	// Process the data
	g_IR.GetMetaData(irMD);
    
    // Grayscale 16 is the only image format supported.
	if (irMD.PixelFormat() != XN_PIXEL_FORMAT_GRAYSCALE_16_BIT)
	{
		printf("The device image format must be Grayscale 16\n");
		mexErrMsgTxt("Kinect Error"); 
	}
    
  	XnUInt16 g_nXRes = irMD.FullXRes();
	XnUInt16 g_nYRes = irMD.FullYRes();
	const XnIRPixel * pIR = irMD.Data();
    int Jdimsc[2];
    Jdimsc[0]=g_nXRes;
    Jdimsc[1]=g_nYRes;
    
    plhs[0] = mxCreateNumericArray(2, Jdimsc, mxUINT16_CLASS, mxREAL);
    Iout = (unsigned short*)mxGetData(plhs[0]);
    memcpy (Iout,pIR,Jdimsc[0]*Jdimsc[1]*2);  
}
